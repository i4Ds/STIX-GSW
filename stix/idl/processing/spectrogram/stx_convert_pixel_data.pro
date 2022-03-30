;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_convert_pixel_data
;
; :description:
;    This procedure reads a STIX science data x-ray compaction level 1 (compressed pixel data file) and converts it to a spectrogram
;    file which can be read in by OSPEX. This spectrogram is in the from of an array in energy and time so individual pixel and detector counts
;    are summed. A corresponding detector response matrix file is also produced. If a background file is supplied this will be subtracted
;    A number of corrections for light travel time,
;
; :categories:
;    spectroscopy
;
; :keywords:
;
;    fits_path_data : in, required, type="string"
;              The path to the sci-xray-cpd (or sci-xray-l1) observation file
;
;    fits_path_bk : in, optional, type="string"
;              The path to file containing the background observation this should be in pixel data format i.e. sci-xray-cpd (or sci-xray-l1)
;
;    distance : in, optional, type="float", default= "1."
;               The distance between Solar Orbiter and the Sun centre in Astronomical Units needed to correct flux.
;
;    time_shift : in, optional, type="float", default="0."
;               The difference in seconds in light travel time between the Sun and Earth and the Sun and Solar Orbiter
;               i.e. Time(Sun to Earth) - Time(Sun to S/C)
;
;    energy_shift : in, optional, type="float", default="0."
;               Shift all energies by this value in keV. Rarely needed only for cases where there is a significant shift
;               in calibration before a new ELUT can be uploaded.
;
;    flare_location : in, type="float array", default="[0.,0.]"
;               the location of the flare in heliocentric coordinates as seen from Solar Orbiter
;
;    det_ind : in, type="int array", default="all detectors  present in observation"
;              indices of detectors to sum when making spectrogram
;
;    pix_ind : in, type="int array", default="all pixels present in observation"
;               indices of pixels to sum when making spectrogram
;
;    shift_duration : in, type="boolean", default="0"
;                     Shift all time bins by 1 to account for FSW time input discrepancy prior to 09-Dec-2021.
;                     N.B. WILL ONLY WORK WITH FULL TIME RESOUTION DATA WHICH IS OFTEN NOT THE CASE FOR PIXEL DATA.
;
;    ospex_obj : out, type="OSPEX object"
;
;
; :examples:
;      fits_path_data   = 'solo_L1A_stix-sci-xray-l1-2104170007_20210417T153019-20210417T171825_009610_V01.fits'
;      stx_get_header_corrections, fits_path_data, distance = distance, time_shift = time_shift
;      stx_convert_pixel_data, fits_path_data = fits_path_data, distance = distance, time_shift = time_shift, ospex_obj = ospex_obj
;
; :history:
;    18-Jun-2021 - ECMD (Graz), initial release
;    19-Jan-2022 - Andrea (FHNW), added keywords for selecting a subset of pixels and detectors for OSPEX
;    22-Feb-2022 - ECMD (Graz), documented, added default warnings, elut is determined by stx_date2elut_file, improved error calculation 
;                               
;-
pro  stx_convert_pixel_data, fits_path_data = fits_path_data, fits_path_bk = fits_path_bk, time_shift = time_shift, energy_shift = energy_shift, distance = distance, $
  flare_location= flare_location, ospex_obj = ospex_obj, det_ind = det_ind, pix_ind = pix_ind, shift_duration = shift_duration, no_attenuation=no_attenuation

  if n_elements(time_shift) eq 0 then begin
    message, 'Time shift value not set using default value of 0 [s].', /info
    print, 'File averaged values can be obtained from the FITS file header'
    print, 'using stx_get_header_corrections.pro.'
    time_shift = 0.
  endif

  if n_elements(distance) eq 0 then begin
    message, 'Distance value not set using default value of 1 [AU].', /info
    print, 'File averaged values can be obtained from the FITS file header'
    print, 'using stx_get_header_corrections.pro.'
    distance = 1.
  endif

  default, energy_shift, 0.
  default, flare_location, [0.,0.]
  default, shift_duration, 0

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
  if not keyword_set(det_ind) then mask_use_detectors[g03_10] = 1 else mask_use_detectors[det_ind] = 1

  mask_use_pixels = intarr(12)
  if not keyword_set(pix_ind) then mask_use_pixels[*] = 1 else mask_use_pixels[pix_ind] = 1


  stx_read_pixel_data_fits_file, fits_path_data, time_shift, primary_header = primary_header, data_str = data_str, data_header = data_header, control_str = control_str, $
    control_header= control_header, energy_str = energy_str, energy_header = energy_header, t_axis = t_axis, energy_shift = energy_shift,  e_axis = e_axis , use_discriminators = 0, $
    shift_duration = shift_duration

  data_level = 1

  hstart_time = (sxpar(primary_header, 'DATE_BEG'))

  elut_filename = stx_date2elut_file(hstart_time)

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


  counts_err = reform(data_str.counts_err,[dim_counts[0:2], n_times])

  counts_err = sqrt(total(reform(counts_err[*,pixels_used,detectors_used,*]^2.,[32,n_pixels,n_detectors,n_times]),2))

  counts_err = reform(counts_err,[dim_counts[0],n_detectors, n_times])

  counts_err =  counts_err[energy_bins,*, *]/ reform(reproduce(eff_ewidth, n_detectors*n_times),n_energies, n_detectors, n_times)

  counts_err =  reform(counts_err,[n_energies, n_detectors, n_times])

  triggers =  transpose(reform(data_str.triggers,[16, n_times]))

  triggers_err =  transpose(reform(data_str.triggers_err,[16, n_times]))


  rcr = data_str.rcr

  ;insert the information from the telemetry file into the expected stx_fsw_sd_spectrogram structure
  spectrogram = { $
    type          : "stx_fsw_sd_spectrogram", $
    counts        : counts_spec, $
    trigger       : triggers, $
    trigger_err   : triggers_err, $
    time_axis     : t_axis , $
    energy_axis   : e_axis, $
    pixel_mask    : pixel_mask_used , $
    detector_mask : detector_mask_used, $
    rcr           : rcr, $
    error         : counts_err}

  data_dims = lonarr(4)
  data_dims[0] = n_energies
  data_dims[1] = n_detectors
  data_dims[2] = n_pixels
  data_dims[3] = n_times

  ;get the rcr states and the times of rcr changes from the ql_lightcurves structure
  ut_rcr = stx_time2any(t_axis.time_end)

  find_changes, rcr, index, state, count=count

  ; ************************************************************
  ; ******************** TEMPORARY FIX *************************
  ; Temporarily creation of the no_attenuation keyword in order
  ; to avoid attenuation of the fitted curve for the case
  ; we want to fit the spectrum with the BKG detector.
  if keyword_set(no_attenuation) then begin
    rcr = rcr*0.
    index = 0
    state = 0
  endif
  ; ************************************************************
  ; ************************************************************

  ;add the rcr information to a specpar structure so it can be incuded in the spectrum FITS file
  specpar = { sp_atten_state :  {time:ut_rcr[index], state:state} }

  stx_convert_science_data2ospex, spectrogram = spectrogram, specpar=specpar, time_shift = time_shift, data_level = data_level, data_dims = data_dims,  fits_path_bk = fits_path_bk,$
    dist_factor = dist_factor, flare_location= flare_location, eff_ewidth = eff_ewidth,ospex_obj = ospex_obj

end

