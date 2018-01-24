;+
; :description:
;    Create a new STX_FSW_MODULE_AD_TEMPERATURE_CORRECTION object
;
; returns the new module
;-
function stx_fsw_module_ad_temperature_correction
  return , obj_new('stx_fsw_module_ad_temperature_correction','stx_fsw_module_ad_temperature_correction','stx_sim_detector_eventlist')
end
