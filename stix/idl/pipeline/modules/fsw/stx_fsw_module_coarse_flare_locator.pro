;+
; :description:
;    Create a new STX_FSW_MODULE_COARSE_FLARE_LOCATOR object
;    
; :history:
;    10-May-2016 - Laszlo I. Etesi (FHNW), updated structure type names
;
; returns the new module
;-
function stx_fsw_module_coarse_flare_locator
  return , obj_new('stx_fsw_module_coarse_flare_locator','stx_fsw_module_coarse_flare_locator', $
                    ['stx_fsw_m_background', 'stx_fsw_ql_flare_location_1',  'stx_fsw_ql_flare_location_2'], $
                    ['background',             'ql_cfl1_acc',                  'ql_cfl2_acc'])
end
