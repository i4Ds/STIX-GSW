;+
; :Description:
;    This function returns the ADC1024 channel number for each pixel-det combination for each energy (keV) input.
;    
;
; :Params:
;    energy - a vector of energies from 3-200 keV. Range isn't checked
; :Examples:
;  IDL> energy = [30, 34, 79, 83.]
;  IDL> out = stx_energy2calchan(  energy)
;  IDL> help, out
;  OUT             FLOAT     = Array[4, 12, 32]

; :Keywords:
;    gain - if provided, must have 384 elements and the offset input must also be provided
;    this is the keV/chan for the 1024 channel ADC
;    offset- if provided, must have 384 elements and the gain input must also be provided
;    ADC1024 channel at 0 keV
;
; :Author: raschwar
;    22-Apr-2020 - ECMD (Graz), added elut_filename keyword 
; 
;-
function stx_energy2calchan, energy, gain = gain, offset = offset, elut_filename = elut_filename

  if total(abs([n_elements( gain ), n_elements(offset)] -[384,384])) ne 0 then $
    stx_read_elut, gain, offset, elut_filename = elut_filename
    sz = size( energy, /dim)
    result = fltarr( [product(sz), 384] )
    for i=0,383 do result[ 0, i] = energy / gain[i] + offset[i]
    result = reform(/over, result, [sz, 12, 32] )


  return, result
end
