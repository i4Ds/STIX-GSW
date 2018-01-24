;---------------------------------------------------------------------------
; Document name: stx_ivs_get_thermal_boundary.pro
; Created by:    Nicky Hochmuth, 2013/07/24
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; PURPOSE:
;       Use the flare magnitude index as an index to a 24-element TC-specified lookup table to
;       determine the minimum science channel number to be considered as ‘nonthermal’.
;       Channels below this value are considered 'thermal’.
;
; CATEGORY:
;       Stix on Bord Algorithm
;
; CALLING SEQUENCE:
;       boundary = stx_ivs_get_thermal_boundary(flare_magnitude_index)
;
; HISTORY:
;       2013/07/24, Nicky.Hochmuth@fhnw.ch, initial release
;       2014/03/21 Nicky Hochmuth: get default lut from keywords
;       
;-
;+
; :description:
;     Determine a ‘total flare magnitude index’, FMtot, to be used as an index for determining
;     the division between thermal and non-thermal energies. The flare magnitude index is
;     determined by a set of thresholds for Ntot in a TC-specified table. FMtot may have
;     values from 0 to 23. (This corresponds roughly to steps of x2 in Ntot.)
;       
; :params:
;    the flare magnitude index for the entire flare
; 
; ;keywords:
; thermal_boundary_lut:  optional, in, type="byte(24)" 
;                        index of the thermal boundary of science energy channels for each flare magnitude index
;
; :returns:
;     the index of the native science energy binning
;-
function stx_ivs_get_thermal_boundary, flare_magnitude_index, thermal_boundary_lut=thermal_boundary_lut
  
  default, thermal_boundary_lut, byte([4,5,6,7,8,9,10,12,13,14,15,16,17,17,18,18,18,19,19,19,19,20,20,20])
  
  flare_magnitude_index = flare_magnitude_index > 0 < 23
  
  return, thermal_boundary_lut[flare_magnitude_index]
end