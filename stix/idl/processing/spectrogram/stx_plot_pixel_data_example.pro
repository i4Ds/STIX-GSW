pro  stx_plot_pixel_data_example, fits_path_data = fits_path_data, fits_path_bk = fits_path_bk, time_shift = time_shift,  dist_factor = dist_factor, $
  flare_location= flare_location, elut_filename = elut_filename, demo = demo 

if keyword_set(demo) then begin
  
  message, 'Running demonstraion - overriding all other input keyowrds', /info 
  fits_path_data = loc_file('solo_L1_stix-sci-xray-l1-1178428688_20200607T213708-20200607T215208_V01_49155.fits', path = concat_dir( getenv('stx_demo_data'),'ospex/sample_data/20200607',/dir) )
  fits_path_bk   = loc_file('solo_L1_stix-sci-xray-l1-1178448400_20200607T224958-20200608T001954_V01_49807.fits', path = concat_dir( getenv('stx_demo_data'),'ospex/sample_data/20200607',/dir) )  
  time_shift = 236.9
  dist_factor =  1./(0.52)^2.
  flare_location = [-1600,-800.]
  elut_filename = 'elut_table_20200519.csv'
  
endif

  stx_read_pixel_data_fits_file, fits_path_data, time_shift, primary_header = primary_header, data_str = data_str, data_header = data_header, control_str = control_str, $
    control_header= control_header, energy_str = energy_str, energy_header = energy_header, t_axis = t_axis, e_axis = e_axis

  hstart_time = (sxpar(primary_header, 'DATE_BEG'))

  counts_in = data_str.counts

  dim_counts = counts_in.dim

  ntimes = n_elements(dim_counts) gt 3 ? dim_counts[3] : 1

  energy_edge_mask = control_str.energy_bin_mask

  ;sum_pixels   = total(total(total(counts_in,1),2),2)
  ;sum_detectors =  total(total(total(counts_in,1),1),2)
  ; idx_excude_det = [8,9,10,12,13,16,18,19] -1
  ; idx_excude_det = [9,10] -1


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

  if ntimes eq 1 then begin

    pixels_used =  where(total(data_str.pixel_masks,2) gt 0 )
    detectors_used = where(data_str.detector_masks eq 1 and mask_use_detectors eq 1)

  endif else begin

    pixels_used = where( where(total(total(data_str.pixel_masks,1),2) gt 0 ) ne 0 )
    detectors_used = where(total(data_str.detector_masks,2) gt 0 and mask_use_detectors eq 1)
    
  endelse

  energies_used = where( energy_edge_mask eq 1 )

  pixel_mask_used = intarr(12)
  pixel_mask_used[pixels_used] = 1

  detector_mask_used = intarr(32)
  detector_mask_used[detectors_used]  = 1

  energy_bins = where(energy_edge_mask[0:-2] eq 1 and energy_edge_mask[1:-1] eq 1 )

  stx_read_elut, ekev_actual = ekev_actual, elut_filename = elut_filename

  ave_edge  =  mean( mean(ekev_actual[energies_used-1, pixels_used, detectors_used, 0], dim = 2 ), dim = 2)

  edge_products, ave_edge, width = ewidth

  eff_ewidth =  (e_axis.width)/ewidth


  counts_in = reform(counts_in,[dim_counts[0:2], ntimes])

  spec_in = total(total(counts_in[*,pixels_used,detectors_used,*],2),2)

  spec_in = reform(spec_in,[dim_counts[0], ntimes])

  counts_spec =  spec_in[energy_bins,*]/reproduce(eff_ewidth, ntimes)

  counts_spec =  reform(counts_spec,[n_elements(energy_bins), ntimes])

  counts_err = total(total(data_str.COUNTS_ERR[energy_bins,*,*],2),2)

  bk_err = total(total(data_str.COUNTS_ERR[energy_bins,*,*],2),2)


  stx_read_pixel_data_fits_file, fits_path_bk,time_shift, data_str = data_str_bk, control_str = control_str_bk, $
    energy_str = energy_str_bk, t_axis = t_axis_bk

  counts_in_bk = data_str_bk.counts

  dim_counts_bk = counts_in_bk.dim

  ntimes_bk = n_elements(dim_counts_bk) gt 3 ? dim_counts_bk[3] : 1

  spec_in_bk = ntimes_bk eq 1 ? (total(total(counts_in_bk[*,pixels_used,detectors_used],2),2)/total(data_str_bk.timedel))#data_str.timedel $
    : (total(total(total(data_str_bk.counts[*,pixels_used,detectors_used],2),2),2)/total(data_str_bk.timedel))#data_str.timedel

  spec_in_bk  =  reform(spec_in_bk,[dim_counts_bk[0], ntimes])

  counts_spec_bk =  spec_in_bk[energy_bins,*]/reproduce(eff_ewidth, ntimes)

  counts_spec_bk =  reform(counts_spec_bk,[n_elements(energy_bins), ntimes])

  spec_in_bsub = counts_spec - counts_spec_bk > 0

  total_error = sqrt(counts_spec + counts_spec_bk )
  ;insert the information from the telemetry file into the expected stx_fsw_sd_spectrogram structure
  spectrogram = { $
    type          : "stx_fsw_sd_spectrogram", $
    counts        : spec_in_bsub, $
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

  ospex_obj =   stx_fsw_sd_spectrogram2ospex( spectrogram, ph_energy_edges = phe, /include_damage, /fits , /tail, dist_factor = dist_factor, flare_location= flare_location )


  ospex_obj -> set, spex_eband =  get_edges([4.,10.,15.,25, 50, 84.], /edges_2)
  ospex_obj -> plot_time,  spex_units='flux'


  stop
end

