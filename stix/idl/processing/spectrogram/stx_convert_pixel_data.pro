pro  stx_convert_pixel_data, fits_path_data = fits_path_data, fits_path_bk = fits_path_bk, time_shift = time_shift, energy_shift = energy_shift, distance = distance, $
  flare_location= flare_location, elut_filename = elut_filename, demo = demo, ospex_obj = ospex_obj

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


  stx_read_pixel_data_fits_file, fits_path_data, time_shift, primary_header = primary_header, data_str = data_str, data_header = data_header, control_str = control_str, $
    control_header= control_header, energy_str = energy_str, energy_header = energy_header, t_axis = t_axis, energy_shift = energy_shift,  e_axis = e_axis , use_discriminators = 0

  data_level = 1

  hstart_time = (sxpar(primary_header, 'DATE_BEG'))

  counts_in = data_str.counts

  dim_counts = counts_in.dim

  n_times = n_elements(dim_counts) gt 3 ? dim_counts[3] : 1

  energy_bin_mask = control_str.energy_bin_mask


  if n_times eq 1 then begin

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


  counts_in = reform(counts_in,[dim_counts[0:2], n_times])

  spec_in = total(reform(counts_in[*,pixels_used,detectors_used,*],[32,n_pixels,n_detectors,n_times]),2)

  spec_in = reform(spec_in,[dim_counts[0],n_detectors, n_times])

  counts_spec =  spec_in[energy_bins,*, *]/ reform(reproduce(eff_ewidth, n_detectors*n_times),n_energies, n_detectors, n_times)

  counts_spec =  reform(counts_spec,[n_energies, n_detectors, n_times])

  counts_err = sqrt(total(total(data_str.counts[energy_bins,*,*],2),2))

  rcr = data_str.rcr

  ;insert the information from the telemetry file into the expected stx_fsw_sd_spectrogram structure
  spectrogram = { $
    type          : "stx_fsw_sd_spectrogram", $
    counts        : counts_spec, $
    trigger       : transpose(long(data_str.triggers)), $
    time_axis     : t_axis , $
    energy_axis   : e_axis, $
    pixel_mask    : pixel_mask_used , $
    detector_mask : detector_mask_used, $
    rcr : rcr, $
    error         : counts_err}

  data_dims = lonarr(4)
  data_dims[0] = n_energies
  data_dims[1] = n_detectors
  data_dims[2] = n_pixels
  data_dims[3] = n_times

  ;get the rcr states and the times of rcr changes from the ql_lightcurves structure
  ut_rcr = stx_time2any(t_axis.time_end)

  find_changes, rcr, index, state, count=count

  ;add the rcr information to a specpar structure so it can be incuded in the spectrum FITS file
  specpar = { sp_atten_state :  {time:ut_rcr[index], state:state} }

  stx_convert_science_data2ospex, spectrogram = spectrogram, specpar=specpar,data_level = data_level, data_dims = data_dims,  fits_path_bk = fits_path_bk,$
    dist_factor = dist_factor, flare_location= flare_location, eff_ewidth = eff_ewidth,ospex_obj = ospex_obj

end

