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
;  Created: 03-may-2018, rschwartz70@gmail.com
;-
pro stx_cal_script, obj=obj, quiet = quiet, _extra = _extra
  if not is_class(obj,'SPEX',/quiet) then obj = ospex()

  obj-> set, spex_source_xy= [0.000000, 0.000000]
  obj-> set, spex_erange= [[22.8, 45.2], [73.2, 88.8]]
  obj-> set, fit_function= 'line_nodrm+line_nodrm+line_nodrm+line_nodrm+line_nodrm'
  obj-> set, fit_comp_params= fit_comp_params
  
  obj-> set, fit_comp_minima= fit_comp_minima
  obj-> set, fit_comp_maxima= fit_comp_maxima
  obj-> set, fit_comp_free_mask= fit_comp_free_mask
  obj-> set, fit_comp_spectrum= ['', '', '', '', '']
  obj-> set, fit_comp_model= ['', '', '', '', '']
  obj-> set, spex_autoplot_bksub= 0
  obj-> set, spex_autoplot_overlay_back= 0
  obj-> set, spex_autoplot_units= 'Flux'
  
  obj->set, spex_fit_manual=0, spex_autoplot_enable=0, spex_fitcomp_plot_resid=0, spex_fit_progbar=0
  obj->set, _extra = _extra ;change any of the previously set controls  through this
  default, quiet, 1
  obj->dofit, /all, quiet = quiet
end
