;+
; :description:
;    Create a new STX_MODULE_CREATE_VISIBILITIES object
;
; returns the new module
;-
function stx_module_create_visibilities
  return , obj_new('stx_module_create_visibilities','stx_module_create_visibilities','stx_pixel_data_summed'+['','_array'])
end
