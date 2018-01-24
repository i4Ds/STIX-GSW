;+
; :description:
;    Create a new STX_MODULE_SUM_OVER_PIXELS object
;
; returns the new module
;-
function stx_module_sum_over_pixels
  return, obj_new('stx_module_sum_over_pixels','stx_module_sum_over_pixels','stx_pixel_data'+['','_array'])
end