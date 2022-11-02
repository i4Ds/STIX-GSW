;+
;  :description:
;    This procedure takes spectrogram data in flight software telemetry format and passes it to OSPEX
;
;  :categories:
;    STIX, telemetry, ASW
;
;  :params:
;    spectrogram  : in, required, type="stx_fsw_sd_spectrogram structure"
;                   the spectrogram data and associated information from fsw science data telemetry
;
;  :keywords:
;    fits         : in, if set data is written to a fits file which is then passed to OSPEX
;
;    specfilename : in, file name for spectrum fits
;
;    srmfilename  : in, file name for srm fits
;
;    sys_uncert : in, type="float", default="0.05"
;                 The fractional systematic uncertanty to be added
;
;    plotman_obj  : out, if set to a named variable this will pass out the plotman object created when the
;                 spectrogram is plotted
;
;  :returns:
;    ospex object with spectrogram data
;
; :examples:
;    obj = stx_fsw_sd_spectrogram2ospex(fsw_spc, /fits)
;
; :history:
;    22-Nov-2016 - ECMD (Graz), initial release
;
;  :todo:
;    22-Nov-2016 - ECMD (Graz), livetime and attenuator state are not ready so artificially prescribed here
;    03-Dec-2018 – ECMD (Graz), livetime and attenuator states accounted for
;    22-Feb-2022 - ECMD (Graz), added passing of time_shift information to file, default systematic error of 5%
;                               print warning when using on-axis default for background detector
;    29-Jul-2022 - ECMD (Graz), make OSPEX object without opening the GUI
;    08-Aug-2022 - ECMD (Graz), can now pass in file names for the output spectrum and srm FITS files
;                               added keyword to allow the user to specify the systematic uncertainty
;                               pass through structure of info parameters to write in FITS file
;    03-Oct-2022 - ECMD (Graz), replaced stix_gtrans32_test with stx_subc_transmission for calculating the grid transmission 
;                               and made the routine the default option rather than the tabulated on-axis values
;
;-
function stx_fsw_sd_spectrogram2ospex, spectrogram, specpar = specpar, time_shift = time_shift, ph_energy_edges = ph_edges, generate_fits = generate_fits, plotman_obj = pobj, $
  specfilename = specfilename, srmfilename = srmfilename, flare_location = flare_location, gtrans32 = gtrans32, livetime_fraction = livetime_fraction, sys_uncert = sys_uncert, $
  fits_info_params = fits_info_params, xspec = xspec, background_data = background_data, _extra = _extra

  default, sys_uncert, 0.05
  default, gtrans32, 1
  
  ntimes = n_elements(spectrogram.time_axis.time_start)

  ;get the energy edges for building the drm from the spectrogram
  ct_edges = spectrogram.energy_axis.edges_1
  maxct = max( ct_edges )

  default, ph_edges,  [ ct_edges, maxct + maxct*(findgen(10)+1)/10. ]

  ;as the drm expects an array [32, 12] pixel mask replicate the passed pixel mask for each detector
  pixel_mask =(spectrogram.detector_mask)##(spectrogram.pixel_mask)

  grids_used = [where(spectrogram.detector_mask eq 1 , /null)]
  pixels_used = [where(spectrogram.pixel_mask eq 1 , /null)]

  grid_transmission_file =  concat_dir(getenv('STX_GRID'), 'nom_grid_transmission.txt')
  readcol, grid_transmission_file, grid_factors_file, format = 'f', skip = 2
  
  
  if (keyword_set(gtrans32) and n_elements(flare_location) ne 0) then begin
    grid_factors_proc = stx_subc_transmission(flare_location)
    ;05-Oct-2022 - ECMD until fine grid tranmission is ready replace the 
    ;grids not in TOP24 with the on-axis tabulated values
    idx_nontop24 = stx_label2det_ind('bkg+cfl+fine')
    grid_factors_proc[idx_nontop24] = grid_factors_file[idx_nontop24]
    grid_factor  = average(grid_factors_proc[grids_used])
  endif else begin
    print, 'Using nominal (on axis) grid transmission'
    grid_factor = average(grid_factors_file[grids_used])
    specpar.flare_xyoffset = [0.,0.]
  endelse

  if grid_factor eq 0 then begin
    if n_elements(grids_used) eq 1 then if grids_used eq 9 then begin
      print, 'Using nominal (on axis) grid transmission for background detector'
      grid_transmission_file =  concat_dir(getenv('STX_GRID'), 'nom_bkg_grid_transmission.txt')
      readcol, grid_transmission_file, bk_grid_factors, format = 'f', skip = 2
      grid_factor = average(bk_grid_factors[pixels_used])

    endif else begin
      message, 'Warning: Grid Factor is 0 - transmission for CFL and BKG detectors is not implemented',/info

    endelse
  endif

  ;make the srm for the appropriate pixel mask and energy edges
  srm = stx_build_pixel_drm(ct_edges, pixel_mask,  ph_energy_edges = ph_edges, grid_factor = grid_factor, dist_factor = dist_factor,$
    xspec = xspec, _extra = _extra)

  rcr_states = specpar.sp_atten_state.state
  rcr_states = rcr_states[uniq(rcr_states, sort(rcr_states))]
  nrcr_states = n_elements(rcr_states)

  srm_atten = replicate( {rcr:0,  srm:fltarr(n_elements(ct_edges)-1,n_elements(ph_edges)-1)},nrcr_states )

  for i =0,  nrcr_states-1 do begin
    ;make the srm for the appropriate pixel mask and energy edges
    rcr = rcr_states[i]

    srm = stx_build_pixel_drm(ct_edges, pixel_mask, rcr = rcr, ph_energy_edges = ph_edges,  grid_factor = grid_factor,$
      dist_factor = dist_factor, xspec = xspec, _extra = _extra)
    srm_atten[i].srm = srm.smatrix
    srm_atten[i].rcr = rcr

  endfor

  detector_label = stx_det_mask2label(spectrogram.detector_mask)
  pixel_label = stx_pix_mask2label(spectrogram.pixel_mask)

  ospex_obj  = ospex(/no)

  ;if the fits keyword is set write the spectrogram and srm data to fits files and then read them in to the ospex object
  if keyword_set(generate_fits) or fits_info_params.generate_fits eq 1 then begin
    utime = transpose([stx_time2any( spectrogram.time_axis.time_start )])

    ;spectrogram structure for passing to fits writer routine
    spectrum_in = { type              : 'stx_spectrogram', $
      data              : spectrogram.counts, $
      t_axis            : spectrogram.time_axis, $
      e_axis            : spectrogram.energy_axis, $
      ltime             : livetime_fraction, $
      attenuator_state  : spectrogram.rcr , $
      error             : spectrogram.error }

    specfilename = fits_info_params.specfile
    srmfilename =  fits_info_params.srmfile

    fits_info_params.grid_factor = grid_factor
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

      sys_err = rebin(sys_err, n_energies,ntimes)
    endif


    stx_write_ospex_fits, spectrum = spectrum_in, srmdata = srm, specpar = specpar, time_shift = time_shift, $
      srm_atten = srm_atten, specfilename = specfilename, srmfilename = srmfilename, ph_edges = ph_edges, $
      fits_info_params = fits_info_params, xspec = xspec

    ospex_obj->set, spex_file_reader = 'stx_read_sp'
    ospex_obj->set, spex_specfile = specfilename   ; name of your spectrum file
    ospex_obj->set, spex_drmfile = srmfilename

  endif else begin
    ;if the generate_fits keyword is not set use the spex_user_data strategy to pass in the data directly to the ospex object

    energy_edges = spectrogram.energy_axis.edges_2
    Edge_Products, ph_edges, edges_2 = ph_edges2

    utime2 = transpose(stx_time2any( [[spectrogram.time_axis.time_start], [spectrogram.time_axis.time_end]] ))
    livetime = livetime_fraction*(spectrogram.time_axis.duration)
    livetime = transpose(rebin([livetime],n_elements(livetime),n_elements(ct_edges)-1))

    ospex_obj->set, spex_data_source = 'spex_user_data'
    ospex_obj->set, spectrum = float(spectrogram.counts),  $
      spex_ct_edges = energy_edges, $
      spex_ut_edges = utime2, $
      livetime = livetime, $
      errors = spectrogram.error
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

  return, ospex_obj
end

