;+
; :description:
;    Create a new STX_FSW_MODULE_CONVERT_SCIENCE_DATA_CHANNELS object
;
; returns the new module
;-
function stx_fsw_module_convert_science_data_channels
  return , obj_new('stx_fsw_module_convert_science_data_channels','stx_fsw_module_convert_science_data_channels','stx_sim_detector_eventlist')
end
