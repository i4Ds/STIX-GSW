;+
; :Description:
;    STX_FWHM - Returns the fwhm resolution vs energy. Returns value in keV
;
; :Params:
;    e - Energy in keV, a vector,  normal range 3-200.0 keV
;    par - default, 1.0, scalar, electronic noise component of overall resolution broadening, excludes Hall tailing
;
;
;
; :Author: richard.schwartz@nasa.gov
; :Date: documented and revised 9-mar-2015
;-
function stx_fwhm, e, par
;if n_elements(par) eq 3 then par2 = par[2]
default, par, 1.0
return, sqrt( par[0]^2 + stx_fwhm_fano( e )^2 ) 
end