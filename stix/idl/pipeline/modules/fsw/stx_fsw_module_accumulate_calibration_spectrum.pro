;+
; :description:
;    Create a new STX_FSW_MODULE_ACCUMULATE_CALIBRATION_SPECTRUM object
;    
; :history:
;    30-Oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;    10-May-2016 - Laszlo I. Etesi (FHNW), updated structure type names
;
; returns the new module
;-
function stx_fsw_module_accumulate_calibration_spectrum
  return , obj_new('stx_fsw_module_accumulate_calibration_spectrum','stx_fsw_module_accumulate_calibration_spectrum', $
  ['stx_sim_detector_eventlist',  'stx_fsw_m_calibration_spectrum'], $
  ['eventlist',                   'previous_calibration_spectrum'                 ])
end
