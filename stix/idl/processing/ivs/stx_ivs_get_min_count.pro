;---------------------------------------------------------------------------
; Document name: stx_ivs_get_min_count.pro
; Created by:    Nicky Hochmuth, 2013/07/25
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; PURPOSE:
;       Use the value of FMt as an index to a TC-specified lookup table to determine thermal
;       divisibility parameters, N1t and N2t. These correspond to the minimum number of counts
;       in a time/energy block to support its division into 1 or more than 1 image. (N2t > 2x N1t).
;       These will be used for for analysis of thermal energy intervals. Do the same thing (using
;       a different TC-specified LUT) referenced by FMnt to determine corresponding
;       parameters, N1nt and N2nt for use with non-thermal energy intervals
;
; CATEGORY:
;       Stix on Bord Algorithm
;
; CALLING SEQUENCE:
;       min_count = stx_ivs_get_min_count(flare_magnitude_index,1)
;
; HISTORY:
;       2013/07/24, Nicky.Hochmuth@fhnw.ch, initial release
;       2014/03/21 Nicky Hochmuth: get default lut from keywords
;       
;-
;+
; :description:
;       Use the value of FMt as an index to a TC-specified lookup table to determine thermal
;       divisibility parameters, N1t and N2t. These correspond to the minimum number of counts
;       in a time/energy block to support its division into 1 or more than 1 image. (N2t > 2x N1t).
;       These will be used for for analysis of thermal energy intervals. Do the same thing (using
;       a different TC-specified LUT) referenced by FMnt to determine corresponding
;       parameters, N1nt and N2nt for use with non-thermal energy intervals
;       
; :params:
;    flare_magnitude_index:   in, required, type=byte
;                             the flare magnitude index for the flare
;     
;    thermal:                 optional, in, type="byte flag" value="[0|1]"
;                             
;     
; :keywords:
;    
;    thermal_min_count_lut: optional, in, type="int(2,24)" 
;                           N1t and N2t for each flare magnitude index in the thermal band
;    
;    nonthermal_min_count_lut:  optional, in, type="int(2,24)"
;                               N1nt and N2nt for each flare magnitude index in the nonthermal band
;                               
; :returns:
;     the minimum counts for a good interval and the minimum count to further split an intervall [N1,N2]
;-
function stx_ivs_get_min_count, flare_magnitude_index, thermal, thermal_min_count_lut = thermal_min_count_lut, nonthermal_min_count_lut = nonthermal_min_count_lut
  default, thermal, 0
  
  default, thermal_min_count_lut,     fix([transpose(1000+(indgen(24)+1)^2.6),transpose(1000+(indgen(24)+1)^2.6 * (2+findgen(24)/23.0))]) 
  default, nonthermal_min_count_lut,  fix([transpose( 800+(indgen(24)+1)^2.2),transpose( 800+(indgen(24)+1)^2.2 * (2+findgen(24)/23.0))])  
  
  flare_magnitude_index = flare_magnitude_index > 0 < 23  
  
  return, thermal ? thermal_min_count_lut[*,flare_magnitude_index] : nonthermal_min_count_lut[*,flare_magnitude_index]
end