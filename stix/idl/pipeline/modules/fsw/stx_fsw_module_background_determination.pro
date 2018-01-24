;+
; :description:
;    Create a new stx_fsw_module_background_determination object
;    
; :history:
;    10-May-2016 - Laszlo I. Etesi (FHNW), updated structure type names
;
; returns the new module
;-
function stx_fsw_module_background_determination
  return , obj_new('stx_fsw_module_background_determination','stx_fsw_module_background_determination',$
            ['stx_fsw_ql_bkgd_monitor',   'stx_fsw_m_background', 'double'],$
            ['ql_bkgd_acc',               'previous_bkgd',        'int_time'])
end
