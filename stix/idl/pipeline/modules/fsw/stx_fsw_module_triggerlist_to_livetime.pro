;+
; :description:
;    Create a new STX_FSW_MODULE_TRIGGERLIST_TO_LIVETIME object
;    
; :history:
;   07-Jul-2015 - Laszlo I. Etesi (FHNW), removed has_leftovers
;
; returns the new module
;-
function stx_fsw_module_triggerlist_to_livetime
  return , obj_new('stx_fsw_module_triggerlist_to_livetime','stx_fsw_module_triggerlist_to_livetime', $
                    ['stx_sim_event_triggerlist', 'stx_sim_event_trigger*',  'double',   'double', 'double*'],$
                    ['triggers',                  'leftovers',               'starttime', 'endtime', 'timing'])
end
