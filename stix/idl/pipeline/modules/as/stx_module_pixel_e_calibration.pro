;+
; :description:
;    Create a new STX_MODULE_PIXEL_E_CALIBRATION object
;
; returns the new module
;-
function stx_module_pixel_e_calibration
  return , obj_new('stx_module_pixel_e_calibration','stx_module_pixel_e_calibration','stx_pixel_data_correction')
end
