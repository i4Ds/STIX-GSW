;+
; :description:
;   This function creates a stx_time_energy_bin_collection a data container for a set of stx_time_energy_bins
;
; :categories:
;    structures
;
; :params:
;    bins   : type="array(stx_time_energy_bin)"
;                   a single or array of stx_time_energy_bins
; :returns:
;    a stx_time_energy_bin_collection
;
; :history:
;     11-oct-2013, Nicky Hochmuth initial  
;-
function stx_time_energy_bin_collection, bins
   return,  obj_new('stx_time_energy_bin_collection', bins)
end