;+
; :description:
;    Create a new STX_FSW_MODULE_FLARE_DETECTION object
;    
; :history:
;    10-May-2016 - Laszlo I. Etesi (FHNW), updated structure type names
;
; returns the new module
;-
function stx_fsw_module_flare_detection
  return , obj_new('stx_fsw_module_flare_detection','stx_fsw_module_flare_detection', $
                  ['stx_fsw_ql_flare_detection',  'long*',      'int',   'byte'], $
                  ['ql_counts',                   'background', 'int_time', 'rcr'])
end
