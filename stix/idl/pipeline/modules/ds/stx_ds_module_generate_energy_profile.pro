;+
; :description:
;    Create a new STX_DS_MODULE_GENERATE_ENERGY_PROFILE object
;
; returns the new module
;-
function stx_ds_module_generate_energy_profile
  return , obj_new('stx_ds_module_generate_energy_profile','stx_ds_module_generate_energy_profile','long')
end
