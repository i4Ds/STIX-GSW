;+
; :description:
;    Create a new STX_MODULE_COARSE_FLARE_LOCATION object
;
; returns the new module
;-
function stx_module_coarse_flare_location
  return , obj_new('stx_module_coarse_flare_location','stx_module_coarse_flare_location','stx_pixel_data'+['','_array'])
end
