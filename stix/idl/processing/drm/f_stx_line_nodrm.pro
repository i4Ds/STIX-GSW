;+
; :description:
;    This function returns a calibration source line spectrum including the effects of incomplete charge
;    collection due to radiation damage
;
; :categories:
;    calibration, fitting
;
; :params:
;    edge2 : in, required, type="float array"
;             Input Energy bins in keV, 2xN
;
;    param : in, required, type="float array"
;             A set of parameters describing the line and tailing
;             p[0] : Normalization
;             p[1] : line center energy in default units, normally keV
;             p[2] : gaussian line width before tailing in sigma
;             p[3] : mfp_divisor, default is 1. Increase mfp_divisor to increase trapping and reduce mean free path
;             p[4] : known line energy. Used to computer tailing. may be different from p[1], set to 0 to use p[1]
;             p[5] : mean free path for holes in cm, for default of  0.36 set to 0,
;             p[6] : mean free path for electrons in cm, for default of 24 set to 0
;  :Keywords:
;     do_calc : default is 1, if set, use with drm in (O)SPEX count calculation
; :returns:
;    returns the calibration line spectrum for the input energy vector.
;
; :examples:
;     spectrum = stx_hecht_fit( findgen(100)*0.5+60., [0.36,24.,10000.])
;
; :history:
;    14-Jun-2017 - ECMD (Graz), initial release
;
;-


function f_stx_line_nodrm, edge2, param, do_calc=do_calc, _extra=_extra

  checkvar, do_calc, 0
  return, f_stx_line( edge2, param, do_calc=do_calc, _extra=_extra)
end
