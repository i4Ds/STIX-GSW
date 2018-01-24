;+
;  :description:
;    Create a new STX_FSW_MODULE_QL_ACCUMULATION object
;    
;  :history:
;    30-Oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;
; returns the new module
;-
function stx_fsw_module_ql_accumulation
  return , obj_new('stx_fsw_module_ql_accumulation','stx_fsw_module_ql_accumulation', $
          ['stx_sim_calibrated_detector_eventlist', 'stx_sim_event_triggerlist', 'stx_time' ] , $
          ['eventlist'                           , 'triggerlist'             , 'interval_start_time'])
end
