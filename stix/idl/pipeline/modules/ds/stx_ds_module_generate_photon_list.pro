;+
; :description:
;    Create a new STX_DS_MODULE_GENERATE_PHOTON_LIST object
;
; returns the new module
;-
function stx_ds_module_generate_photon_list
  return , obj_new('stx_ds_module_generate_photon_list','stx_ds_module_generate_photon_list',['stx_sim_source*', 'long', 'long'], ['souces', 'bkg_flux', 'bkg_duration'])
end
