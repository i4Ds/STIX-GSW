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
;
;-
function stx_fsw_sd_spectrogram2ospex, spectrogram, specpar = specpar, fits = fits, plotman_obj = pobj, specfilename = specfilename, srmfilename  = srmfilename

  ;convert the triggers to livetime
  ;NB currently issues with trigger format so fractional livetime of 1.0 for all intervals set
  trig = (fltarr(16)+1./16.)##spectrogram.trigger
  triggergram = stx_triggergram(transpose(trig),  spectrogram.time_axis)
  livetime_fraction = stx_livetime_fraction(triggergram)
  ntimes = n_elements(spectrogram.time_axis.time_start)

  ;get the energy edges for building the drm from the spectrogram
  ct_edges = spectrogram.energy_axis.edges_1
  maxct = max( ct_edges )
  ph_edges = [ ct_edges, maxct + maxct*(findgen(10)+1)/10. ]

  ;as the drm expects an array [32, 12] pixel mask replicate the passed pixel mask for each detector
  pixel_mask = (fltarr(32)+1)##(spectrogram.pixel_mask)[*,0]

  ;make the srm for the appropriate pixel mask and energy edges
  srm = stx_build_pixel_drm(ct_edges, ph_energy_edges = ph_edges)


  rcr_states = specpar.sp_atten_state.state
  rcr_states = rcr_states[UNIQ(rcr_states, SORT(rcr_states))]
  nrcr_states = n_elements(rcr_states)

  srm_atten = replicate( {rcr:0,  srm:fltarr(n_elements(ct_edges)-1,n_elements(ph_edges)-1)},nrcr_states )

  for i =0,  nrcr_states-1 do begin
    ;make the srm for the appropriate pixel mask and energy edges
    rcr = rcr_states[i]

    srm = stx_build_pixel_drm(ct_edges, pixel_mask, rcr = rcr, ph_energy_edges = ph_edges,  d_al = 0.06)
    srm_atten[i].srm = srm.smatrix
    srm_atten[i].rcr = rcr

  endfor

  ospex_obj  = ospex()

  ;if the fits keyword is set write the spectrogram and srm data to fits files and then read them in to the ospex object
  if keyword_set(fits) then begin
    utime = transpose(stx_time2any( spectrogram.time_axis.time_start ))
    ; spectrogram.ltime = livetime_fraction*transpose(rebin(spectrogram.t_axis.duration,ntimes,32))
    ;spectrogram structure for passing to fits writer routine
    ;NB currently attenuator state is not passed in so it is set to 0 here
    spectrum_in = { type              : 'stx_spectrogram', $
      data              : spectrogram.counts, $
      t_axis            : spectrogram.time_axis, $
      e_axis            : spectrogram.energy_axis, $
      ltime             : transpose(livetime_fraction), $
      attenuator_state  : 0 }

    default, specfilename, 'stx_spectrum_' + time2file( utime[0] ) + '.fits'
    default, srmfilename, 'stx_srm_' + time2file( utime[0] ) + '.fits'

    stx_write_ospex_fits, spectrum = spectrum_in, srmdata = srm,  specpar = specpar, srm_atten =srm_atten, specfilename = specfilename, srmfilename = srmfilename, ph_edges = ph_edges

    ospex_obj->set, spex_file_reader = 'stx_read'
    ospex_obj->set, spex_specfile = specfilename   ; name of your spectrum file
    ospex_obj->set, spex_drmfile = srmfilename

  endif else begin
    ;if the fits keyword is not set use the spex_user_data strategy to pass in the data directly to the ospex object

    energy_edges = spectrogram.energy_axis.edges_2
    Edge_Products, ph_edges, edges_2 = ph_edges2

    utime2 = transpose(stx_time2any( [[spectrogram.time_axis.time_start], [spectrogram.time_axis.time_end]] ))

    ospex_obj->set, spex_data_source = 'spex_user_data'
    ospex_obj->set, spectrum = float(spectrogram.counts),  $
      spex_ct_edges = energy_edges, $
      spex_ut_edges = utime2, $
      livetime = livetime_seconds
    ospex_obj->set, spex_respinfo = srm.smatrix
    ospex_obj->set, spex_area = srm.area
    ospex_obj->set, spex_detectors = 'STIX'
    ospex_obj->set, spex_drm_ph_edges = ph_edges2

  endelse

  ;plot the spectrogram data
  ospex_obj-> plotman, class='spex_data', /pl_spec, spex_units='flux', colortable=3, /log_scale, $
    yrange=[ ct_edges[0], ct_edges[-1] ], /yst, plotman_obj=pobj

  return, ospex_obj
end

