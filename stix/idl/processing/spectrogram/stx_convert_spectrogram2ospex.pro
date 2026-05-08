;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_convert_spectrogram2ospex
;
; :description:
;    This procedure reads a spectrogram structure (which is created from either a spectrogram file or a compressed pixel data file) and converts it to a spectrogram
;    file which can be read in by OSPEX.
;    
; :categories:
;    spectroscopy
;
; :keywords:
; 
;   spec_data: in, mandatory, type="stx_spectrogram"
;              Spectrogram structure created either by 'stx_convert_pixel_data.pro' or 'stx_convert_spectrogram.pro'
;     
;   pixel_mask_used: in, mandatory, type = "int array"
;              12-element array with entries equal to 1 if the corresponding detector pixels are used (and 0 otherwise)
;   
;   detector_mask_used: in, mandatory, type = "int array"
;              32-element array with entries equal to 1 if the corresponding detector is used (and 0 otherwise)
;   
;   fits_info_params: in, mandatory, type="struct"
;              Structure created by 'stx_fits_info_params.pro'
;              
;   ct_edges: in, mandatory, type="float array"
;             Energy edges of the count energy bins of the spectrogram
;   
;   no_attenuation: in, optional, type="bool"
;             If set, avoid attenuation of the fitted curve. This is useful for obtaining thermal fit parameters with the BKG detector (temporary fix by Andrea)
;   
;   flare_location_stx : in, optional, type="2 element float array"
;               the location of the flare (X,Y) in the STIX imaging frame [arcsec]. Default, [0.,0.]. It is used to compute the grid transmission
;   
;   time_shift : in, optional, type="float", default="0."
;               The difference in seconds in light travel time between the Sun and Earth and the Sun and Solar Orbiter
;               i.e. Time(Sun to Earth) - Time(Sun to S/C)
;   
;   sys_uncert : in, type="float", default="0.05"
;                The fractional systematic uncertainty to be added
;                
;   silent : in, type="int", default="0"
;            If set prevents informational messages being displayed.
;   
;   plot : in, type="boolean", default="1"
;          If set open OSPEX GUI and plot lightcurve in standard quicklook energy bands where there is data present
;          
;   xspec : in, type="boolean", default="0"
;                     If set, generate SRM file compatible with XSPEC rather than OSPEX.
;
;   ospex_obj : out, type="OSPEX object"
   
;
; :history: 07-May-2026 - Massa P. (FHNW), created
;
;-

