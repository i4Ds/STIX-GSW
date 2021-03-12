pro  stx_plot_pixel_data_example, fits_path_data = fits_path_data, fits_path_bk = fits_path_bk, time_shift = time_shift, energy_shift = energy_shift, distance = distance, $
  flare_location= flare_location, elut_filename = elut_filename, demo = demo

  if keyword_set(demo) then begin

    message, 'Running demonstraion - overriding all other input keywords', /info
    fits_path_data = loc_file('solo_L1_stix-sci-xray-l1-1178428688_20200607T213708-20200607T215208_V01_49155.fits', path = concat_dir( getenv('stx_demo_data'),'ospex/sample_data/20200607',/dir) )
    fits_path_bk   = loc_file('solo_L1_stix-sci-xray-l1-1178448400_20200607T224958-20200608T001954_V01_49807.fits', path = concat_dir( getenv('stx_demo_data'),'ospex/sample_data/20200607',/dir) )
    time_shift = 236.9
    distance =  0.52
    flare_location = [-1600,-800.]
    elut_filename = 'elut_table_20200519.csv'
    energy_shift = 0

  endif

  default, time_shift, 0.
  default, energy_shift, 0.
  default, distance, 1.
  default, flare_location, [0.,0.]
  default, elut_filename, 'elut_table_20200519.csv'

  dist_factor = 1./(distance^2.)

  stx_read_pixel_data_fits_file, fits_path_data, time_shift, primary_header = primary_header, data_str = data_str, data_header = data_header, control_str = control_str, $
    control_header= control_header, energy_str = energy_str, energy_header = energy_header, t_axis = t_axis, energy_shift = energy_shift,  e_axis = e_axis , use_discriminators = 0
  
  data_level = 1

  hstart_time = (sxpar(primary_header, 'DATE_BEG'))

  counts_in = data_str.counts

  dim_counts = counts_in.dim

  ntimes = n_elements(dim_counts) gt 3 ? dim_counts[3] : 1

  energy_bin_mask = control_str.energy_bin_mask


  g10=[3,20,22]-1
  g09=[16,14,32]-1
  g08=[21,26,4]-1
  g07=[24,8,28]-1
  g06=[15,27,31]-1
  g05=[6,30,2]-1
  g04=[25,5,23]-1
  g03=[7,29,1]-1
  g02=[12,19,17]-1
  g01=[11,13,18]-1
  g01_10=[g01,g02,g03,g04,g05,g06,g07,g08,g09,g10]
  g03_10=[g03,g04,g05,g06,g07,g08,g09,g10]

  mask_use_detectors = intarr(32)
  mask_use_detectors[g03_10] = 1

  mask_use_pixels = intarr(12)
  mask_use_pixels[*] = 1

  if ntimes eq 1 then begin

    pixels_used =  where(total(data_str.pixel_masks,2) gt 0 and mask_use_pixels eq 1)
    detectors_used = where(data_str.detector_masks eq 1 and mask_use_detectors eq 1)

  endif else begin

    pixels_used = where(total(total(data_str.pixel_masks,1),2) gt 0 and mask_use_pixels eq 1)
    detectors_used = where(total(data_str.detector_masks,2) gt 0 and mask_use_detectors eq 1)

  endelse

  energy_bins = where( energy_bin_mask eq 1 )
  n_energies = n_elements(energy_bins)
  pixel_mask_used = intarr(12)
  pixel_mask_used[pixels_used] = 1
  n_pixels = total(pixel_mask_used)

  detector_mask_used = intarr(32)
  detector_mask_used[detectors_used]  = 1
  n_detectors =total(detector_mask_used)
  energy_edges_used = [e_axis.low_fsw_idx, e_axis.high_fsw_idx[-1]+1]
  n_energy_edges = n_elements(energy_edges_used)

  stx_read_elut, ekev_actual = ekev_actual, elut_filename = elut_filename

  ave_edge  = mean(reform(ekev_actual[energy_edges_used-1, pixels_used, detectors_used, 0 ],n_energy_edges, n_pixels, n_detectors), dim= 2)
  ave_edge  = mean(reform(ave_edge,n_energy_edges, n_detectors), dim= 2)


  edge_products, ave_edge, width = ewidth

  eff_ewidth =  (e_axis.width)/ewidth


  counts_in = reform(counts_in,[dim_counts[0:2], ntimes])

  spec_in = total(reform(counts_in[*,pixels_used,detectors_used,*],[32,n_pixels,n_detectors,ntimes]),2)

  spec_in = reform(spec_in,[dim_counts[0],n_detectors, ntimes])

  counts_spec =  spec_in[energy_bins,*, *]/ reform(reproduce(eff_ewidth, n_detectors*ntimes),n_energies, n_detectors, ntimes)

  counts_spec =  reform(counts_spec,[n_energies, n_detectors, ntimes])

  counts_err = total(total(data_str.COUNTS_ERR[energy_bins,*,*],2),2)


  ;insert the information from the telemetry file into the expected stx_fsw_sd_spectrogram structure
  spectrogram = { $
    type          : "stx_fsw_sd_spectrogram", $
    counts        : counts_spec, $
    trigger       : transpose(data_str.triggers), $
    time_axis     : t_axis , $
    energy_axis   : e_axis, $
    pixel_mask    : pixel_mask_used , $
    detector_mask : detector_mask_used, $
    error         : counts_err}

  livetime_frac =  stx_spectrogram_livetime(  spectrogram, corrected_counts = corrected_counts, level = data_level )

  corrected_counts = total(reform(corrected_counts,[n_energies, n_detectors, ntimes ]),2)

  counts_spec = total(reform(counts_spec,[n_energies, n_detectors, ntimes ]),2)


  if keyword_set(fits_path_bk) then begin

    stx_read_pixel_data_fits_file, fits_path_bk,time_shift, data_str = data_str_bk, control_str = control_str_bk, $
      energy_str = energy_str_bk, t_axis = t_axis_bk, e_axis = e_axis_bk, use_discriminators = 0
    bk_data_level = 1

    counts_in_bk = data_str_bk.counts

    dim_counts_bk = counts_in_bk.dim

    ntimes_bk = n_elements(dim_counts_bk) gt 3 ? dim_counts_bk[3] : 1


    spec_in_bk = total(reform(data_str_bk.counts[*,pixels_used,detectors_used], dim_counts_bk[0],n_pixels,n_detectors, ntimes_bk  ),2)
    spec_in_bk = reform(spec_in_bk, dim_counts_bk[0],n_detectors, ntimes_bk)

    spectrogram_bk = { $
      type          : "stx_fsw_sd_spectrogram", $
      counts        : spec_in_bk, $
      trigger       : transpose(data_str_bk.triggers), $
      time_axis     : t_axis_bk , $
      energy_axis   : e_axis_bk, $
      pixel_mask    : pixel_mask_used , $
      detector_mask : detector_mask_used, $
      error         : sqrt(spec_in_bk)}

    livetime_frac_bk =  stx_spectrogram_livetime(  spectrogram_bk, corrected_counts = corrected_counts_bk, level = bk_data_level )

    corrected_counts_bk = total(reform(corrected_counts_bk,[dim_counts_bk[0], n_detectors, ntimes_bk ]),2)

    corrected_counts_bk = (total(reform(corrected_counts_bk, dim_counts_bk[0], ntimes_bk),2)/total(data_str_bk.timedel))#data_str.timedel

    corrected_counts_bk  = reform(corrected_counts_bk,dim_counts_bk[0], ntimes)

    corrected_counts_bk =  corrected_counts_bk[energy_bins,*]/reproduce(eff_ewidth, ntimes)

    corrected_counts_bk =  reform(corrected_counts_bk,[n_elements(energy_bins), ntimes])


    spec_in_bk = total(reform(spec_in_bk,[dim_counts_bk[0], n_detectors, ntimes_bk ]),2)

    spec_in_bk = (total(reform(spec_in_bk, dim_counts_bk[0], ntimes_bk),2)/total(data_str_bk.timedel))#data_str.timedel

    spec_in_bk  = reform(spec_in_bk,dim_counts_bk[0], ntimes)

    spec_in_bk =  spec_in_bk[energy_bins,*]/reproduce(eff_ewidth, ntimes)

    spec_in_bk =  reform(spec_in_bk,[n_elements(energy_bins), ntimes])


    error_bk = total(total(data_str.COUNTS_ERR[energy_bins,*,*],2),2)

    spec_in_corr = corrected_counts - corrected_counts_bk ;> 0

    spec_in_uncorr = counts_spec - spec_in_bk ;> 0

    total_error = sqrt(corrected_counts + corrected_counts_bk )


  endif else begin

    spec_in_corr = corrected_counts ; > 0

    spec_in_uncorr = counts_spec ;> 0

    total_error = sqrt(corrected_counts)

  endelse

  eff_livetime_fraction = f_div(counts_spec , corrected_counts , default = 1 )
  eff_livetime_fraction = mean(eff_livetime_fraction, dim = 1)
  eff_livetime_fraction_expanded = transpose(rebin([eff_livetime_fraction],n_elements(eff_livetime_fraction),n_energies))
  spec_in_corr *= eff_livetime_fraction_expanded

  ;insert the information from the telemetry file into the expected stx_fsw_sd_spectrogram structure
  spectrogram = { $
    type          : "stx_fsw_sd_spectrogram", $
    counts        : spec_in_corr, $
    trigger       : transpose(data_str.triggers), $
    time_axis     : t_axis , $
    energy_axis   : e_axis, $
    pixel_mask    : pixel_mask_used , $
    detector_mask : detector_mask_used, $
    error         : total_error}


  srmfilename = 'stx_spectrum_srm_'+hstart_time+'.fits'
  specfilename =  'stx_spectrum_'+hstart_time+'.fits'

  transmission = read_csv(loc_file( 'stix_trans_by_component.csv', path = getenv('STX_GRID') ))

  phe = transmission.field9
  edge_products, phe, mean = mean_phe, width = w_phe
  ph_in = [mean_phe[0]- w_phe[0], mean_phe]

  ospex_obj =   stx_fsw_sd_spectrogram2ospex( spectrogram, ph_energy_edges = ph_in, /include_damage, /fits , /tail,livetime_fraction = eff_livetime_fraction, $
    dist_factor = dist_factor, flare_location= flare_location )

  ospex_obj -> set, spex_eband = get_edges([4.,10.,15.,25, 50, 84.], /edges_2)
  ospex_obj -> plot_time,  spex_units='flux'


  stop
end

