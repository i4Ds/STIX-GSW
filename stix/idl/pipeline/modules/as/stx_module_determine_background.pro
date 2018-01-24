;+
; :description:
;    Create a new stx_module_determine_background object
;
; returns the new module
;-
function stx_module_determine_background
  return , obj_new('stx_module_determine_background','stx_module_determine_background','stx_pixel_data' + ['','_array'])
end
