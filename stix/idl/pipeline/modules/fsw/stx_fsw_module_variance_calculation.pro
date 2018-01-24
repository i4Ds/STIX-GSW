;+
; :description:
;    Create a new STX_FSW_MODULE_VARIANCE_CALCULATION object
;    
; :history:
;    10-May-2016 - Laszlo I. Etesi (FHNW), updated structure type names
;
; returns the new module
;-
function stx_fsw_module_variance_calculation
  return , obj_new('stx_fsw_module_variance_calculation','stx_fsw_module_variance_calculation', $
                  ['stx_fsw_ql_variance'], $
                  ['ql_data'] $
  )
end
