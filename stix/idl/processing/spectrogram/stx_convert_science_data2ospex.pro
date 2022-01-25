pro stx_convert_science_data2ospex, spectrogram = spectrogram, specpar = specpar, data_level = data_level, data_dims = data_dims,  fits_path_bk = fits_path_bk,$
  dist_factor = dist_factor, flare_location= flare_location, eff_ewidth = eff_ewidth, ospex_obj = ospex_obj

  n_energies = data_dims[0]
  n_detectors = data_dims[1]
  n_pixels = data_dims[2]
  n_times = data_dims[3]

  counts_spec  = spectrogram.counts
  livetime_frac =  stx_spectrogram_livetime(  spectrogram, corrected_counts = corrected_counts, level = data_level )

  corrected_counts = total(reform(corrected_counts, [n_energies, n_detectors, n_times ]),2)

  counts_spec = total(reform(counts_spec,[n_energies, n_detectors, n_times ]),2)

  if keyword_set(fits_path_bk) then begin

    stx_read_pixel_data_fits_file, fits_path_bk,time_shift, data_str = data_str_bk, control_str = control_str_bk, $
      energy_str = energy_str_bk, t_axis = t_axis_bk, e_axis = e_axis_bk, use_discriminators = 0
    bk_data_level = 1

    counts_in_bk = data_str_bk.counts

    dim_counts_bk = counts_in_bk.dim

    ntimes_bk = n_elements(dim_counts_bk) gt 3 ? dim_counts_bk[3] : 1
    pixels_used = where(spectrogram.pixel_mask eq 1)
    detectors_used = where(spectrogram.detector_mask eq 1)
    n_pixels_bk = n_elements(pixels_used)
    n_detectors_bk = n_elements(detectors_used)

    spec_in_bk = total(reform(data_str_bk.counts[*,pixels_used,detectors_used], dim_counts_bk[0], n_pixels_bk, n_detectors_bk, ntimes_bk  ),2)
    spec_in_bk = reform(spec_in_bk, dim_counts_bk[0],n_detectors_bk, ntimes_bk)

    spectrogram_bk = { $
      type          : "stx_fsw_sd_spectrogram", $
      counts        : spec_in_bk, $
      trigger       : transpose(data_str_bk.triggers), $
      time_axis     : t_axis_bk , $
      energy_axis   : e_axis_bk, $
      pixel_mask    : spectrogram.pixel_mask , $
      detector_mask : spectrogram.detector_mask, $
      error         : sqrt(spec_in_bk)}

    livetime_frac_bk =  stx_spectrogram_livetime(  spectrogram_bk, corrected_counts = corrected_counts_bk, level = bk_data_level )

    corrected_counts_bk = total(reform(corrected_counts_bk,[dim_counts_bk[0], n_detectors_bk, ntimes_bk ]),2)

    corrected_counts_bk = (total(reform(corrected_counts_bk, dim_counts_bk[0], ntimes_bk),2)/total(data_str_bk.timedel))#(spectrogram.time_axis.duration)

    corrected_counts_bk  = reform(corrected_counts_bk,dim_counts_bk[0], n_times)

    energy_bins = spectrogram.energy_axis.low_fsw_idx

    corrected_counts_bk =  corrected_counts_bk[energy_bins,*]/reproduce(eff_ewidth, n_times)

    corrected_counts_bk =  reform(corrected_counts_bk,[n_elements(energy_bins), n_times])


    spec_in_bk = total(reform(spec_in_bk,[dim_counts_bk[0], n_detectors_bk, ntimes_bk ]),2)

    spec_in_bk = (total(reform(spec_in_bk, dim_counts_bk[0], ntimes_bk),2)/total(data_str_bk.timedel))#(spectrogram.time_axis.duration)

    spec_in_bk  = reform(spec_in_bk,dim_counts_bk[0], n_times)

    spec_in_bk =  spec_in_bk[energy_bins,*]/reproduce(eff_ewidth, n_times)

    spec_in_bk =  reform(spec_in_bk,[n_elements(energy_bins), n_times])

    error_bk = total(total(data_str_bk.counts_err[energy_bins,*,*],2),2)

    spec_in_corr = corrected_counts - corrected_counts_bk; > 0

    spec_in_uncorr = counts_spec - spec_in_bk; > 0

    total_error = sqrt(corrected_counts + corrected_counts_bk )


  endif else begin

    spec_in_corr = corrected_counts  ;> 0

    spec_in_uncorr = counts_spec ;> 0

    total_error = sqrt(corrected_counts)

  endelse

  eff_livetime_fraction = f_div(counts_spec , corrected_counts , default = 1 )
  eff_livetime_fraction = mean(eff_livetime_fraction, dim = 1)
  eff_livetime_fraction_expanded = transpose(rebin([eff_livetime_fraction],n_elements(eff_livetime_fraction),n_energies))
  spec_in_corr *= eff_livetime_fraction_expanded

  e_axis = spectrogram.energy_axis
  emin = 1
  emax = 150
  new_edges = where( spectrogram.energy_axis.edges_1 gt emin and  spectrogram.energy_axis.edges_1 lt emax)
  e_axis_new = stx_construct_energy_axis(energy_edges = e_axis.edges_1, select = new_edges)

  new_energies = where_arr(fix(10*e_axis.mean),fix(10*e_axis_new.mean))

  spec_in_corr = spec_in_corr[new_energies,*]
  total_error = total_error[new_energies,*]

  ;insert the information from the telemetry file into the expected stx_fsw_sd_spectrogram structure
  spectrogram = { $
    type          : "stx_fsw_sd_spectrogram", $
    counts        : spec_in_corr, $
    trigger       : transpose(spectrogram.trigger), $
    time_axis     : spectrogram.time_axis , $
    energy_axis   : e_axis_new, $
    pixel_mask    : spectrogram.pixel_mask , $
    detector_mask : spectrogram.detector_mask, $
    rcr           : spectrogram.rcr,$
    error         : total_error}

  fstart_time = time2fid(atime(stx_time2any((spectrogram.time_axis.time_start)[0])),/full,/time)

  srmfilename = 'stx_spectrum_srm_' + fstart_time + '.fits'
  specfilename =  'stx_spectrum_'   + fstart_time + '.fits'

  transmission = read_csv(loc_file( 'stix_trans_by_component.csv', path = getenv('STX_GRID')))

  phe = transmission.field9
  phe = phe[where(phe gt emin-1 and phe lt 2*emax)]
  edge_products, phe, mean = mean_phe, width = w_phe
  ph_in = [mean_phe[0]- w_phe[0], mean_phe]

  ospex_obj =   stx_fsw_sd_spectrogram2ospex( spectrogram, specpar = specpar, ph_energy_edges = ph_in, /include_damage, /fits , /tail, livetime_fraction = eff_livetime_fraction, $
    dist_factor = dist_factor, flare_location= flare_location )

  ospex_obj -> set, spex_eband = get_edges([4.,10.,15.,25, 50, 84.], /edges_2)

  ospex_obj -> plot_time,  spex_units='flux'


end