;+
; :description:
;    create a new stx_fsw_module_rate_control_regime object
;    
; :history:
;    10-May-2016 - Laszlo I. Etesi (FHNW), updated structure type names
;
; returns the new module
;-
function stx_fsw_module_rate_control_regime
  return , obj_new('stx_fsw_module_rate_control_regime','stx_fsw_module_rate_control_regime', $
                  ['stx_fsw_m_rate_control_regime', 'stx_fsw_ql_bkgd_monitor_lt', 'stx_fsw_ql_quicklook_lt'], $
                  ['rcr',                         'live_time_bkgd',             'live_time'])
                  ; TODO: make sure live_time_bkgd is replaced with counts_bkgd
end
