;+
; :description:
;    Create a new STX_DS_MODULE_PHOTON_DETECTION_TEST object
;
; returns the new module
;-
function stx_ds_module_photon_detection_test
  return , obj_new('stx_ds_module_photon_detection_test','stx_ds_module_photon_detection_test',['stx_sim_photon*','stx_sim_source*','stx_time'], ['events','source','start_time'])
end
