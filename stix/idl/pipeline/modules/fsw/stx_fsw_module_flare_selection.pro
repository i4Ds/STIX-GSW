;+
; :description:
;    Create a new STX_FSW_MODULE_FLARE_SELECTION object
;
; returns the new module
;-
function stx_fsw_module_flare_selection
  return , obj_new('stx_fsw_module_flare_selection','stx_fsw_module_flare_selection', $ 
    ['stx_fsw_m_flare_flag', 'stx_fsw_m_coarse_flare_locator'], $
    ['flare_flag',           'cfl'])
end
