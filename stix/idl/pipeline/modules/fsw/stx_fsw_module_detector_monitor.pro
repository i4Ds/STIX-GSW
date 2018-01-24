;+
; :description:
;    create a new stx_fsw_module_detector_monitor object
;    
; :history:
;    10-May-2016 - Laszlo I. Etesi (FHNW), updated structure type names
;
; returns the new module
;-
function stx_fsw_module_detector_monitor
  return , obj_new('stx_fsw_module_detector_monitor','stx_fsw_module_detector_monitor', $
    ['stx_fsw_ql_detector_anomaly',  'stx_fsw_ql_detector_anomaly_lt',  'stx_fsw_m_detector_monitor*',            'stx_fsw_m_flare_flag',  'double'], $
    ['ql_counts',               'lt_counts',                  'detector_monitor', 'flare_flag', 'int_time'])
end



