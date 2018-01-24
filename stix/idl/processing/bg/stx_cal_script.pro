;+
; OSPEX script created Wed Nov 29 16:52:57 2017 by OSPEX writescript method.
;
;  Call this script with the keyword argument, obj=obj to return the
;  OSPEX object reference for use at the command line as well as in the GUI.
;  For example:
;     ospex_script_29_nov_2017, obj=obj
;
;  Note that this script simply sets parameters in the OSPEX object as they
;  were when you wrote the script, and optionally restores fit results.
;  To make OSPEX do anything in this script, you need to add some action commands.
;  For instance, the command
;     obj -> dofit, /all
;  would tell OSPEX to do fits in all your fit time intervals.
;  See the OSPEX methods section in the OSPEX documentation at
;  http://hesperia.gsfc.nasa.gov/ssw/packages/spex/doc/ospex_explanation.htm
;  for a complete list of methods and their arguments.
;  5-dec-2017, RAS, fixed edited object name from o to obj in lines at bottom
;-
pro stx_cal_script, obj=obj, _extra = _extra
  if not is_class(obj,'SPEX',/quiet) then obj = ospex()
  obj-> set, spex_specfile= '.\Cal_bkg_dev.fits'
  obj-> set, spex_drmfile= '.\Cal_bkg_dev_drm.fits'
  obj-> set, spex_source_xy= [0.000000, 0.000000]
  obj-> set, spex_erange= [[22.799999D, 45.200001D], [73.199997D, 88.800003D]]
  obj-> set, fit_function= 'line_nodrm+line_nodrm+line_nodrm+line_nodrm+line_nodrm'
  obj-> set, fit_comp_params= [0.971807, 29.8638, 16.2872, 0.114519, 30.8512, 0.727227, $
    0.0215271, 35.1231, 0.777957, 0.0407576, 80.9584, 1.05361, 0.606173, 68.7680, 24.2684]
  obj-> set, fit_comp_minima= [0.100000, 28.0000, 3.00000, 0.0100000, 30.0000, 0.0100000, $
    0.00500000, 32.0000, 0.500000, 0.00500000, 77.0000, 0.500000, 0.200000, 64.0000, $
    0.0100000]
  obj-> set, fit_comp_maxima= [5.00000, 37.0000, 30.0000, 5.00000, 33.0000, 3.00000, 5.00000, $
    36.0000, 3.00000, 1.00000, 82.0000, 2.00000, 10.0000, 70.0000, 40.0000]
  obj-> set, fit_comp_free_mask= [1B, 1B, 1B, 1B, 1B, 1B, 1B, 1B, 1B, 1B, 1B, 1B, 1B, 1B, $
    1B]
  obj-> set, fit_comp_spectrum= ['', '', '', '', '']
  obj-> set, fit_comp_model= ['', '', '', '', '']
  obj-> set, spex_autoplot_bksub= 0
  obj-> set, spex_autoplot_overlay_back= 0
  obj-> set, spex_autoplot_units= 'Flux'
  obj-> set, spex_eband= [[3.00000, 6.00000], [6.00000, 12.0000], [12.0000, 25.0000], $
    [25.0000, 50.0000], [50.0000, 100.000], [100.000, 300.000]]
  obj-> set, spex_tband= [' 1-Jan-2019 00:00:00.000', ' 2-Jan-2019 00:00:00.000']

  set_logenv, 'OSPEX_NOINTERACTIVE', '1'
  obj->set, spex_fit_manual=0, spex_autoplot_enable=0, spex_fitcomp_plot_resid=0, spex_fit_progbar=0
  obj->set, _extra = _extra ;change any of the previously set controls  through this
  obj->dofit, /all
end
