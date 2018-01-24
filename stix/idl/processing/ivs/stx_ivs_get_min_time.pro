;---------------------------------------------------------------------------
; Document name: stx_ivs_get_min_time.pro
; Created by:    Nicky Hochmuth, 2013/07/26
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; PURPOSE:
;       Use the value of FMt as an index to a TC-specified lookup table to determine thermal
;       divisibility parameters, Tt. These correspond to the minimum time durations an imaging intervall should have
;       Do the same thing (using a different TC-specified LUT) referenced by FMnt to determine corresponding
;       parameter, Tnt for use with non-thermal energy intervals
;
; CATEGORY:
;       Stix on Bord Algorithm
;
; CALLING SEQUENCE:
;       t = stx_ivs_get_min_time(flare_magnitude_index,thermal=1)
;
; HISTORY:
;       2013/07/26, Nicky.Hochmuth@fhnw.ch, initial release
;       2014/03/26  Nicky Hochmuth: get default lut from keywords       
;-
;+
; :description:
;       Use the value of FMt as an index to a TC-specified lookup table to determine thermal
;       divisibility parameters, Tt. These correspond to the minimum time durations an imaging intervall should have
;       Do the same thing (using a different TC-specified LUT) referenced by FMnt to determine corresponding
;       parameter, Tnt for use with non-thermal energy intervals
;            
; :params:
;    the flare magnitude index for the flare
;
; :keywords:
;    thermal: optional, in, type="byte flag" value="[0|1]" 
; :returns:
;     the minimum time for a imaging interval in the concerning energy band (thermal/nonthermal)
;-
function stx_ivs_get_min_time, flare_magnitude_index, thermal,  thermal_min_time_lut=thermal_min_time_lut, nonthermal_min_time_lut = nonthermal_min_time_lut
  default, thermal, 1
  
  default, thermal_min_time_lut,    0.1+((findgen(24)+1)^2)/150
  default, nonthermal_min_time_lut, 0.1+((findgen(24)+1)^2)/400
  
  flare_magnitude_index = flare_magnitude_index > 0 < 23  
  
  return, thermal ?   thermal_min_time_lut[flare_magnitude_index] : nonthermal_min_time_lut[flare_magnitude_index]
end