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
;    file which can be read in by OSPEX. This spectrogram is in the form of an array in energy and time so individual pixel and detector counts
;    are summed. A corresponding detector response matrix file is also produced. If a background file is supplied this will be subtracted
;    A number of corrections for light travel time, (...) are applied.
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
;    silent : in, type="int", default="0"
;             If set prevents informational messages being displayed.
;
;    plot : in, type="boolean", default="1"
;                     If set open OSPEX GUI and plot lightcurve in standard quicklook energy bands
;                     where there is data present
;
;    xspec : in, type="boolean", default="0"
;                     If set, generate SRM file compatible with XSPEC rather than OSPEX.
;
;    ospex_obj : out, type="OSPEX object"
;
;    delta_time_min: in, type="float". Pixel data counts are rebinned in time in such a way that the
;                    time resolution is at least equal to delta_time_min (defined in seconds).
;                    Rebinned data are used to construct spectra needed for the ELUT correction.
;
;    calib_data: if a 'stx_calibration_data' structure is passed as input, then the ELUT correction is applied 
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
;    06-Dec-2023 - ECMD (Graz), added silent keyword, more information is now printed if not set
;    2024-07-12, F. Schuller (AIP): added optional keyword xspec
;    07-May-2025 - Stiefel M. and Massa P., re-implemented to take into account new ELUT correction, new subcollimator transmission and live time normalization
;
;-
pro  stx_convert_pixel_data, fits_path_data = fits_path_data, fits_path_bk = fits_path_bk, $
  time_shift = time_shift, energy_shift = energy_shift, distance = distance, $
  flare_location_stx = flare_location_stx, det_ind = det_ind, pix_ind = pix_ind, calib_data = calib_data, shift_duration = shift_duration, $
  no_attenuation = no_attenuation, sys_uncert = sys_uncert, generate_fits = generate_fits, specfile = specfile, $
  srmfile = srmfile, silent = silent, plot = plot, xspec=xspec, ospex_obj = ospex_obj, $
  delta_time_min = delta_time_min, tailing=tailing, include_damage=include_damage, _extra=extra

  default, shift_duration, 0
  default, plot, 1
  default, det_ind, 'top24'
  default, silent, 0
  default, xspec, 0
  default, sys_uncert, 0.05
  default, delta_time_min, 20.
  default, tailing, 1
  default, include_damage, 1
  default, flare_location_stx, [0.,0.]

  if n_elements(time_shift) eq 0 then begin
    if ~keyword_set(silent) then begin
      message, 'Time shift value not set, using default value of 0 [s].', /info
      print, 'File averaged values can be obtained from the FITS file header'
      print, 'using stx_get_header_corrections.pro.'
    endif
    time_shift = 0.
  endif

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

  ;;***************** READ SCIENCE AND BKG DATA

  stx_read_pixel_data_fits_file, fits_path_data, time_shift, primary_header = primary_header, data_str = data_str, data_header = data_header, control_str = control_str, $
    control_header= control_header, energy_str = energy_str, energy_header = energy_header, t_axis = t_axis, energy_shift = energy_shift,  e_axis = e_axis , use_discriminators = 0, $
    shift_duration = shift_duration, silent=silent

  ;; Select indices of the energy bins (among the 32) that are actually present in the pixel data science file
  energy_bin_mask = data_str.energy_bin_mask
  energy_bin_idx  = where(energy_bin_mask eq 1)

  energy_low  = e_axis.LOW
  energy_high = e_axis.HIGH

  energy_min = min(energy_low)
  energy_max = max(energy_high)

  ;; Read BKG data
  if keyword_set(fits_path_bk) then begin

    stx_read_pixel_data_fits_file, fits_path_bk, data_str = data_bkg, t_axis = t_axis_bkg, e_axis = e_axis_bkg, _extra=extra

    if n_elements(t_axis_bkg.DURATION) gt 1 then message, 'The chosen file does not contain a background measurement'

    ;; Select indices of the energy bins (among the 32) that are actually present in the pixel data bkg file
    energy_bin_mask_bkg = data_bkg.energy_bin_mask
    energy_bin_idx_bkg = where(energy_bin_mask_bkg eq 1)

    energy_low_bkg  = e_axis_bkg.LOW
    energy_high_bkg = e_axis_bkg.HIGH

    ;; Extract energy range in common between science and background file
    energy_min = max([energy_min,min(energy_low_bkg)])
    energy_max = min([energy_max,max(energy_high_bkg)])
    idx_energy_bkg = where((energy_low_bkg ge energy_min) and (energy_high_bkg le energy_max))

    energy_bin_idx_bkg = energy_bin_idx_bkg[idx_energy_bkg]
    energy_low_bkg = energy_low_bkg[idx_energy_bkg]
    energy_high_bkg = energy_high_bkg[idx_energy_bkg]

  endif

  ;; Extract energy range in common between science and background file
  idx_energy = where((energy_low ge energy_min) and (energy_high le energy_max))

  energy_bin_idx = energy_bin_idx[idx_energy]
  energy_low = energy_low[idx_energy]
  energy_high = energy_high[idx_energy]

  ct_edges = get_uniq( [energy_low,energy_high],epsilon=0.0001)

  ;;***************** READ FITS INFO PARAMS

  data_level = 1

  uid = control_str.request_id

  if n_elements(distance) ne 0 then fits_distance = distance

  ;; Check if science and background files are reconrded with the same ELUT
  elut_filename = stx_date2elut_file(stx_time2any(t_axis.TIME_START[0]))
  stx_read_elut, elut_gain, elut_offset, adc4096_str, elut_filename = elut_filename

  fits_info_params = stx_fits_info_params( fits_path_data = fits_path_data, data_level = data_level, $
    distance = fits_distance, time_shift = time_shift, fits_path_bk = fits_path_bk, uid = uid, $
    generate_fits = generate_fits, specfile = specfile, srmfile = srmfile, elut_file = elut_filename, silent = silent)

  ;;***************** CHECK FOR POTENTIAL PIXEL SHADOWING

  counts = data_str.COUNTS
  counts_error = data_str.COUNTS_ERR

  dim_counts = counts.dim

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

  ;; Check if the top or bottom row of pixels is not fully-illuminated
  if ~keyword_set(silent) then begin
    if total(pixel_mask_used[0:3]) eq total(pixel_mask_used[4:7]) then begin
      count_ratio_threshold = 1.05
      counts_top = total(counts[1:25,0:3,detectors_used,*])
      counts_bottom = total(counts[1:25,4:7,detectors_used,*])
      case 1 of
        f_div(counts_top, counts_bottom, default = 2) gt count_ratio_threshold : message, 'Top pixel total 5% higher than bottom row. Possible pixel shadowing. Recommend using only top pixels for analysis.',/info
        f_div(counts_bottom, counts_top, default = 2) gt count_ratio_threshold : message, 'Bottom pixel total 5% higher than top row. Possible pixel shadowing. Recommend using only bottom pixels for analysis.',/info
        else:
      endcase
    endif
  endif

  ;;***************** Compute count rates (normalize by livetime)

  counts = counts[energy_bin_idx,*,*,*]
  counts_error = counts_error[energy_bin_idx,*,*,*]

  if keyword_set(fits_path_bk) then begin

    elut_filename_bkg = stx_date2elut_file(stx_time2any(t_axis_bkg.TIME_START))
    stx_read_elut, ekev_actual = ekev_actual_bkg, elut_filename = elut_filename_bkg

    ;; Compare ELUT tables
    elut_comp = STRCMP(elut_filename, elut_filename_bkg)

    if not elut_comp then $
      message, 'The background file must be recorded when the same ELUT as the science file was uploaded. Please choose a different background file that is closer in time to the science file.'

    counts_bkg       = data_bkg.COUNTS
    counts_error_bkg = data_bkg.COUNTS_ERR
    counts_bkg       = counts_bkg[energy_bin_idx_bkg,*,*]
    counts_error_bkg = counts_error_bkg[energy_bin_idx_bkg,*,*]

  endif else begin

    counts_bkg       = dblarr(size(counts, /dim))
    counts_error_bkg = dblarr(size(counts, /dim))

  endelse

  ;; Compute live time
  live_time_data = stx_cpd_livetime(data_str.TRIGGERS, data_str.TRIGGERS_ERR, t_axis)
  live_time_bins = live_time_data.LIVE_TIME_BINS
  live_time_bins_error = live_time_data.LIVE_TIME_BINS_ERR
  live_time_fraction_bins = live_time_data.LIVETIME_FRACTION

  live_time_bins_rep = transpose(cmreplicate(live_time_bins, [n_elements(energy_bin_idx),12]), [2,3,0,1])
  live_time_bins_error_rep = transpose(cmreplicate(live_time_bins_error, [n_elements(energy_bin_idx),12]), [2,3,0,1])

  if keyword_set(fits_path_bk) then begin

    live_time_bkg_data = stx_cpd_livetime(data_bkg.TRIGGERS, data_bkg.TRIGGERS_ERR, t_axis_bkg)
    live_time_bkg = live_time_bkg_data.LIVE_TIME_BINS
    live_time_error_bkg = live_time_bkg_data.LIVE_TIME_BINS_ERR

  endif else begin

    live_time_bkg = dblarr(32) + 1.
    live_time_error_bkg = dblarr(32)

  endelse

  live_time_bkg_rep = transpose(cmreplicate(live_time_bkg, [n_elements(energy_bin_idx),12]), [1,2,0])
  live_time_error_bkg_rep = transpose(cmreplicate(live_time_error_bkg, [n_elements(energy_bin_idx),12]), [1,2,0])

  ;; Normalize by livetime
  count_rates = f_div( counts, live_time_bins_rep )
  count_rates_error = count_rates * sqrt( f_div( counts_error, counts )^2. + f_div( live_time_bins_error_rep, live_time_bins_rep )^2. )

  count_rates_bkg = f_div( counts_bkg, live_time_bkg_rep )
  count_rates_bkg_error = count_rates_bkg * sqrt( f_div( counts_error_bkg, counts_bkg )^2. + f_div( live_time_error_bkg_rep, live_time_bkg_rep )^2. )

  if n_times gt 1 then begin

    count_rates_bkg = cmreplicate( count_rates_bkg, n_times);[1,n_times] )
    count_rates_bkg_error = cmreplicate( count_rates_bkg_error, n_times);[1,n_times] )

  endif

  ;; Apply BKG subtraction
  count_rates = count_rates - count_rates_bkg
  count_rates_error = sqrt( count_rates_error^2. + count_rates_bkg_error^2. )

  ;;***************** APPLY ELUT CORRECTION

  if (total(pixel_mask_used[0:3]) gt 0.) and (total(pixel_mask_used[4:7]) gt 0.) $
    and (total(pixel_mask_used[8:11]) gt 0.) then sumcase = 'ALL'

  if (total(pixel_mask_used[0:3]) gt 0.) and (total(pixel_mask_used[4:7]) gt 0.) $
    and (total(pixel_mask_used[8:11]) eq 0.) then sumcase = 'TOP+BOT'

  if (total(pixel_mask_used[0:3]) gt 0.) and (total(pixel_mask_used[4:7]) eq 0.) $
    and (total(pixel_mask_used[8:11]) eq 0.) then sumcase = 'TOP'

  if (total(pixel_mask_used[0:3]) eq 0.) and (total(pixel_mask_used[4:7]) gt 0.) $
    and (total(pixel_mask_used[8:11]) eq 0.) then sumcase = 'BOT'

  if (total(pixel_mask_used[0:3]) eq 0.) and (total(pixel_mask_used[4:7]) eq 0.) $
    and (total(pixel_mask_used[8:11]) gt 0.) then sumcase = 'SMALL'

  case sumcase of

    'TOP':     begin
      pixel_ind = [0]
    end

    'BOT':     begin
      pixel_ind = [1]
    end

    'TOP+BOT': begin
      pixel_ind = [0,1]
    end

    'ALL': begin
      pixel_ind = [0,1,2]
    end

    'SMALL': begin
      pixel_ind = [2]
    end
  end



  if keyword_set(calib_data) then begin
    
    ;; Create daily ELUT
    energy_bin_low = calib_data.ENERGY_BIN_LOW
    energy_bin_high = calib_data.ENERGY_BIN_HIGH

    energy_bin_low  = energy_bin_low[energy_bin_idx,*,*]
    energy_bin_high = energy_bin_high[energy_bin_idx,*,*]

    ; Rebin counts in time. From stx_science_data_lightcurve:
    ; determine time bins with minimum duration - keep adding consecutive bins until the minimum
    ; value is at least reached

    duration = t_axis.DURATION

    i=0
    j=0
    total_time=0
    iall=[]

    while (i lt n_elements(duration)-1) do begin
      while (total_time lt delta_time_min)  and (i+j le n_elements(duration)-1) do begin
        total_time = total(duration[i:i+j])
        j++
      endwhile
      iall = [iall,i]
      i = i+j
      j = 0
      total_time = 0
    endwhile

    idx_time_min = iall[0:-2]
    idx_time_max = iall[1:-1]-1
    
    

    count_rates_elut = fltarr(count_rates.dim)
    count_rates_error_elut = fltarr(count_rates_error.dim)

    n_times_rebinned = n_elements(idx_time_min)

    for t_bin = 0,n_times_rebinned-1 do begin

      this_count_rates = reform(count_rates[*,*,*,idx_time_min[t_bin]:idx_time_max[t_bin]])
      this_count_rates_error = reform(count_rates_error[*,*,*,idx_time_min[t_bin]:idx_time_max[t_bin]])

      if idx_time_max[t_bin]-idx_time_min[t_bin] ge 1 then begin

        rebinned_count_rates = average(this_count_rates, 4)

      endif else begin

        rebinned_count_rates = this_count_rates

      endelse

      if n_elements(pixels_used) gt 1 then begin

        spectrum = total(rebinned_count_rates[*,pixels_used,*], 2)

      endif else begin

        spectrum = reform(rebinned_count_rates[*,pixels_used,*])

      endelse

      if n_elements(detectors_used) gt 1 then begin

        spectrum = total(spectrum[*,detectors_used], 2)

      endif else begin

        spectrum = reform(spectrum[*,detectors_used])

      endelse

      spectrum = spectrum / (energy_high - energy_low)

      ;; Apply ELUT correction
      for e_bin=0,n_elements(idx_energy)-1 do begin

        this_energy_range = [energy_low[e_bin], energy_high[e_bin]]

        elut_data = stx_elut_correction(this_count_rates, this_count_rates_error, $
          energy_bin_idx, energy_bin_low, energy_bin_high, energy_high, energy_low, e_bin, this_energy_range, $
          spectrum, pixels_used, detectors_used, /silent)

        count_rates_elut[e_bin,*,*,idx_time_min[t_bin]:idx_time_max[t_bin]] = elut_data.COUNTS
        count_rates_error_elut[e_bin,*,*,idx_time_min[t_bin]:idx_time_max[t_bin]] = elut_data.COUNTS_ERROR

      endfor
      
    endfor

    count_rates = count_rates_elut
    count_rates_error = count_rates_error_elut

  endif

  ;;***************** CREATE SPECTROGRAM

  if n_elements(pixels_used) gt 1 then begin

    spec = total(count_rates[*,pixels_used,*,*], 2)
    spec_error = sqrt(total(count_rates_error[*,pixels_used,*,*]^2., 2))

  endif else begin

    spec = reform(count_rates[*,pixels_used,*,*])
    spec_error = reform(count_rates_error[*,pixels_used,*,*])

  endelse

  if n_elements(detectors_used) gt 1 then begin

    spec = total(spec[*,detectors_used,*], 2)
    spec_error = sqrt(total(spec_error[*,detectors_used,*]^2., 2))

  endif else begin

    spec = reform(spec[*,detectors_used,*])
    spec_error = reform(spec_error[*,detectors_used,*])

  endelse

  ;; Compute average livetime and livetime fraction
  avg_live_time_bins = average(live_time_bins[detectors_used,*], 1)
  avg_live_time_fraction_bins = average(live_time_fraction_bins[detectors_used,*], 1)

  ;; Multiply by average live time. The units of the spectrogram are counts
  avg_live_time_bins_rep = transpose(cmreplicate(avg_live_time_bins, n_elements(energy_bin_idx)))

  spec *= avg_live_time_bins_rep
  spec_error *= avg_live_time_bins_rep

  ;;***************** CHECK FOR RCR CHANGES

  rcr = data_str.rcr

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
    jumps = where(abs(total(spec,1) - shift(total(spec,1),-1)) * 24. / n_elements(detectors_used) gt 1e4)
    ;jumps = where(abs(total(spec,1) - shift(total(spec,1),-1)) gt 1e4)
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

  ;add the rcr information to a specpar structure so it can be included in the spectrum FITS file
  specpar = { sp_atten_state :  {time:ut_rcr[index], state:state}, flare_xyoffset : fltarr(2), use_flare_xyoffset:0 }

  ;;***************** CREATE SRM

  pixel_mask =detector_mask_used ## pixel_mask_used

  transmission = read_csv(loc_file( 'stix_transmission_highres_20251110.csv', path = getenv('STX_GRID')))

  emin = 4
  emax = 150
  phe = transmission.(0)
  phe = phe[where(phe gt emin-1 and phe lt 3.5*emax)]
  edge_products, phe, mean = mean_phe, width = w_phe
  ph_edges = [mean_phe[0] - w_phe[0], mean_phe]

  distance = fits_info_params.distance
  dist_factor = 1./(distance^2.)

  ;make the srm for the appropriate pixel mask and energy edges
  ;srm = stx_build_pixel_drm(ct_edges, pixel_mask,  ph_energy_edges = ph_edges, dist_factor = dist_factor, tailing = tailing, include_damage = include_damage, _extra=extra)
  ph_edges =  get_uniq( [ph_edges,ct_edges],epsilon=0.0001)

  ;; Compute subc. transmission
  edge_products,ph_edges, mean=ph_in
  subc_transmission = stx_subc_transmission(flare_location_stx, ph_in, _extra=extra)

  if n_elements(detectors_used) eq 1 then begin
    grid_factor = reform(subc_transmission[*,detectors_used])
  endif else begin
    grid_factor = total(subc_transmission[*,detectors_used],2) / n_elements(detectors_used)
  endelse


  ;; Check if BKG or CFL detectors are used

  idx_cfl = where(detectors_used eq 8, n_cfl)
  idx_bkg = where(detectors_used eq 9, n_bkg)

  if n_cfl eq 1 then message, "CFL detector can not be selected for spectral fitting."
  if (n_elements(detectors_used) gt 1) and (n_bkg eq 1) then message, "BKG detector can not be selected together with imaging detectors for spectral fitting."

  if n_elements(detectors_used) eq 1 then if detectors_used eq 9 then begin
    grid_transmission_file =  concat_dir(getenv('STX_GRID'), 'real_bkg_grid_transmission.txt')
    readcol, grid_transmission_file, bk_grid_factors, format = 'f', skip = 2, silent = silent

    grid_factor = average(bk_grid_factors[pixels_used])

  endif

  ;; Creates appropriate SRM for different attenuator states
  rcr_states = specpar.sp_atten_state.state
  rcr_states = rcr_states[uniq(rcr_states, sort(rcr_states))]
  nrcr_states = n_elements(rcr_states)

  srm_atten = replicate( {rcr:0,  srm:fltarr(n_elements(ct_edges)-1,n_elements(ph_edges)-1)},nrcr_states )

  for i =0,  nrcr_states-1 do begin
    ;make the srm for the appropriate pixel mask and energy edges
    rcr = rcr_states[i]

    srm = stx_build_pixel_drm(ct_edges, pixel_mask, rcr = rcr, grid_factor= grid_factor, ph_energy_edges = ph_edges, dist_factor = dist_factor, tailing = tailing, include_damage = include_damage, _extra=extra)
    srm_atten[i].srm = srm.smatrix
    srm_atten[i].rcr = rcr

  endfor

  ;;***************** SAVE FITS
  detector_label = stx_det_mask2label(detector_mask_used)
  pixel_label = stx_pix_mask2label(pixel_mask_used)

  ospex_obj  = ospex(/no)

  ;if the fits keyword is set write the spectrogram and srm data to fits files and then read them in to the ospex object
  if fits_info_params.generate_fits eq 1 then begin
    utime = transpose([stx_time2any( t_axis.time_start )])

    ;spectrogram structure for passing to fits writer routine
    spectrum_in = { type              : 'stx_spectrogram', $
      data              : spec, $
      t_axis            : t_axis, $
      e_axis            : e_axis, $
      ltime             : avg_live_time_fraction_bins, $
      attenuator_state  : data_str.rcr , $
      error             : spec_error }

    specfilename = fits_info_params.specfile
    srmfilename =  fits_info_params.srmfile

    fits_info_params.grid_factor.add, grid_factor
    fits_info_params.detused = detector_label + ', Pixels: ' + pixel_label

    if keyword_set(xspec) then begin
      ;xspec in general works with energy depandent systematic errors
      e_axis = spectrum_in.e_axis
      n_energies = n_elements(e_axis.mean)
      sys_err  = fltarr(n_energies)

      idx_below10kev = where(e_axis.mean lt 10, cb10)
      sys_err[*] = 0.03
      if cb10 gt 0 then sys_err[idx_below10kev] = 0.05
      idx_below7kev = where(e_axis.mean lt 7, cb7)
      if cb7 gt 0 then sys_err[idx_below7kev] = 0.07

      sys_err = rebin(sys_err, n_energies,n_times)
    endif

    stx_write_ospex_fits, spectrum = spectrum_in, srmdata = srm, specpar = specpar, time_shift = time_shift, $
      srm_atten = srm_atten, specfilename = specfilename, srmfilename = srmfilename, ph_edges = ph_edges, $
      fits_info_params = fits_info_params, xspec = xspec, silent = silent

    ospex_obj->set, spex_file_reader = 'stx_read_sp'
    ospex_obj->set, spex_specfile = specfilename   ; name of your spectrum file
    ospex_obj->set, spex_drmfile = srmfilename

  endif else begin
    ;if the generate_fits keyword is not set use the spex_user_data strategy to pass in the data directly to the ospex object

    energy_edges = e_axis.edges_2
    Edge_Products, ph_edges, edges_2 = ph_edges2

    utime2 = transpose(stx_time2any( [[t_axis.time_start], [t_axis.time_end]] ))

    ospex_obj->set, spex_data_source = 'spex_user_data'
    ospex_obj->set, spectrum = float(spec),  $
      spex_ct_edges = energy_edges, $
      spex_ut_edges = utime2, $
      livetime = avg_live_time_bins_rep, $
      errors = spec_error
    srm = rep_tag_name(srm,'smatrix','drm')
    ospex_obj->set, spex_respinfo = srm
    ospex_obj->set, spex_area = srm.area
    ospex_obj->set, spex_detectors = 'STIX'
    ospex_obj->set, spex_drm_ct_edges = energy_edges
    ospex_obj->set, spex_drm_ph_edges = ph_edges2
  endelse

  ospex_obj->set, spex_uncert = sys_uncert
  ospex_obj->set, spex_error_use_expected = 0

  counts_str = ospex_obj->getdata(spex_units='counts')
  origunits = ospex_obj->get(/spex_data_origunits)
  origunits.data_name = 'STIX'
  ospex_obj->set, spex_data_origunits = origunits

  if keyword_set(plot) then begin
    ospex_obj ->gui
    ospex_obj ->set, spex_eband = get_edges([4.,10.,15.,25, 50, 84.], /edges_2)
    ospex_obj ->plot_time,  spex_units='flux', /show_err, obj = plotman_object
  endif

end

