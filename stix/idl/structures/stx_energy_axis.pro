;+
; :Description: stx_energy_axis is a enrgy axis structure definition function
; :Params:
;   num_energy - integer type, number of energy bins
;-
function stx_energy_axis, num_energy
default, num_energy, 32
  return, {   $ ; units in keV
        type  : 'stx_energy_axis', $
        mean  : fltarr(num_energy), $
        gmean : fltarr(num_energy), $
        low   : fltarr(num_energy), $
        high  : fltarr(num_energy), $
        low_fsw_idx  : byte(indgen(num_energy)), $ ;original on board science chanel index 0-31
        high_fsw_idx : byte(indgen(num_energy)), $ ;original on board science chanel index 0-31
        edges_1: fltarr( num_energy+1 ), $
        edges_2: fltarr( 2, num_energy), $
        width : fltarr(num_energy) $
     }
end