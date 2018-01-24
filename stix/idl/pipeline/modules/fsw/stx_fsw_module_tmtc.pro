;+
; :DESCRIPTION:
;    Create a new STX_FSW_MODULE_DATA_COMPRESSION object
;
; returns the new module
;-
function stx_fsw_module_tmtc
  return , obj_new('stx_fsw_module_tmtc','stx_fsw_module_tmtc',"ANONYMOUS")
end