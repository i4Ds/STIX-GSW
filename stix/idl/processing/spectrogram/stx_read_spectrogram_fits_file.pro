;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_read_spectrogram_fits_file
;
; :description:
;    This procedure reads all extensions of a STIX science data x-ray compaction level 4 (spectrogram data) FITS file and converts them to
;    IDL structures. The header information for the primary HDU and subsequent extensions is also returned.
;
; :categories:
;    spectroscopy, io
;
; :params:
;
;    fits_path_data : in, required, type="string"
;              The path to the sci-xray-spec (or sci-spectrogram) observation file
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
;              The header of the primary HDU of the spectrogram data file
;
;    data_header : out, type="string array", default="string array"
;              The header of the data extension of the spectrogram data file
;
;    data_str : out, type="structure"
;              The contents of the data extension of the spectrogram data file
;
;    control_header : out, type="string array"
;                The header of the control extension of the spectrogram data file
;
;    control_str : out, type="structure"
;               The contents of the control extension of the spectrogram data file
;
;    energy_header : out, type="string array"
;               The header of the energies extension of the spectrogram data file
;
;    energy_str : out, type="structure"
;              The contents of the energies extension of the spectrogram data file
;
;    t_axis : out, type="stx_time_axis structure",
;               The time axis corresponding to the observation data
;
;    e_axis : out, type="stx_energy_axis structure "
;              The energy axis corresponding to the observation data
;
;    shift_duration : in, type="boolean", default="1"
;                     Shift all time bins by 1 to account for FSW time input discrepancy prior to 09-Dec-2021.
;                     N.B. WILL ONLY WORK WITH FULL TIME RESOLUTION DATA WHICH IS USUALLY NOT THE CASE FOR SPECTROGRAM DATA.
;
; :history:
;    18-Jun-2021 - ECMD (Graz), initial release
;    22-Feb-2022 - ECMD (Graz), documented, improved handling of alpha and non-alpha files, fixed duration shift issue
;    05-Jul-2022 - ECMD (Graz), fixed handling of L1 files which don't contain the full set of energies
;    21-Jul-2022 - ECMD (Graz), added automatic check for energy shift 
;    
;-
pro stx_read_spectrogram_fits_file, fits_path, time_shift, primary_header = primary_header, data_str = data, data_header = data_header, control_str = control, $
  control_header= control_header, energy_str = energy, energy_header = energy_header, t_axis = t_axis, e_axis = e_axis, $
  energy_shift = energy_shift, use_discriminators = use_discriminators, keep_short_bins = keep_short_bins, replace_doubles = replace_doubles, $
  shift_duration = shift_duration

  default, time_shift, 0
  default, use_discriminators, 1
  default, replace_doubles, 0
  default, keep_short_bins, 1
  default, alpha, 0

  !null = stx_read_fits(fits_path, 0, primary_header, mversion_full = mversion_full)
  control = stx_read_fits(fits_path, 'control', control_header, mversion_full = mversion_full)
  data = stx_read_fits(fits_path, 'data', data_header, mversion_full = mversion_full)
  energy = stx_read_fits(fits_path, 'energies', energy_header, mversion_full = mversion_full)


  n_time = n_elements(data.time)

  energies_used = where( control.energy_bin_mask eq 1 , nenergies)

  processing_level = (sxpar(primary_header, 'LEVEL'))
  if strcompress(processing_level,/remove_all) eq 'L1A' then alpha = 1

  hstart_time = alpha ? (sxpar(primary_header, 'date_beg')) : (sxpar(primary_header, 'date-beg'))

  trigger_zero = (sxpar(data_header, 'TZERO3'))
  new_triggers = float(trigger_zero + data.triggers)
  data = rep_tag_value(data, 'TRIGGERS', new_triggers)
  ;TO BE ADDED WHEN FULL_RESOLUTION KEWORD IS INCLUDED
  ;  full_resolution = (sxpar(primary_header, 'FULL_RESOLUTION'))
  ;
  ;if ~full_resolution  and apply_time_shift then begin
  ;    message, /info, 'For time shift compensation full archive buffer time resolution files are needed.'
  ;endif

  data.counts_err  = sqrt(data.counts_err^2. + data.counts)
  data.triggers_err = sqrt( data.triggers_err^2. + data.triggers)

  duration_shift_needed = (anytim(hstart_time) lt anytim('2021-12-09T00:00:00')) ? 1 : 0
  default, shift_duration, duration_shift_needed

  ; If time range of observation is during Nov 2020 RSCW apply average energy shift by default
  expected_energy_shift = stx_check_energy_shift(hstart_time)
  default, energy_shift, expected_energy_shift

  if ~keyword_set(keep_short_bins) and (anytim(hstart_time) lt anytim('2020-11-25T00:00:00') ) then $
    message, 'Automatic short bin removal should not be attempted on observations before 25-Nov-20'

  if keyword_set(shift_duration) and (anytim(hstart_time) gt anytim('2021-12-09T00:00:00') ) then $
    message, 'Shift of duration with respect to time bins is no longer needed after 09-Dec-21'

  if shift_duration then begin

    ;shift counts and triggers by one time step
    counts = data.counts
    shifted_counts =counts
    shifted_counts[*,0:-2]=counts[*,1:-1]
    counts = shifted_counts[*,0:-2]

    counts_err = data.counts_err
    shifted_counts_err =counts_err
    shifted_counts_err[*,0:-2]=counts_err[*,1:-1]
    counts_err = shifted_counts_err[*,0:-2]

    triggers = data.triggers
    shifted_triggers =triggers
    shifted_triggers[0:-2]=triggers[1:-1]
    triggers = shifted_triggers[0:-2]

    triggers_err = data.triggers_err
    shifted_triggers_err = triggers_err
    shifted_triggers_err[0:-2]=triggers_err[1:-1]
    triggers_err = shifted_triggers_err[0:-2]

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
    control_index = (data.control_index)

  endelse

  if ~keyword_set(keep_short_bins) then begin

    ;remove short time bins with low counts
    counts_for_time_bin=total(counts[1:10,*],1)
    
    min_count_threshold = 1400
    idx_short=where(counts_for_time_bin le min_count_threshold )

    ;list when we have mimum duration time bins, short or normal bins
    mask_long_bins  =  lonarr(n_time-1) + 1

    min_time = stx_date2min_time(hstart_time) / 10.

    if idx_short[0] ne -1 then begin

      idx_double = where(duration[idx_short-1] eq min_time)

      idx_short_plus = idx_double[0] ne -1 ? [idx_short,idx_short[idx_double]-1] : idx_short

      if idx_double[0] ne -1 and  keyword_set(replace_doubles) then begin

        mask_long_bins[idx_short] = 0
        duration[idx_short[idx_double]-1]  = (duration[max(where(duration[0:idx_short[idx_double]] gt 1))] + duration[ min(where(duration[idx_short[idx_double]:-1] gt 1)) + idx_short[idx_double]])/2.
      endif else begin

        mask_long_bins[idx_short_plus] = 0

      endelse
    endif

    idx_long = where(mask_long_bins eq 1)

    time_bin_short_removed = time_bin_center[idx_long]
    duration_short_removed = duration[idx_long]
    counts_short_removed = counts[*,idx_long]
    counts_err_short_removed  = counts_err[*,idx_long]
    triggers_short_removed =  triggers[idx_long]
    triggers_err_short_removed = triggers_err[idx_long]

    time_bin_center =  time_bin_short_removed
    duration =  duration_short_removed
    counts = counts_short_removed
    counts_err =  counts_err_short_removed
    triggers = triggers_short_removed
    triggers_err=   triggers_err_short_removed

  endif

  n_time = n_elements(time_bin_center) ; update number of time bins

  if alpha then begin
    rcr = tag_exist(data, 'rcr') ? data.rcr :replicate(control.rcr, n_time)
    control = rep_tag_name(control, 'pixel_mask','pixel_masks')
    control = rep_tag_name(control, 'detector_mask','detector_masks')
  endif else begin
    rcr =  ((data.rcr).typecode) eq 7 ? fix(strmid(data.rcr,0,1,/reverse_offset)) : (data.rcr)
    ;L1 files
    full_counts = dblarr(32, n_time)
    full_counts[energies_used, *] = counts
    counts = full_counts

    full_counts_err = dblarr(32, n_time)
    full_counts[energies_used, *] = counts_err
    counts_err = full_counts_err


  endelse


  ; create time object
  stx_time_obj = stx_time()
  stx_time_obj.value =  anytim(hstart_time , /mjd)
  start_time = stx_time_add(stx_time_obj, seconds = time_shift)

  if ~keyword_set(alpha) then begin ; 25-Mar-22 (ECMD) time and timedel in L1 files are now in centiseconds
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

  data = {time: time_bin_center,$
    timedel:duration , $
    triggers:triggers, $
    triggers_err: triggers_err,$
    counts:counts ,$
    counts_err: counts_err ,$
    rcr: rcr,$
    control_index:control_index}

  if control.energy_bin_mask[0] || control.energy_bin_mask[-1] and ~keyword_set(use_discriminators) then begin

    control.energy_bin_mask[0] = 0
    control.energy_bin_mask[-1] = 0
    data.counts[0,*] = 0.
    data.counts[-1,*] = 0.

    data.counts_err[0,*] = 0.
    data.counts_err[-1,*] = 0.

  endif

  energies_used = where( control.energy_bin_mask eq 1, nenergies)
  energy_edges_2 = transpose([[energy[energies_used].e_low], [energy[energies_used].e_high]])
  edge_products, energy_edges_2, edges_1 = energy_edges_1

  energy_edges_all2 = transpose([[energy.e_low], [energy.e_high]])
  edge_products, energy_edges_all2, edges_1 = energy_edges_all1

  use_energies = where_arr(energy_edges_all1,energy_edges_1)
  energy_edge_mask = intarr(33)
  energy_edge_mask[use_energies] = 1

  e_axis = stx_construct_energy_axis(energy_edges = energy_edges_all1 + energy_shift, select = use_energies)


end