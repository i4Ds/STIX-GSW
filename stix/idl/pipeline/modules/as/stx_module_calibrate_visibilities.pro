;+
; :description:
;    Create a new STX_MODULE_CALIBRATE_VISIBILITIES object
;
; returns the new module
;-
function stx_module_calibrate_visibilities
  return , obj_new('stx_module_calibrate_visibilities','stx_module_calibrate_visibilities','stx_visibility_bag'+['','_array'])
end
