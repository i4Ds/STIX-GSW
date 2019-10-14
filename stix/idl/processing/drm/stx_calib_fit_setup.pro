;+
; :Description:
;    Describe the procedure.
;  OSPEX script created Mon Jun 24 09:24:23 2019 by OSPEX writescript method.
;
;  Call this script with the keyword argument, obj=obj to return the
;  OSPEX object reference for use at the command line as well as in the GUI.
;  For example:
;     stx_calib_fit_setup, obj=obj
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
;;
;
;
; :Keywords:
;    obj - spex object instance
;    hi_erange - parameters to fit the line at 81 keV
;
; :Author: rschwartz70@gmail.com, 29-jun-2019
;-
pro stx_calib_fit_setup, obj=obj, hi_erange = hi_erange 

  default, hi_erange, 0
  
  if hi_erange then begin
    obj-> set, spex_erange= [63.296486D, 83.064713D]
    obj-> set, fit_function= 'line_nodrm+stx_line_nodrm'
    obj-> set, fit_comp_params= [719.015, 39.6775, 25.7065, $
      5159.57, 81., 0.692135, 1.90161, 81.00, 0.000, 0.000]
    obj-> set, fit_comp_minima= [0.1000, 10.00, 3.000, $
      1.000, 25.00, 0.1000, 0.01000, 80, 0.000, 0.000]
    obj-> set, fit_comp_maxima= [10000.0, 10.00, 50.00, $
      10000.0, 99.00, 5.000, 99.00, 33.00, 0.000, 0.000]
    obj-> set, fit_comp_free_mask= [1B, 1B, 1B, 1B, 1B, 1B, 1B, 0B, 0B, 0B]
    obj-> set, fit_comp_spectrum= ['', '']
    obj-> set, fit_comp_model= ['', '']

  endif else begin
  obj-> set, spex_erange= [29., 37.941589D]
  obj-> set, fit_function= 'line_nodrm+stx_line_nodrm+stx_line_nodrm'
  ;suppressing tailing at 31 keV to mimic Oliver's fits. There is a pseudo tailing from edge effects
  ;which should be captured by a more complete response matrix
  obj-> set, fit_comp_params= [6026.83, 16.6150, 10.3247, $
    9386.68,   30.85,     0.64,      0.01,   30.850,  0.0, 0.0, $
    1492.65, 35.4737,     0.81,      0.01,   35.0,  0.0, 0.0]
  obj-> set, fit_comp_minima= [0.10, 10.0, 3.0, $
    1.0, 25.0, 0.10, 0.010,   30.0,   0.0, 0.0, $
    1.0, 25.0, 0.10, 0.010,    0.0,   0.0, 0.0]
  obj-> set, fit_comp_maxima= [10.0, 50.0, 50.0, $
    1e5, 99.0, 5.0,   99.0,    33.0,  0.0, 0.0, $
    1e5, 99.0, 5.0,   99.0,    40.0,  0.0, 0.0]
  obj-> set, fit_comp_free_mask= [1B, 1B, 1B, $
    1B, 1B, 1B, 0B, 0B, 0B, 0B, $
    1B, 1B, 1B, 0B, 0B, 0B, 0B]
  obj-> set, fit_comp_spectrum= ['', '', '']
  obj-> set, fit_comp_model= ['', '', '']
  obj-> set, spex_autoplot_bksub= 0
  obj-> set, spex_autoplot_overlay_back= 0
  obj-> set, spex_autoplot_units= 'Counts'
  obj-> set, spex_fitcomp_plot_resid= 0
  endelse
  obj-> set, _extra = _extra
end
