;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_convert_spectrogram
;
; :description:
;    This procedure reads a STIX science data x-ray compaction level 4 (spectrogram) and converts it to a spectrogram
;    file which can be read in by OSPEX. This spectrogram is in the from of an array in energy and time so individual pixel and detector counts
;    are summed. A corresponding detector response matrix file is also produced. If a background file is supplied this is will be subtracted
;    A number of corrections for light travel time,
;
; :categories:
;    spectroscopy
;
; :keywords:
;
;    fits_path_data : in, required, type="string"
;              The path to the sci-xray-spec (or sci-spectrogram) observation file
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
;      fits_path_data   = 'solo_L1A_stix-sci-spectrogram-2104170001_20210417T153019-20210417T171825_010019_V01.fits'
;      stx_get_header_corrections, fits_path_data, distance = distance, time_shift = time_shift
;      stx_convert_spectrogram, fits_path_data = fits_path_data, distance = distance, time_shift = time_shift, ospex_obj = ospex_obj
;
; :history:
;    18-Jun-2021 - ECMD (Graz), initial release
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
pro  stx_convert_spectrogram, fits_path_data = fits_path_data, fits_path_bk = fits_path_bk,$
  aux_fits_file = aux_fits_file, flare_location_hpc = flare_location_hpc, flare_location_stx = flare_location_stx, $
  time_shift = time_shift, energy_shift = energy_shift, distance = distance,  $
  replace_doubles = replace_doubles, keep_short_bins = keep_short_bins, apply_time_shift = apply_time_shift,$
  shift_duration = shift_duration, no_attenuation = no_attenuation, sys_uncert = sys_uncert, $
  generate_fits = generate_fits, specfile = specfile, srmfile = srmfile,$
  background_data = background_data, plot = plot, ospex_obj = ospex_obj

  if n_elements(time_shift) eq 0 then begin
    message, 'Time shift value is not set. Using default value of 0 [s].', /info
    print, 'File averaged values can be obtained from the FITS file header'
    print, 'using stx_get_header_corrections.pro.'
    time_shift = 0.
  endif


  default, plot, 1

  stx_read_spectrogram_fits_file, fits_path_data, time_shift, primary_header = primary_header, data_str = data_str, data_header = data_header, control_str = control_str, $
    control_header= control_header, energy_str = energy_str, energy_header = energy_header, t_axis = t_axis, energy_shift = energy_shift,  e_axis = e_axis , use_discriminators = 0,$
    replace_doubles = replace_doubles, keep_short_bins = keep_short_bins, shift_duration = shift_duration

  data_level = 4

  start_time = atime(stx_time2any((t_axis.time_start)[0]))

  elut_filename = stx_date2elut_file(start_time)

  uid = control_str.request_id

  fits_info_params = stx_fits_info_params( fits_path_data = fits_path_data, data_level = data_level, $
    distance = distance, time_shift = time_shift, fits_path_bk = fits_path_bk, uid = uid, $
    generate_fits = generate_fits, specfile = specfile, srmfile = srmfile, elut_file = elut_filename)

  counts_in = data_str.counts

  dim_counts = counts_in.dim

  n_times = n_elements(dim_counts) gt 1 ? dim_counts[1] : 1

  pixels_used = where(data_str.pixel_masks eq 1)
  detectors_used = where(control_str.detector_masks eq 1)

  energy_edges_used = where(control_str.energy_bin_edge_mask eq 1, n_energy_edges)
  energy_bin_mask = stx_energy_edge2bin_mask(control_str.energy_bin_edge_mask)
  energy_bins = where(energy_bin_mask eq 1, n_energies)

  pixel_mask_used = intarr(12)
  pixel_mask_used[pixels_used] = 1
  n_pixels = total(pixel_mask_used)

  detector_mask_used = intarr(32)
  detector_mask_used[detectors_used] = 1
  n_detectors = total(detector_mask_used)

  stx_read_elut, ekev_actual = ekev_actual, elut_filename = elut_filename

  ave_edge  = mean(reform(ekev_actual[energy_edges_used-1, pixels_used, detectors_used, 0 ], n_energy_edges, n_pixels, n_detectors), dim = 2)
  ave_edge  = mean(reform(ave_edge,n_energy_edges, n_detectors), dim = 2)


  edge_products, ave_edge, width = ewidth

  eff_ewidth =  (e_axis.width)/ewidth

  counts_in = reform(counts_in,[dim_counts[0], n_times])

  spec_in = counts_in

  counts_spec =  spec_in[energy_bins, *] * reproduce(eff_ewidth, n_times)

  counts_spec =  reform(counts_spec,[n_energies, n_times])

  counts_err = data_str.counts_err[energy_bins,*] * reproduce(eff_ewidth, n_times)

  counts_err =  reform(counts_err,[n_energies, n_times])

  triggers =  reform(data_str.triggers,[1, n_times])

  triggers_err =  reform(data_str.triggers_err,[1, n_times])

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
  data_dims[1] = 1
  data_dims[2] = 1
  data_dims[3] = n_times

  ;get the rcr states and the times of rcr changes from the ql_lightcurves structure
  ut_rcr = stx_time2any(t_axis.time_start)
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

    jumps = where(abs( counts_spec[2,*] - shift(counts_spec[2,*],-1) ) gt 1e4)
    ; include the starting bin
    jumps = [0, jumps]
    ; as the attenuator motion can be present in two consecutive bins select only the first
    idx_jumps =  where(abs(jumps - shift(jumps, -1)) gt 2)
    jumps_use= [jumps[idx_jumps]]
    ; each transition should correspond close in time to a recorded transition in the FITS file
    ; adjust the time indexes of these transitions to the closest jumps
    index = jumps_use

  endif
  ; ************************************************************

  ;add the rcr information to a specpar structure so it can be included in the spectrum FITS file
  specpar = { sp_atten_state :  {time:ut_rcr[index], state:state}, flare_xyoffset : fltarr(2), use_flare_xyoffset:0 }

  stx_convert_science_data2ospex, spectrogram = spectrogram, specpar = specpar, time_shift = time_shift, data_level = data_level, data_dims = data_dims, fits_path_bk = fits_path_bk, $
    distance = distance, fits_path_data = fits_path_data,  eff_ewidth = eff_ewidth, fits_info_params = fits_info_params, sys_uncert = sys_uncert, $
    aux_fits_file = aux_fits_file, flare_location_hpc = flare_location_hpc, flare_location_stx = flare_location_stx, $
    background_data = background_data, plot = plot, generate_fits = generate_fits, ospex_obj = ospex_obj

end

