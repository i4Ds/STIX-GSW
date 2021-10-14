pro stx_read_spectrogram_fits_file, fits_path, time_shift, primary_header = primary_header, data_str = data, data_header = data_header, control_str = control, $
  control_header= control_header, energy_str = energy, energy_header = energy_header, t_axis = t_axis, e_axis = e_axis, $
  energy_shift = energy_shift, use_discriminators = use_discriminators, keep_short_bins = keep_short_bins, replace_doubles = replace_doubles, $
  apply_time_shift = apply_time_shift

  default, time_shift, 0
  default, energy_shift, 0
  default, use_discriminators, 1
  default, replace_doubles, 0
  default, keep_short_bins, 0
  default, apply_time_shift , 1

  !null = mrdfits(fits_path, 0, primary_header, /silent)
  control = mrdfits(fits_path, 1, control_header, /unsigned, /silent)
  data = mrdfits(fits_path, 2, data_header, /unsigned, /silent)
  energy = mrdfits(fits_path, 3, energy_header, /unsigned, /silent)

  n_time = n_elements(data.time)

  hstart_time = (sxpar(primary_header, 'DATE_BEG'))

  ;TO BE ADDED WHEN FULL_RESOLUTION KEWORD IS INCUDED
  ;  full_resolution = (sxpar(primary_header, 'FULL_RESOLUTION'))
  ;
  ;if ~full_resolution  and apply_time_shift then begin
  ;    message, /info, 'For time shift compensation full archive buffer time resoultion files are needed.'
  ;endif

  if ~keyword_set(keep_short_bins) and (anytim(hstart_time) lt anytim('2020-11-25T00:00:00') ) then $
    message, 'Automatic short bin removal should not be attempted on observations before 25-Nov-20'
  if apply_time_shift then begin

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

  endif else begin

    counts = data.counts
    counts_err = data.counts_err
    triggers = data.triggers
    triggers_err = data.triggers_err
    duration = (data.timedel)
    time_bin_center = (data.time)

  endelse

  if ~keyword_set(keep_short_bins) then begin

    ;remove short time bins with low counts
    counts_for_time_bin=total(counts[1:10,*],1)

    idx_short=where(counts_for_time_bin le 1400 )

    ;list when we have 1 second time bins, short or normal bins
    mask_long_bins  =  lonarr(n_time-1) + 1

    if idx_short[0] ne -1 then begin

      idx_double = where(duration[idx_short-1] eq 1)

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

  data = {time: time_bin_center,$
    timedel:duration , $
    triggers:triggers, $
    triggers_err: triggers_err,$
    counts:counts ,$
    counts_err: counts_err ,$
    control_index:(data.control_index)[0:-2]}


  ; create time object
  stx_time_obj = stx_time()
  stx_time_obj.value =  anytim(hstart_time , /mjd)
  start_time = stx_time_add(stx_time_obj, seconds = time_shift)

  t_start = stx_time_add( start_time,  seconds = [time_bin_center - duration/2.] )
  t_end = stx_time_add( start_time,  seconds = [time_bin_center + duration/2.] )
  t_mean = stx_time_add( start_time,  seconds = [time_bin_center] )

  t_axis  = stx_time_axis(n_elements(time_bin_center))
  t_axis.mean =  t_mean
  t_axis.time_start = t_start
  t_axis.time_end = t_end
  t_axis.duration = duration


  if control.energy_bin_mask[0] || control.energy_bin_mask[-1] and ~keyword_set(use_discriminators) then begin

    control.energy_bin_mask[0] = 0
    control.energy_bin_mask[-1] = 0
    data.counts[0,*] = 0.
    data.counts[-1,*] = 0.

    data.counts_err[0,*] = 0.
    data.counts_err[-1,*] = 0.

  endif

  energies_used = where( control.energy_bin_mask eq 1 , nenergies)
  energy_edges_2 = transpose([[energy[energies_used].e_low], [energy[energies_used].e_high]])
  edge_products, energy_edges_2, edges_1 = energy_edges_1

  energy_edges_all2 = transpose([[energy.e_low], [energy.e_high]])
  edge_products, energy_edges_all2, edges_1 = energy_edges_all1

  use_energies = where_arr(energy_edges_all1,energy_edges_1)
  energy_edge_mask = intarr(33)
  energy_edge_mask[use_energies] = 1

  e_axis = stx_construct_energy_axis(energy_edges = energy_edges_all1 + energy_shift, select = use_energies)


end