;+
; :description:
;    Create a new STX_DS_MODULE_GENERATE_TIME_PROFILE object
;
; returns the new module
;-
function stx_ds_module_generate_time_profile
  return , obj_new('stx_ds_module_generate_time_profile','stx_ds_module_generate_time_profile','long')
end
