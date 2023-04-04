;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_energy_edge2bin_mask
;
; :description:
;    This function converts a 33 element energy bin edge mask to the previously 
;    standard 32 element energy bin mask
;
; :params:
;    energy_bin_edge_mask : in, required, type="array"
;             33 element mask where 1 indicates that the data was accumulated from
;             this energy edge 
;
; :returns:
;    energy_bin_mask 
;             32 element mask where 1 indicates that the data from this energy bin 
;             was included
;             
; :examples:
;      energy_bin_mask = stx_energy_edge2bin_mask(control.energy_bin_edge_mask)
;
; :history:
;    04-Apr-2023 - ECMD (Graz), initial release
;
;-
function stx_energy_edge2bin_mask, energy_bin_edge_mask

energy_bin_mask = (energy_bin_edge_mask and shift(energy_bin_edge_mask,1))[1:-1]
energy_bin_mask[min(where(energy_bin_mask eq 1)): max(where(energy_bin_mask eq 1))] = 1

return, energy_bin_mask
end
