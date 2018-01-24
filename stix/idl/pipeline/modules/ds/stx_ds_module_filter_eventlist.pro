;+
; :description:
;    Create a new STX_DS_MODULE_FILTER_EVENTLIST object
;
; returns the new module
;-
function stx_ds_module_filter_eventlist
  return , obj_new('stx_ds_module_filter_eventlist','stx_ds_module_filter_eventlist','stx_sim_detector_eventlist')
end
