;+
; :DESCRIPTION:
;    Create a new STX_FSW_MODULE_INTERVALSELECTION_SPC object
;
; returns the new module
;-
function stx_fsw_module_intervalselection_spc
  ivs = obj_new('stx_fsw_module_intervalselection_spc','stx_fsw_module_intervalselection_spc', 'stx_fsw_ivs_img_result')

  return, ivs
end

