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
;    flare_location_stx : in, type="2 element float array"
;               the location of the flare (X,Y) in the STIX imaging frame [arcsec] 
;
;    time_shift : in, optional, type="float", default="0."
;               The difference in seconds in light travel time between the Sun and Earth and the Sun and Solar Orbiter
;               i.e. Time(Sun to Earth) - Time(Sun to S/C)
;
;    energy_shift : in, optional, type="float", default="0."
;               Shift all energies by this value in keV. Rarely needed only for cases where there is a significant shift
;               in calibration before a new ELUT can be uploaded.
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
;    plot : in, type="boolean", default="1"
;                     If set open OSPEX GUI and plot lightcurve in standard quicklook energy bands
;                     where there is data present
;
;    xspec : in, type="boolean", default="0"
;                     If set, generate SRM file compatible with XSPEC rather than OSPEX.
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
;    06-Dec-2023 - ECMD (Graz), added silent keyword, more information is now printed if not set
;    2024-07-12, F. Schuller (AIP): added optional keyword xspec
;    07-May-2026 - Massa P., removed ELUT correction as it is not possible to apply it to spectrogram data. Furter, this routine now calls 'stx_convert_spectrogram2ospex'
;                            which is called also by 'stx_convert_pixel_data'
;-
pro stx_convert_spectrogram, fits_path_data = fits_path_data, fits_path_bk = fits_path_bk,$
  flare_location_stx = flare_location_stx, time_shift = time_shift, energy_shift = energy_shift, $
  distance = distance, replace_doubles = replace_doubles, keep_short_bins = keep_short_bins, $
  shift_duration = shift_duration, no_attenuation = no_attenuation, sys_uncert = sys_uncert, $
  generate_fits = generate_fits, specfile = specfile, srmfile = srmfile, silent = silent, $
  plot = plot, xspec=xspec, ospex_obj = ospex_obj, tailing=tailing, include_damage=include_damage, _extra=extra

  
  if n_elements(time_shift) eq 0 then begin
    if ~keyword_set(silent) then begin
      message, 'Time shift value is not set. Using default value of 0 [s].', /info
      print, 'File averaged values can be obtained from the FITS file header'
      print, 'using stx_get_header_corrections.pro.'
    endif
    time_shift = 0.
  endif
  
  default, sys_uncert, 0.05
  default, silent, 0
  default, plot, 1
  default, xspec, 0
  default, tailing, 1
  default, include_damage, 1
  
  ;;------------------------------------------------------------

  stx_read_spectrogram_fits_file, fits_path_data, time_shift, primary_header = primary_header, data_str = data_str, data_header = data_header, control_str = control_str, $
    control_header= control_header, energy_str = energy_str, energy_header = energy_header, t_axis = t_axis, energy_shift = energy_shift,  e_axis = e_axis , use_discriminators = 0,$
    replace_doubles = replace_doubles, keep_short_bins = keep_short_bins, shift_duration = shift_duration


  ;; Select indices of the energy bins (among the 32) that are actually present in the pixel data science file
  energy_bin_mask = data_str.energy_bin_mask
  energy_bin_idx  = where(energy_bin_mask eq 1)

  energy_low  = e_axis.LOW
  energy_high = e_axis.HIGH

  energy_min = min(energy_low)
  energy_max = max(energy_high)
 
  if keyword_set(fits_path_bk) then begin

    stx_read_pixel_data_fits_file, fits_path_bk, data_str = data_bkg, t_axis = t_axis_bkg, e_axis = e_axis_bkg, _extra=extra

    if n_elements(t_axis_bkg.DURATION) gt 1 then message, 'The chosen file does not contain a background measurement'

    ;; Check if the spectrogram and the BKG file are recorded with the same ELUT
    elut_filename = stx_date2elut_file(stx_time2any(t_axis.TIME_START[0]))
    elut_filename_bkg = stx_date2elut_file(stx_time2any(t_axis_bkg.TIME_START))
    
    elut_comp = STRCMP(elut_filename, elut_filename_bkg) ;; Compare ELUT tables

    if not elut_comp then $
      message, 'The background file must be recorded when the same ELUT as the science file was uploaded. Please choose a different background file that is closer in time to the science file.'
    

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

  ;;--------- Create spectrogram structure
  
  data_level = 4
  uid = control_str.request_id
  
  ;; Define default file name for spectrum and srm
  default, specfile, 'stx_spectrum_' + strtrim(uid,2) + '.fits'
  if ~keyword_set(srmfile) then $
    srmfile = xspec ? 'stx_srm_' + strtrim(uid,2) + '_XSPEC.fits' : 'stx_srm_' + strtrim(uid,2) + '.fits'
  
  if n_elements(distance) ne 0 then fits_distance = distance

  fits_info_params = stx_fits_info_params( fits_path_data = fits_path_data, data_level = data_level, $
    distance = fits_distance, time_shift = time_shift, fits_path_bk = fits_path_bk, uid = uid, $
    generate_fits = generate_fits, specfile = specfile, srmfile = srmfile, elut_file = elut_filename, silent = silent)

  counts_in = data_str.counts

  dim_counts = counts_in.dim

  n_times = n_elements(dim_counts) gt 1 ? dim_counts[1] : 1

  pixels_used = where(data_str.pixel_masks eq 1)
  detectors_used = where(control_str.detector_masks eq 1)
  

  n_energies = n_elements(energy_bin_idx)

  pixel_mask_used = intarr(12)
  pixel_mask_used[pixels_used] = 1
  n_pixels = total(pixel_mask_used)

  detector_mask_used = intarr(32)
  detector_mask_used[detectors_used] = 1
  n_detectors = total(detector_mask_used)


  counts_in = reform(counts_in,[dim_counts[0], n_times])

  spec_in = counts_in

  counts_spec =  spec_in[energy_bin_idx, *]

  counts_spec =  reform(counts_spec,[n_energies, n_times])

  counts_err = data_str.counts_err[energy_bin_idx,*]

  counts_err =  reform(counts_err,[n_energies, n_times])

  triggers =  reform(data_str.triggers,[1, n_times])

  triggers_err =  reform(data_str.triggers_err,[1, n_times])

  rcr = data_str.rcr

  ;; Create spectrogram structure for live time correction
  
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
  
  
  ;; Live time correction
  livetime_data =  stx_spectrogram_livetime( spectrogram, corrected_counts = counts_spec, corrected_error = counts_spec_error, level = data_level )
  livetime = livetime_data.livetime
  livetime_err = livetime_data.livetime_err
  
  ;;----- BKG subtraction
  
  if keyword_set(fits_path_bk) then begin
  
    counts_bkg       = data_bkg.COUNTS
    counts_error_bkg = data_bkg.COUNTS_ERR
    counts_bkg       = counts_bkg[energy_bin_idx_bkg,*,*]
    counts_error_bkg = counts_error_bkg[energy_bin_idx_bkg,*,*]
  
    live_time_bkg_data = stx_cpd_livetime(data_bkg.TRIGGERS, data_bkg.TRIGGERS_ERR, t_axis_bkg)
    live_time_bkg = live_time_bkg_data.LIVE_TIME_BINS
    live_time_error_bkg = live_time_bkg_data.LIVE_TIME_BINS_ERR
  
    live_time_bkg_rep = transpose(cmreplicate(live_time_bkg, [n_elements(energy_bin_idx),12]), [1,2,0])
    live_time_error_bkg_rep = transpose(cmreplicate(live_time_error_bkg, [n_elements(energy_bin_idx),12]), [1,2,0])
  
    ;; Normalize by livetime
    count_rates_bkg = f_div( counts_bkg, live_time_bkg_rep )
    count_rates_bkg_error = count_rates_bkg * sqrt( f_div( counts_error_bkg, counts_bkg )^2. + f_div( live_time_error_bkg_rep, live_time_bkg_rep )^2. )
  
    ;; Sum over detectors and pixels
    counts_spec_bkg = total(total(count_rates_bkg, 2) ,2)
    counts_spec_bkg_error = sqrt(total(total(count_rates_bkg_error^2., 2) ,2))
  
    if n_times gt 1 then begin
  
      counts_spec_bkg = cmreplicate( counts_spec_bkg, n_times )
      counts_spec_bkg_error = cmreplicate( counts_spec_bkg_error, n_times )
      
    endif
    
    counts_spec = counts_spec - counts_spec_bkg
    counts_spec_error = sqrt(counts_spec_error^2. + counts_spec_bkg_error^2.)
    
  
  endif

  ;;------ Multiply by live time. The units of the spectrogram are counts
  spec = counts_spec * livetime               
  spec_error = abs(spec) * sqrt( f_div(counts_spec_error,counts_spec)^2. + f_div(livetime_err,livetime)^2. ) 
  
  
  livetime_fraction = livetime_data.livetime_fraction
  livetime_fraction_dim = size(livetime_fraction, /dim)
  if n_elements(livetime_fraction_dim) ge 2 then livetime_fraction = reform(livetime_fraction[0,*])
  
  ;; Create spectrogram structure
  spec_data = {type   : 'stx_spectrogram', $
    data              : spec, $
    t_axis            : t_axis, $
    e_axis            : e_axis, $
    ltime             : livetime_fraction, $ 
    attenuator_state  : data_str.RCR , $
    error             : spec_error}

  ;;------------------------------------------------------

  stx_convert_spectrogram2ospex, spec_data, pixel_mask_used, detector_mask_used, fits_info_params, ct_edges, $
    no_attenuation=no_attenuation, flare_location_stx=flare_location_stx, time_shift = time_shift, $
    sys_uncert=sys_uncert, silent=silent, plot=plot, xspec=xspec, ospex_obj = ospex_obj, $
    tailing=tailing, include_damage=include_damage, _extra=extra

end

