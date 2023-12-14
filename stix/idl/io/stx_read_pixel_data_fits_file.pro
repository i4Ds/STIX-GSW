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
;               The header of the primary HDU of the pixel data file.
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
;                     N.B. WILL ONLY WORK WITH FULL TIME RESOLUTION DATA WHICH IS OFTEN NOT THE CASE FOR PIXEL DATA.
;
; :history:
;    25-Jan-2021 - ECMD (Graz), initial release
;    19-Jan-2022 - Andrea (FHNW), Added the correction of the duration time array when reading the L1 FITS files for OSPEX
;    22-Feb-2022 - ECMD (Graz), documented, improved handling of alpha and non-alpha files, altered duration shift calculation
;    28-Feb-2022 - ECMD (Graz), fixed issue reading sting rcr values for level 1 files
;    05-Jul-2022 - ECMD (Graz), fixed handling of L1 files which don't contain the full set of energy, detector and pixel combinations
;    21-Jul-2022 - ECMD (Graz), added automatic check for energy shift
;    04-Sep-2022 - Paolo (WKU), fixed issue concerning pixel mask
;    10-Feb-2023 - FSc (AIP), adapted to recent changes in L1 files (see PR #296 in STIXcore GitHub)
;    21-Feb-2023 - FSc (AIP), fix for more changes in L1 files (energy_bin_edge_mask vs. energy_bin_mask)
;    15-Mar-2023 - ECMD (Graz), updated to handle release version of L1 FITS files
;    27-Mar-2023 - ECMD (Graz), added check for duration shift already applied in FITS file
;    11-Oct-2023 - Paolo (WKU), 'energy_bin_mask' is returned in the data structure
;
;-
pro stx_read_pixel_data_fits_file, fits_path, time_shift, alpha = alpha, primary_header = primary_header, data_str = data, data_header = data_header, control_str = control, $
  control_header= control_header, energy_str = energy, energy_header = energy_header, t_axis = t_axis, e_axis = e_axis, $
  energy_shift = energy_shift, use_discriminators = use_discriminators, shift_duration = shift_duration, silent=silent

  default, alpha, 0
  default, time_shift, 0
  default, use_discriminators, 1
  default, shift_duration, 0
  
  !null = stx_read_fits(fits_path, 0, primary_header,  mversion_full = mversion_full, silent=silent)
  control = stx_read_fits(fits_path, 'control', control_header, mversion_full = mversion_full, silent=silent)
  data = stx_read_fits(fits_path, 'data', data_header, mversion_full = mversion_full, silent=silent)
  energy = stx_read_fits(fits_path, 'energies', energy_header, mversion_full = mversion_full, silent=silent)

  processing_level = (sxpar(primary_header, 'LEVEL'))
  if strcompress(processing_level,/remove_all) eq 'L1A' then alpha = 1

  stx_check_duration_shift, primary_header, duration_shifted = duration_shifted, duration_shift_not_possible = duration_shift_not_possible

  hstart_time = alpha ? (sxpar(primary_header, 'date_beg')) : (sxpar(primary_header, 'date-beg'))

  data.counts_comp_err  = sqrt(data.counts_comp_err^2. + data.counts)
  data.triggers_comp_err = sqrt(data.triggers_comp_err^2. + data.triggers)

  shift_duration = shift_duration && ~duration_shifted && ~duration_shift_not_possible

  if keyword_set(shift_duration) and (anytim(hstart_time) gt anytim('2021-12-09T00:00:00') ) then $
    message, 'Shift of duration with respect to time bins is no longer needed after 09-Dec-21'

  ; ************************************
  ; Andrea (19-Jan-2022)
  if keyword_set(shift_duration) then begin
    ;shift counts and triggers by one time step
    counts = data.counts
    shifted_counts =counts
    shifted_counts[*,*,*,0:-2]=counts[*,*,*,1:-1]
    counts = shifted_counts[*,*,*,0:-2]

    counts_err = data.counts_comp_err
    shifted_counts_err =counts_err
    shifted_counts_err[*,*,*,0:-2]=counts_err[*,*,*,1:-1]
    counts_err = shifted_counts_err[*,*,*,0:-2]

    triggers = data.triggers
    shifted_triggers =triggers
    shifted_triggers[*,0:-2]=triggers[*,1:-1]
    triggers = shifted_triggers[*,0:-2]

    triggers_err = data.triggers_comp_err
    shifted_triggers_err = triggers_err
    shifted_triggers_err[*,0:-2]=triggers_err[*,1:-1]
    triggers_err = shifted_triggers_err[*,0:-2]

    duration = (data.timedel)[0:-2]
    time_bin_center = (data.time)[0:-2]
    control_index = (data.control_index)[0:-2]

  endif else begin

    counts = data.counts
    counts_err = data.counts_comp_err
    triggers = data.triggers
    triggers_err =  data.triggers_comp_err
    duration = (data.timedel)
    time_bin_center = (data.time)
    control_index = data.control_index

  endelse

  n_times = n_elements(time_bin_center) ; update number of time bins

  ; changed 2023-02-21 - FIX ME: this is not correct when using energy-bin grouping
  edges_used = where( control.energy_bin_edge_mask eq 1, nedges)
  energy_bin_mask = stx_energy_edge2bin_mask(control.energy_bin_edge_mask)
  energies_used = where(energy_bin_mask eq 1) 
  
  if ~keyword_set(alpha) then begin

    rcr =  ((data.rcr).typecode) eq 7 ? fix(strmid(data.rcr,0,1,/reverse_offset)) : (data.rcr)
    data =  rep_tag_value(data, rcr, 'RCR')

    detectors_used = where( (data.detector_masks)[*,0] eq 1, ndets)
    pixels_used = where( (data.pixel_masks)[*,0] eq 1, npix)

    full_counts = dblarr(32, 12, 32, n_times)
    full_counts[energies_used, pixels_used, detectors_used, *] = counts[*,pixels_used,*,*]
    counts = full_counts

    full_counts_err = dblarr(32, 12, 32, n_times)
    full_counts_err[energies_used, pixels_used, detectors_used, *] = counts_err[*,pixels_used,*,*]
    counts_err = full_counts_err

  endif else begin
    rcr = data.rcr
  endelse


  energy_edges_2 = transpose([[energy.e_low], [energy.e_high]])

  if control.energy_bin_edge_mask[0] and ~keyword_set(use_discriminators) then begin
    
    control.energy_bin_edge_mask[0] = 0
    data.counts[0,*,*,*] = 0.
    data.counts_comp_err[0,*,*,*] = 0.
    energy_edges_2 = energy_edges_2[*,1:-1]

  endif

  if control.energy_bin_edge_mask[-1]  and ~keyword_set(use_discriminators) then begin

    control.energy_bin_edge_mask[-1] = 0
    data.counts[-1,*,*,*] = 0.
    data.counts_comp_err[-1,*,*,*] = 0.
    energy_edges_2 = energy_edges_2[*,0:-2]

  endif


  ; create time object
  stx_time_obj = stx_time()
  stx_time_obj.value =  anytim(hstart_time , /mjd)
  start_time = stx_time_add(stx_time_obj, seconds = time_shift)

  if ~keyword_set(alpha) then begin
    time_bin_center = double(time_bin_center)
    duration = double(duration)
    ; 29-Jun-22 (ECMD) time and timedel in L1 files are now in centiseconds
    t_start = stx_time_add( start_time,  seconds = [ time_bin_center/100 - duration/200 ] )
    t_end   = stx_time_add( start_time,  seconds = [ time_bin_center/100 + duration/200 ] )
    t_mean  = stx_time_add( start_time,  seconds = [ time_bin_center/100 ] )
    duration = duration/100
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

  ; If time range of observation is during Nov 2020 RSCW apply average energy shift by default
  expected_energy_shift = stx_check_energy_shift(hstart_time)
  default, energy_shift, expected_energy_shift

  
  edges_used = where( control.energy_bin_edge_mask eq 1, nedges)
  energy_bin_mask = stx_energy_edge2bin_mask(control.energy_bin_edge_mask)
  energies_used = where(energy_bin_mask eq 1)
  
  ; changed 2023-03-15: Now only the used energies are in table energy, therefore:
  edge_products, energy_edges_2, edges_1 = energy_edges_1

  e_axis = stx_construct_energy_axis(energy_edges = energy_edges_1 + energy_shift, select =  indgen(n_elements(energy_edges_1)) )
  e_axis.low_fsw_idx = energies_used
  e_axis.high_fsw_idx = energies_used

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
    energy_bin_mask: energy_bin_mask,$
    num_pixel_sets:data.num_pixel_sets,$
    num_energy_groups:data.num_energy_groups }

end
