;+
;+
; Name: STX_RCR_AREA
;
; Purpose: This function returns the nominal pixel areas for the STIX
; rate control regimes
; Input: 
;   RCR - pixel area for each RCR (specified 0 to 7 ), all in cm2
;     1. Attenuator out, all pixels, 0.8096, starts at 1
;     2. Attenuator in, all pixels, 0.8096
;     3. Half pixels (0.4048)
;     4, 5, 6, 7, 8 - 0.2024,  0.1012  0.0396,  0.0198,  0.0099
;  These values are based on small pixel size of 1.1 x 0.9 mm and full active area of 8.8 x 9.2 mm Input: 
; History:
;   richard.schwartz@nasa.gov 1-dec-2014
;   4-dec-2014, richard.schwartz@nasa.gov, rcr's run 0 to 7 and not 1-8
;-
function stx_rcr_area, rcr, all = all 
states = [0.8096, 0.80961, 0.4048,  0.2024,  0.1012, 0.0396,  0.0198,  0.0099]  ;in cm2

;first state no attenuator, all pixels
;second state all pixels with attenuator
;then down the pixel ladder
default, rcr, 0
if keyword_set( all ) then rcr = indgen( 8 )
rcr >= 0 <7
out = states[ rcr  ]
return, out
end