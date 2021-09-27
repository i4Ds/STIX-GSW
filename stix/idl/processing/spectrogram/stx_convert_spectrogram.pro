pro  stx_convert_spectrogram, fits_path_data = fits_path_data, fits_path_bk = fits_path_bk, time_shift = time_shift, energy_shift = energy_shift, distance = distance, $
  flare_location= flare_location, elut_filename = elut_filename, replace_doubles = replace_doubles, keep_short_bins = keep_short_bins, ospex_obj = ospex_obj


  default, time_shift, 0.
  default, energy_shift, 0.
  default, distance, 1.
  default, flare_location, [0.,0.]
  default, elut_filename, 'elut_table_20200519.csv'

  dist_factor = 1./(distance^2.)

  stx_read_spectrogram_fits_file, fits_path_data, time_shift, primary_header = primary_header, data_str = data_str, data_header = data_header, control_str = control_str, $
    control_header= control_header, energy_str = energy_str, energy_header = energy_header, t_axis = t_axis, energy_shift = energy_shift,  e_axis = e_axis , use_discriminators = 0,$
    replace_doubles = replace_doubles, keep_short_bins = keep_short_bins

  data_level = 4

  hstart_time = (sxpar(primary_header, 'DATE_BEG'))

  counts_in = data_str.counts

  dim_counts = counts_in.dim

  n_times = n_elements(dim_counts) gt 1 ? dim_counts[1] : 1

  energy_bin_mask = control_str.energy_bin_mask

  pixels_used = where(control_str.pixel_mask eq 1)
  detectors_used = where(control_str.detector_mask eq 1)


  energy_bins = where( energy_bin_mask eq 1 )
  n_energies = n_elements(energy_bins)
  pixel_mask_used = intarr(12)
  pixel_mask_used[pixels_used] = 1
  n_pixels = total(pixel_mask_used)

  detector_mask_used = intarr(32)
  detector_mask_used[detectors_used] = 1
  n_detectors = total(detector_mask_used)

  energy_edges_used = [e_axis.low_fsw_idx, e_axis.high_fsw_idx[-1]+1]
  n_energy_edges = n_elements(energy_edges_used)

  stx_read_elut, ekev_actual = ekev_actual, elut_filename = elut_filename

  ave_edge  = mean(reform(ekev_actual[energy_edges_used-1, pixels_used, detectors_used, 0 ], n_energy_edges, n_pixels, n_detectors), dim = 2)
  ave_edge  = mean(reform(ave_edge,n_energy_edges, n_detectors), dim = 2)


  edge_products, ave_edge, width = ewidth

  eff_ewidth =  (e_axis.width)/ewidth

  counts_in = reform(counts_in,[dim_counts[0], n_times])

  spec_in = counts_in

  counts_spec =  spec_in[energy_bins, *]/ reproduce(eff_ewidth, n_times)

  counts_spec =  reform(counts_spec,[n_energies, n_times])

  counts_err = data_str.counts_err[energy_bins,*]

   triggers =  reform(counts_spec,[n_energies, n_times]) 
 
  ;insert the information from the telemetry file into the expected stx_fsw_sd_spectrogram structure
  spectrogram = { $
    type          : "stx_fsw_sd_spectrogram", $
    counts        : counts_spec, $
    trigger       : reform(long(data_str.triggers),1,n_times), $
    time_axis     : t_axis , $
    energy_axis   : e_axis, $
    pixel_mask    : pixel_mask_used , $
    detector_mask : detector_mask_used, $
    error         : counts_err}

  data_dims = lonarr(4)
  data_dims[0] = n_energies
  data_dims[1] = 1
  data_dims[2] = 1
  data_dims[3] = n_times

  stx_convert_science_data2ospex, spectrogram = spectrogram, data_level = data_level, data_dims = data_dims, fits_path_bk = fits_path_bk, $
    dist_factor = dist_factor, flare_location= flare_location, eff_ewidth = eff_ewidth, ospex_obj = ospex_obj

end

