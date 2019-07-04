;+
; NAME:
;	F_STX_LINE_NODRM_DEFAULTS
;
; PURPOSE: Function to return default values for
;   parameters, minimum and maximum range, and free parameter mask when
;   fitting to F_STX_LINE_NODRM function.
;   
;
; CALLING SEQUENCE: defaults = f_stx_line_nodrm_defaults()
;
; INPUTS:
;	None
; OUTPUTS:
;	Structure containing default values
;
; MODIFICATION HISTORY:
; Richard Schwartz, 24-jun-2019
;
;-
;------------------------------------------------------------------------------

FUNCTION F_STX_LINE_NODRM_DEFAULTS
  ;             A set of parameters describing the line and tailing
  ;             p[0] : Normalization
  ;             p[1] : line center energy in default units, normally keV
  ;             p[2] : gaussian line width before tailing in sigma
  ;             p[3] : mfp_divisor, default is 1. Increase mfp_divisor to increase trapping and reduce mean free path
  ;             p[4] : known line energy. Used to computer tailing. may be different from p[1], set to 0 to use p[1]
  ;             p[5] : mean free path for holes in cm, for default of  0.36 set to 0,
  ;             p[6] : mean free path for electrons in cm, for default of 24 set to 0

defaults = { $
  fit_comp_params:           [1., 31.,  1.0, 1., 31.0,  0.0, 0.0 ], $
  fit_comp_minima:           [1., 25.,  0.1, 31.,   .01, 0.0, 0.0 ], $
  fit_comp_maxima:           [1., 99.,  5.0, 99.,    10., 0.0, 0.0 ], $
  fit_comp_free_mask:        [1,  1, 00,   1,   0,    0,   0   ] $
}

RETURN, defaults
END
