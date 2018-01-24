;+
; :description:
;    Create a new STX_MODULE_INTERVAL_SELECTION object
;
; returns the new module
;-
function stx_module_sum_over_time_energy
  return , obj_new('stx_module_sum_over_time_energy','stx_module_sum_over_time_energy','stx_pixel_data_intervals')
end
