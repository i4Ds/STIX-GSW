;+
; :description:
;    Create a new STX_MODULE_PIXEL_PHASE_CALIBRATION object
;
; returns the new module
;-
function stx_module_pixel_phase_calibration
  return , obj_new('stx_module_pixel_phase_calibration','stx_module_pixel_phase_calibration','stx_pixel_data_correction')
end

