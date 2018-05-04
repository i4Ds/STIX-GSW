;+
; :Description:
;    This function gives a baseline model for the STIX on-board calibration x-ray lines
; :Output:
;   returns a set of 6 lines, intensities, line centers (keV), sigma (keV) for use with f_nline the
;   same function used in ospex for fitting line properties
; :Author: rschwartz70@gmail.com, 20-apr-2018
;  3-may-2018, RAS, added documentation
;-
function stx_cal_lines_mdl
  kev35 = transpose( [[0.06, .116, 0.0358], [34.92, 34.987, 35.818],  [1,1,1]  ])
  kev31 = [[  0.35, 30.625, 1.], [0.65, 30.973, 1]]
  kev81 = [.25, 81, 1.5]
  
  default, gauss_line_param, [ kev31[*], kev35[*], kev81[*] ]
  ;parameters are meant to be fwhm and f_line takes the width (3rd param) as sigma
  ;fwhm = sigma * 2.^1.5 *alog( 2)^0.5 
  fwhm = gauss_line_param[2:*:3]
  sigma = fwhm / ( 2.^1.5 *alog( 2)^0.5 )
  gauss_lines = gauss_line_param
  gauss_lines[2:*:3] = sigma

return, gauss_lines
end