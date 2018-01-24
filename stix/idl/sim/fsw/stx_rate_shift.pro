;+
; :description:
;    This procedure calculates the rate dependent energy shift in a single pixel given the rate in counts/s
;
;
; :params:
;    rate   : in, required, type="Long"
;             the rate in counts/s for the pixel
;
;
; :keywords:
;
;    ad      : in, type="bool [0|1]", default="1"
;              output the energy shift in ad channels rather than keV
;    keV     : in, type="bool [0|1]", default="0"    
;              overrides AD and returns the output in keV      
;
;    maxrate : in, optional, type = "float"
;              The count rate at which the energy shift is at the maximum value of 1 keV
;              above this it plateaus at the constant value of 1 keV
;
; :returns:
; 
;     eshift - the energy shift either in keV or number of ad channels
;
; :examples:
;    eshift = stx_rate_shift( 1000L, /ad , maxrate = 2000)
;
; :history:
;    10-Oct-2017 - ECMD (Graz), initial release
;    10-Oct-2017 - rschwartz70@gmail.com - added KEV
;
;-
function stx_rate_shift, rate, ad = ad, kev = kev, maxrate = maxrate
  default, maxrate,  3000.
  default, ad,  1
  default, kev, 0
  
  ;the current model for the energy shift is linear from 0 to 1 keV up to the maximum rate and then
  ;equal to 1 keV for all rates above that
  eshift  = float(rate)/maxrate < 1.0
  
  ; if the ad channel keyword is set then convert the shift in keV
  ; to as shift in ad channel - currently assuming a gain 0.1 for all
  ; pixels
  if ~keV then if keyword_set(ad) then eshift = uint(eshift*10.)
  
  return, eshift
end
