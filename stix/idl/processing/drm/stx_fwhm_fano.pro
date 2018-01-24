;+
; :Description:
;    STX_FWHM_FANO - Returns the fwhm resolution vs energy from Fano noise, electron-hole to phonon process
;    e is the energy in keV
;    w = 0.0044 ;ev per electron hole pair
;    f = 0.1 ; Fano factor;
;    fano_fwhm =  sqrt( e / f / w ) / 1000.0 ;returns answer in keV 

; :Params:
;    e - Energy in keV, a vector,  normal range 3-200.0 keV
;    
;
;
;
; :Author: richard.schwartz@nasa.gov
; :Date:  9-mar-2015
;-
function stx_fwhm_fano, e
w = 0.0044 ;ev per electron hole pair
f = 0.1 ; Fano factor
return, sqrt( e / f / w ) / 1000.0 ;returns answer in keV 
end