;+
; :Description:
;    ADC1024 calibration spectra are passed to the OSPEX object for fitting using energy edges
;    derived from the previous calibration assumed close enough that the default fitting ranges
;    should still contain the lines at 30.85, 35, and 81 keV. Only 1 of 384 pixel/det spectra
;    are analyzed in each pass but the object is kept open for use on the next spectrum coming
;    from the calling program
;
; :Params:
;    spectra - lonarr(1024, 12, 32)
;    offset_nom - fltarr(12,32) initial ADC1024 offset ~300
;    gain_nom - fltarr(12,32) initial ADC1024 gain ~0.4
;
; :Keywords:
;    ip - pixel, int, 0-11
;    id - detector id, int,0-31
;    summlo - fitted parameters and sigmas for 31,35 keV line range
;    summhi - fitted parameters and sigmas for 81 keV line range
;    obj - SPEX object, used for fitting and plotting if needed
;    auto - default 1, fit automatically w/o cli/gui intervention
;    no_gui - default 1, use OSPEX without GUI
;    _extra - additional parameters to pass to OSPEX
;
; :Author: rschwartz70@gmail.com, 28-jun-2019.
;-
pro stx_calib_fit_single, spectra, offset_nom, gain_nom, ip=ip, id = id, summlo= summlo, summhi=summhi, dohi = dohi, $
  obj = obj, auto = auto, $
  no_gui = no_gui, $
  _extra = _extra

  default, auto, 1 ;if set, noninteractive
  default, no_gui, 1
  if not is_class(obj,'SPEX',/quiet) then obj = ospex(no_gui = no_gui)
  spec = n_dimensions( spectra ) eq 3 ? spectra : total( spectra, 4)
  spec = spectra[250:600, ip, id]
  medg2 = get_edges( findgen(352)+250., /edges_2)
  ;scale into energy units
  gainx = gain_nom[ ip, id]
  offsetx = offset_nom[ ip, id]
  eedg2 = (medg2 - offsetx) * gainx
  default, dohi, 0 ;if set skip to 81 keV range and skip 31 keV range

  if ~dohi then begin
    stx_calib_fit_setup, obj = obj
    obj->set, spex_data_source = 'spex_user_data',spectrum = spec, spex_ct_edges = eedg2, spex_drm_ct_edges = eedg2
    ;Or, if you don't want to interact with the xfit_comp widget, and don't want to see plots or the progress bar, change the last two lines to this:
    if keyword_set( auto ) then begin
      set_logenv, 'OSPEX_NOINTERACTIVE', '1'
      obj->set, spex_fit_manual = 0, spex_autoplot_enable = 0, spex_fitcomp_plot_resid = 0, spex_fit_progbar = 0
      obj->set, _extra = _extra
      obj->dofit, /all

    endif
    summlo = obj->get(/spex_summ_fit_function, /spex_summ_params, /spex_summ_sigma)
  endif
  stx_calib_fit_setup, obj = obj, /hi_erange
  if keyword_set( auto ) then begin
    set_logenv, 'OSPEX_NOINTERACTIVE', '1'
    obj->set, spex_fit_manual = 0, spex_autoplot_enable = 0, spex_fitcomp_plot_resid = 0, spex_fit_progbar = 0
    obj->set, _extra = _extra
    obj->dofit, /all

  endif
  summhi = obj->get(/spex_summ_fit_function, /spex_summ_params, /spex_summ_sigma)

end