pro stx_convert_spectrogram2ospex, spec_data, pixel_mask_used, detector_mask_used, fits_info_params, ct_edges, $
                                   no_attenuation=no_attenuation, flare_location_stx=flare_location_stx, time_shift = time_shift, $
                                   sys_uncert=sys_uncert, silent=silent, plot=plot, xspec=xspec, ospex_obj = ospex_obj, $
                                   tailing=tailing, include_damage=include_damage, _extra=extra

  default, no_attenuation, 0
  default, sys_uncert, 0.05
  
  if n_elements(time_shift) eq 0 then begin
    if ~keyword_set(silent) then begin
      message, 'Time shift value not set, using default value of 0 [s].', /info
      print, 'File averaged values can be obtained from the FITS file header'
      print, 'using stx_get_header_corrections.pro.'
    endif
    time_shift = 0.
  endif

  ;;****************** Define parameters

  ut_rcr = stx_time2any(spec_data.t_axis.time_start)
  rcr = spec_data.attenuator_state
  spec = spec_data.data
  
  detectors_used = where(detector_mask_used eq 1, n_det)
  pixels_used = where(pixel_mask_used eq 1, n_pix)

  ;; Print warning if fine-resolution sub-collimators are considered
  subc_fine_label = ['1a','1b','1c','2a','2b','2c']
  subc_fine_index = stx_label2ind(subc_fine_label)
  subc_fine_used = detector_mask_used[subc_fine_index]
  
  idx = where(subc_fine_used eq 1b, n_det)
  
  if n_det gt 0 then message, [" ", " ", "The high-energy calibration of sub-collimator " + subc_fine_label[idx] + " is not completed yet. This could affect the spectral fit results.", " ", " "], /continue
  
  ;;***************** CHECK FOR RCR CHANGES
  
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
  if not keyword_set(flare_location_stx) then begin
    flare_location_stx = [0.,0.]
    use_flare_xyoffset = 0
  endif else begin
    use_flare_xyoffset = 1
  endelse

  specpar = { sp_atten_state :  {time:ut_rcr[index], state:state}, flare_xyoffset : flare_location_stx, use_flare_xyoffset:use_flare_xyoffset }
  
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
  
    srm = stx_build_pixel_drm(ct_edges, pixel_mask, rcr = rcr, grid_factor= grid_factor, ph_energy_edges = ph_edges, dist_factor = dist_factor, tailing = tailing, include_damage = include_damage, xspec=xspec, _extra=extra)
    srm_atten[i].srm = srm.smatrix
    srm_atten[i].rcr = rcr
  
  endfor
  
  ;;***************** SAVE FITS
  detector_label = stx_det_mask2label(detector_mask_used)
  pixel_label = stx_pix_mask2label(pixel_mask_used)
  
  ospex_obj  = ospex(/no)
  
  ;if the fits keyword is set write the spectrogram and srm data to fits files and then read them in to the ospex object
  if fits_info_params.generate_fits eq 1 then begin
    
    utime = transpose([stx_time2any( spec_data.t_axis.time_start )])
  
    specfilename = fits_info_params.specfile
    srmfilename =  fits_info_params.srmfile
  
    fits_info_params.grid_factor.add, grid_factor
    fits_info_params.detused = detector_label + ', Pixels: ' + pixel_label
  
    if keyword_set(xspec) then begin
      ;xspec in general works with energy depandent systematic errors
      e_axis = spec_data.e_axis
      n_energies = n_elements(e_axis.mean)
      sys_err  = fltarr(n_energies)
      
      n_times = n_elements(spec_data.t_axis.time_start)
  
      idx_below10kev = where(e_axis.mean lt 10, cb10)
      sys_err[*] = 0.03
      if cb10 gt 0 then sys_err[idx_below10kev] = 0.05
      idx_below7kev = where(e_axis.mean lt 7, cb7)
      if cb7 gt 0 then sys_err[idx_below7kev] = 0.07
  
      sys_err = rebin(sys_err, n_energies,n_times)
    endif
  
    stx_write_ospex_fits, spectrum = spec_data, srmdata = srm, specpar = specpar, time_shift = time_shift, $
      srm_atten = srm_atten, specfilename = specfilename, srmfilename = srmfilename, ph_edges = ph_edges, $
      fits_info_params = fits_info_params, xspec = xspec, silent = silent
  
    ospex_obj->set, spex_file_reader = 'stx_read_sp'
    ospex_obj->set, spex_specfile = specfilename   ; name of your spectrum file
    ospex_obj->set, spex_drmfile = srmfilename
  
  endif else begin
    ;if the generate_fits keyword is not set use the spex_user_data strategy to pass in the data directly to the ospex object
    e_axis = spec_data.e_axis
    t_axis = spec_data.t_axis
    
    energy_edges = e_axis.edges_2
    Edge_Products, ph_edges, edges_2 = ph_edges2
  
    utime2 = transpose(stx_time2any( [[t_axis.time_start], [t_axis.time_end]] ))
  
    livetime_frac = spec_data.LTIME
    nchan = n_elements( ct_edges ) - 1
    duration = spec_data.t_axis.duration
    nrows = n_elements(duration)
    duration_array=rebin(duration, nrows, nchan)
    livetime_frac_array = rebin([livetime_frac], nrows, nchan)
    data=f_div(float(spec),transpose(duration_array*livetime_frac_array))
    data_error = f_div(spec_data.ERROR,transpose(duration_array*livetime_frac_array))
    
    ospex_obj->set, spex_data_source = 'spex_user_data'
    ospex_obj->set, spectrum = data,  $
      spex_ct_edges = energy_edges, $
      spex_ut_edges = utime2, $
      livetime = spec_data.LTIME * spec_data.t_axis.duration, $ 
      errors = data_error
    
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



 