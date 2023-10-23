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
;    flare_location_hpc : in, type="2 element float array"
;               the location of the flare (X,Y) in Helioprojective Cartesian coordinates as seen from Solar Orbiter [arcsec]
;
;    aux_fits_file : in, required if flare_location_hpc is passed in, type="string"
;                the path of the auxiliary ephemeris FITS file to be read."
;               
;    det_ind : in, type="int array", default="all detectors  present in observation"
;              indices of detectors to sum when making spectrogram
;
;    pix_ind : in, type="int array", default="all pixels present in observation"
;               indices of pixels to sum when making spectrogram
;
;    shift_duration : in, type="boolean", default="0"
;                     Shift all time bins by 1 to account for FSW time input discrepancy prior to 09-Dec-2021.
;                     N.B. WILL ONLY WORK WITH FULL TIME RESOLUTION DATA WHICH IS OFTEN NOT THE CASE FOR PIXEL DATA.
;
;    sys_uncert : in, type="float", default="0.05"
;                 The fractional systematic uncertainty to be added
;
;    generate_fits : in, type="boolean", default="1"
;                    If set spectrum and srm FITS files will be generated and read using the stx_read_sp using the
;                    SPEX_ANY_SPECFILE strategy. Otherwise use the spex_user_data strategy to pass in the data
;                    directly to the ospex object.
;
;    specfile : in, type="string", default="'stx_spectrum_' + UID + '.fits'"
;                    File name to use when saving the spectrum FITS file for OSPEX input.
;
;    srmfile : in, type="string", default="'stx_srm_'+ UID + '.fits'"
;                    File name to use when saving the srm FITS file for OSPEX input.
;
;    background_data : out, type="stx_background_data structure"
;                     Structure containing the subtracted background for external plotting.
;
;    plot : in, type="boolean", default="1"
;                     If set open OSPEX GUI and plot lightcurve in standard quicklook energy bands
;                     where there is data present
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
;    04-Jul-2022 - ECMD (Graz), added plot keyword
;    20-Jul-2022 - ECMD (Graz), distance factor now calculated in stx_convert_science_data2ospex
;    08-Aug-2022 - ECMD (Graz), can now pass in file names for the output spectrum and srm FITS files
;                               added keyword to allow the user to specify the systematic uncertainty
;                               generate structure of info parameters to pass through to FITS file
;    16-Aug-2022 - ECMD (Graz), information about subtracted background can now be passed out
;    15-Mar-2023 - ECMD (Graz), updated to handle release version of L1 FITS files
;    16-Jun-2023 - ECMD (Graz), for a source location dependent response estimate, the location in HPC and the auxiliary ephemeris file must be provided.
;
;-
pro  stx_convert_pixel_data, fits_path_data = fits_path_data, fits_path_bk = fits_path_bk, $
  time_shift = time_shift, energy_shift = energy_shift, distance = distance, $
  aux_fits_file = aux_fits_file, flare_location_hpc = flare_location_hpc, flare_location_stx = flare_location_stx, $
  det_ind = det_ind, pix_ind = pix_ind, $
  shift_duration = shift_duration, no_attenuation = no_attenuation, sys_uncert = sys_uncert, $
  generate_fits = generate_fits, specfile = specfile, srmfile = srmfile,$
  background_data = background_data, plot = plot, ospex_obj = ospex_obj


  if n_elements(time_shift) eq 0 then begin
    message, 'Time shift value not set, using default value of 0 [s].', /info
    print, 'File averaged values can be obtained from the FITS file header'
    print, 'using stx_get_header_corrections.pro.'
    time_shift = 0.
  endif

  default, shift_duration, 0
  default, plot, 1
  default, det_ind, 'top24'

  if data_type(det_ind) eq 7 then det_ind = stx_label2det_ind(det_ind)
  if data_type(pix_ind) eq 7 then pix_ind = stx_label2pix_ind(pix_ind)

  stx_compute_subcollimator_indices, g01,g02,g03,g04,g05,g06,g07,g08,g09,g10,$
    l01,l02,l03,l04,l05,l06,l07,l08,l09,l10,$
    res32,res10,o32,g03_10,g01_10,g_plot,l_plot

  ; 22-Jul-2022 - ECMD, changed keyword_set to n_elements as [0] is valid detector or pixel index array
  mask_use_detectors = intarr(32)
  if n_elements(det_ind) eq 0 then mask_use_detectors[g03_10] = 1 else mask_use_detectors[det_ind] = 1

  mask_use_pixels = intarr(12)
  if n_elements(pix_ind) eq 0 then mask_use_pixels[*] = 1 else mask_use_pixels[pix_ind] = 1


  stx_read_pixel_data_fits_file, fits_path_data, time_shift, primary_header = primary_header, data_str = data_str, data_header = data_header, control_str = control_str, $
    control_header= control_header, energy_str = energy_str, energy_header = energy_header, t_axis = t_axis, energy_shift = energy_shift,  e_axis = e_axis , use_discriminators = 0, $
    shift_duration = shift_duration

  data_level = 1

  start_time = atime(stx_time2any((t_axis.time_start)[0]))

  elut_filename = stx_date2elut_file(start_time)
  uid = control_str.request_id

  if n_elements(distance) ne 0 then fits_distance = distance

  fits_info_params = stx_fits_info_params( fits_path_data = fits_path_data, data_level = data_level, $
    distance = fits_distance, time_shift = time_shift, fits_path_bk = fits_path_bk, uid = uid, $
    generate_fits = generate_fits, specfile = specfile, srmfile = srmfile, elut_file = elut_filename)

  counts_in = data_str.counts

  dim_counts = counts_in.dim

  n_times = n_elements(dim_counts) gt 3 ? dim_counts[3] : 1

  energy_edges_used = where(control_str.energy_bin_edge_mask eq 1, n_energy_edges)
  energy_bin_mask = stx_energy_edge2bin_mask(control_str.energy_bin_edge_mask)
  energy_bins = where(energy_bin_mask eq 1, n_energies)

  if n_times eq 1 then begin

    pixels_used =  where(data_str.pixel_masks gt 0 and mask_use_pixels eq 1)
    detectors_used = where(data_str.detector_masks eq 1 and mask_use_detectors eq 1)

  endif else begin

    pixels_used = where(total(data_str.pixel_masks,2) gt 0 and mask_use_pixels eq 1)
    detectors_used = where(total(data_str.detector_masks,2) gt 0 and mask_use_detectors eq 1)

  endelse


  pixel_mask_used = intarr(12)
  pixel_mask_used[pixels_used] = 1
  n_pixels = total(pixel_mask_used)

  detector_mask_used = intarr(32)
  detector_mask_used[detectors_used]  = 1
  n_detectors = total(detector_mask_used)

  if total(pixel_mask_used[0:3]) eq total(pixel_mask_used[4:7]) then begin
    count_ratio_threshold = 1.05
    counts_top = total(counts_in[1:25,0:3,detectors_used,*])
    counts_bottom = total(counts_in[1:25,4:7,detectors_used,*])
    case 1 of
      f_div(counts_top, counts_bottom, default = 2) gt count_ratio_threshold : message, 'Top pixel total 5% higher than bottom row. Possible pixel shadowing. Recommend using only top pixels for analysis.',/info
      f_div(counts_bottom, counts_top, default = 2) gt count_ratio_threshold : message, 'Bottom pixel total 5% higher than top row. Possible pixel shadowing. Recommend using only bottom pixels for analysis.',/info
      else:
    endcase
  endif


  stx_read_elut, ekev_actual = ekev_actual, elut_filename = elut_filename

  ave_edge  = mean(reform(ekev_actual[energy_edges_used-1, pixels_used, detectors_used, 0 ],n_energy_edges, n_pixels, n_detectors), dim= 2)
  ave_edge  = mean(reform(ave_edge,n_energy_edges, n_detectors), dim= 2)


  edge_products, ave_edge, width = ewidth

  eff_ewidth =  (e_axis.width)/ewidth


  counts_in = reform(counts_in,[dim_counts[0:2], n_times])

  spec_in = total(reform(counts_in[*,pixels_used,detectors_used,*],[32,n_pixels,n_detectors,n_times]),2)

  spec_in = reform(spec_in,[dim_counts[0],n_detectors, n_times])

  counts_spec =  spec_in[energy_bins,*, *] * reform(reproduce(eff_ewidth, n_detectors*n_times),n_energies, n_detectors, n_times)

  counts_spec =  reform(counts_spec,[n_energies, n_detectors, n_times])


  counts_err = reform(data_str.counts_err,[dim_counts[0:2], n_times])

  counts_err = sqrt(total(reform(counts_err[*,pixels_used,detectors_used,*]^2.,[32,n_pixels,n_detectors,n_times]),2))

  counts_err = reform(counts_err,[dim_counts[0],n_detectors, n_times])

  counts_err =  counts_err[energy_bins,*, *] * reform(reproduce(eff_ewidth, n_detectors*n_times),n_energies, n_detectors, n_times)

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
  ; ***** Andrea: 2022-April-05
  ; Temporarily creation of the no_attenuation keyword in order
  ; to avoid attenuation of the fitted curve. This is useful for
  ; obtaining thermal fit parameters with the BKG detector in the
  ; case the attenuator is inserted. We tested it with the X
  ; class flare on 2021-Oct-26 and it works nicely.
  if keyword_set(no_attenuation) then begin
    rcr = rcr*0.
    index = 0
    state = 0
  endif
  ; ************************************************************
  ; ************************************************************

  ; ******************** TEMPORARY FIX *************************
  ; ***** ECMD: 2022-Jun-27
  ; As the reported time of the RCR status change can be inaccurate
  ; up to several seconds correct this by finding the times where there is a
  ; large change in counts in the counts of the 5 - 6 keV energy bin.
  ; find all time intervals where the difference between adjacent bins is large
  if max(rcr) gt 0 then begin; skip if in the standard state of RCR0 for the full time range

    jumps = where(abs((total(counts_spec,2))[2,*] - shift((total(counts_spec,2))[2,*],-1)) gt 1e4)
    ; include the starting bin
    jumps = [0, jumps]
    ; as the attenuator motion can be present in two consecutive bins select only the first
    idx_jumps =  where(abs(jumps - shift(jumps, -1)) gt 2)
    jumps_use= [jumps[idx_jumps]]
    ; each transition should correspond close in time to a recorded transition in the FITS file
    ; adjust the time indexes of these transitions to the closest jumps
    closest_jumps = value_closest(jumps_use, index)
    index = jumps_use[closest_jumps]

  endif
  ; ************************************************************

  ;add the rcr information to a specpar structure so it can be included in the spectrum FITS file
  specpar = { sp_atten_state :  {time:ut_rcr[index], state:state}, flare_xyoffset : fltarr(2), use_flare_xyoffset:0 }

  stx_convert_science_data2ospex, spectrogram = spectrogram, specpar=specpar, time_shift = time_shift, $
    data_level = data_level, data_dims = data_dims, fits_path_bk = fits_path_bk, distance = distance, fits_path_data = fits_path_data,$
    aux_fits_file = aux_fits_file, flare_location_hpc = flare_location_hpc, flare_location_stx = flare_location_stx, $
    eff_ewidth = eff_ewidth, sys_uncert = sys_uncert, plot = plot, background_data = background_data, $
    fits_info_params = fits_info_params, ospex_obj = ospex_obj

end

