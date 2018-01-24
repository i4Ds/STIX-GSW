;+
; :description:
;    Create a new STX_MODULE_INTERVAL_SELECTION object
;
; returns the new module
;-
function stx_module_interval_selection
  return , obj_new('stx_module_interval_selection','stx_module_interval_selection','stx_raw_pixel_data' + ['','_array'])
end
