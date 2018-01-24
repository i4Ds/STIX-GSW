;+
; :file_comments:
;    This module is part of the Flight Software Simulation (FSW) package and 
;    performs the interval selection for spectroscopy on the archive buffer and the output od the intervalselection for imaging
;
; :categories:
;    Flight Software, interval selection, module, spectroscopy
;
; :examples:
;    obj = new_obj('stx_fsw_module_intervalselection_spc')
;
; :history:
;    07-Dec-2015 - Nicky Hochmuth (FHNW), initial release
;-    


;+
; :description:
;    This internal routine calibrates the accumulator data
;
; :params:
;    in : in, required, type="defined in 'factory function'"
;        this is a stx_sim_source_structure object
;         
;    configuration : in, required, type="stx_configuration_manager"
;        this is the configuration manager object containing the 
;        configuration parameters for this module
;
; :returns:
;   this function returns an array of stx_sim_photon_structure
;-
function stx_fsw_module_intervalselection_spc::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  conf.plotting  = 1
  
  ;combine detector mask from config with list of active detectors
  ;detectors_used = in.active_detectors AND conf.detector_mask 
    
  return, stx_fsw_ivs_spc(in.spectrogram, in.time_splits, $ 
    thermalboundary = in.thermalboundary, $
    min_count   = conf.min_count,$
    min_time    = conf.min_time, $
    plotting    = conf.plotting)
end

;+
; :description:
;    Constructor
;
; :inherits:
;    hsp_module
;
; :hidden:
;-
pro stx_fsw_module_intervalselection_spc__define
  compile_opt idl2, hidden
  
  void = { stx_fsw_module_intervalselection_spc, inherits ppl_module}
end
