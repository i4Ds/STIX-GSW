;+
; :DESCRIPTION:
;   this functions generates a mask (33bit value) from the energy_axis
;;
; :CATEGORIES:
;   simulation, writer, telemetry, energy_axis
;
; :PARAMS:
;   energy_axis : in, required, type="stx_energy_axis"
;     the energy_axis parameter
;
; :HISTORY:
;    08-Nov-2015 - Simon Marcin (FHNW), initial release
;-
function stx_energy_axis_to_mask, energy_axis

  ; define mask
  energy_bin_mask = BYTARR(33)
  n_bins = n_elements(energy_axis.LOW_FSW_IDX)
  
  ; tag energy ranges
  energy_bin_mask[[energy_axis.LOW_FSW_IDX]]=1b
  energy_bin_mask[energy_axis.HIGH_FSW_IDX[n_bins-1]+1]=1b
  return, energy_bin_mask
end
