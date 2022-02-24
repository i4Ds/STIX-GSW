;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_read_pixel_data_fits_file
;
; :description:
;    This procedure reads all extensions of a STIX science data x-ray compaction level 1 (compressed pixel data) FITS file and converts them to
;    IDL structures. The header information for the primary HDU and subsequent extensions is also returned.
;
; :categories:
;    spectroscopy, io
;
; :params:
;
;    fits_path_data : in, required, type="string"
;              The path to the sci-xray-cpd (or sci-xray-l1) observation file
;
;    time_shift : in, optional, type="float", default="0."
;               The difference in seconds in light travel time between the Sun and Earth and the Sun and Solar Orbiter
;               i.e. Time(Sun to Earth) - Time(Sun to S/C)
;
;
; :keywords:
;
;    energy_shift : in, optional, type="float", default="0."
;               Shift all energies by this value in keV. Rarely needed only for cases where there is a significant shift
;               in calibration before a new ELUT can be uploaded.
;
;    alpha : in, type="boolean", default="0"
;            Set if input file is an alpha e.g. L1A
;
;    use_discriminators : in, type="boolean", default="0"
;               an output float value;
;
;    primary_header : out, type="string array"
;               an output float value;
;
;    data_str : out, type="structure"
;              The header of the primary HDU of the pixel data file
;
;    data_header : out, type="string array", default="string array"
;              The header of the data extension of the pixel data file
;
;    data_str : out, type="structure"
;              The contents of the data extension of the pixel data file
;
;    control_header : out, type="string array"
;                The header of the control extension of the pixel data file
;
;    control_str : out, type="structure"
;               The contents of the control extension of the pixel data file
;
;    energy_header : out, type="string array"
;               The header of the energies extension of the pixel data file
;
;    energy_str : out, type="structure"
;              The contents of the energies extension of the pixel data file
;
;    t_axis : out, type="stx_time_axis structure",
;               The time axis corresponding to the observation data
;
;    e_axis : out, type="stx_energy_axis structure "
;              The energy axis corresponding to the observation data
;
;    shift_duration : in, type="boolean", default="0"
;                     Shift all time bins by 1 to account for FSW time input discrepancy prior to 09-Dec-2021.
;                     N.B. WILL ONLY WORK WITH FULL TIME RESOUTION DATA WHICH IS OFTEN NOT THE CASE FOR PIXEL DATA.
;
; :history:
;    25-Jan-2021 - ECMD (Graz), initial release
;    19-Jan-2022 - Andrea (FHNW), Added the correction of the duration time array when reading the L1 FITS files for OSPEX
;    22-Feb-2022 - ECMD (Graz), documented, improved handling of alpha and non-alpha files, altered duration shift calculation 
;    
;-
pro stx_read_pixel_data_fits_file, fits_path, time_shift, alpha = alpha, primary_header = primary_header, data_str = data, data_header = data_header, control_str = control, $
  control_header= control_header, energy_str = energy, energy_header = energy_header, t_axis = t_axis, e_axis = e_axis, $
  energy_shift = energy_shift, use_discriminators = use_discriminators, shift_duration = shift_duration

  default, alpha, 0
  default, time_shift, 0
  default, energy_shift, 0
  default, use_discriminators, 1

  !null = stx_read_fits(fits_path, 0, primary_header,  mversion_full = mversion_full)
  control = stx_read_fits(fits_path, 'control', control_header, mversion_full = mversion_full)
  data = stx_read_fits(fits_path, 'data', data_header, mversion_full = mversion_full)
  energy = stx_read_fits(fits_path, 'energies', energy_header, mversion_full = mversion_full)


  hstart_time = (sxpar(primary_header, 'date_beg'))
  processing_level = (sxpar(primary_header, 'LEVEL'))
  if strcompress(processing_level,/remove_all) eq 'L1A' then alpha = 1


  data.counts_err  = sqrt(data.counts_err^2. + data.counts)
  data.triggers_err = sqrt(data.triggers_err^2. + data.triggers)


  ; ************************************
  ; Andrea (19-Jan-2022)
  if keyword_set(shift_duration) then begin
    ;shift counts and triggers by one time step
    counts = data.counts
    shifted_counts =counts
    shifted_counts[*,*,*,0:-2]=counts[*,*,*,1:-1]
    counts = shifted_counts[*,*,*,0:-2]

    counts_err = data.counts_err
    shifted_counts_err =counts_err
    shifted_counts_err[*,*,*,0:-2]=counts_err[*,*,*,1:-1]
    counts_err = shifted_counts_err[*,*,*,0:-2]

    triggers = data.triggers
    shifted_triggers =triggers
    shifted_triggers[*,0:-2]=triggers[*,1:-1]
    triggers = shifted_triggers[*,0:-2]

    triggers_err = data.triggers_err
    shifted_triggers_err = triggers_err
    shifted_triggers_err[*,0:-2]=triggers_err[*,1:-1]
    triggers_err = shifted_triggers_err[*,0:-2]

    duration = (data.timedel)[0:-2]
    time_bin_center = (data.time)[0:-2]
    control_index = (data.control_index)[0:-2]
    
  endif else begin

    counts = data.counts
    counts_err = data.counts_err
    triggers = data.triggers
    triggers_err =  data.triggers_err
    duration = (data.timedel)
    time_bin_center = (data.time)
    control_index = data.control_index
    
  endelse


  if control.energy_bin_mask[0] || control.energy_bin_mask[-1] and ~keyword_set(use_discriminators) then begin

    control.energy_bin_mask[0] = 0
    control.energy_bin_mask[-1] = 0
    data.counts[0,*,*,*] = 0.
    data.counts[-1,*,*,*] = 0.

    data.counts_err[0,*,*,*] = 0.
    data.counts_err[-1,*,*,*] = 0.

  endif

  if ~keyword_set(alpha) then begin
    rcr =  (data.rcr.typecode)[0] eq 7 ? fix((data.rcr).substring(-1)) : (data.rcr)
    data =  rep_tag_value(data, rcr, 'RCR')
  endif else begin
    rcr = data.rcr
  endelse

  ; create time object
  stx_time_obj = stx_time()
  stx_time_obj.value =  anytim(hstart_time , /mjd)
  start_time = stx_time_add(stx_time_obj, seconds = time_shift)

  if ~keyword_set(alpha) then begin
    t_start = stx_time_add( start_time,  seconds = [ time_bin_center/10. - duration/20. ] )
    t_end   = stx_time_add( start_time,  seconds = [ time_bin_center/10. + duration/20. ] )
    t_mean  = stx_time_add( start_time,  seconds = [ time_bin_center/10. ] )
  endif else begin
    t_start = stx_time_add( start_time,  seconds = [ time_bin_center - duration/2. ] )
    t_end   = stx_time_add( start_time,  seconds = [ time_bin_center + duration/2. ] )
    t_mean  = stx_time_add( start_time,  seconds = [ time_bin_center ] )
  endelse


  t_axis  = stx_time_axis(n_elements(time_bin_center))
  t_axis.mean =  t_mean
  t_axis.time_start = t_start
  t_axis.time_end = t_end
  t_axis.duration = duration


  energies_used = where( control.energy_bin_mask eq 1 , nenergies)
  energy_edges_2 = transpose([[energy[energies_used].e_low], [energy[energies_used].e_high]])
  edge_products, energy_edges_2, edges_1 = energy_edges_1

  energy_edges_all2 = transpose([[energy.e_low], [energy.e_high]])
  edge_products, energy_edges_all2, edges_1 = energy_edges_all1

  use_energies = where_arr(energy_edges_all1,energy_edges_1)
  energy_edge_mask = intarr(33)
  energy_edge_mask[use_energies] = 1

  e_axis = stx_construct_energy_axis(energy_edges = energy_edges_all1 + energy_shift, select = use_energies)

  data = {time: time_bin_center,$
    timedel:duration , $
    triggers:triggers, $
    triggers_err: triggers_err,$
    counts:counts ,$
    counts_err: counts_err ,$
    rcr: rcr,$
    control_index:control_index,$
    pixel_masks:data.pixel_masks,$
    detector_masks:data.detector_masks,$
    num_pixel_sets:data.num_pixel_sets,$
    num_energy_groups:data.num_energy_groups }

end