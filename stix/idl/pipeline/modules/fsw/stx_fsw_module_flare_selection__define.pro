
;+
; :file_comments:
;    This module is part of the FLIGHT SOFTWARE (FSW) package and
;    generate a list of flare times based on the flare flag of the stx_fsw_module_flare_detection
;
; :categories:
;    flight software, flare detection and selevtion
;
; :examples:
;       fs = stx_fsw_module_flare_selection()
;       succes = fs->execute({time:ql_flare_detection.time_axis,flare_flag:flare_flag}, flare_times ,ppl_history(),configmanager_ptr)
; :history:
;    22-May-2014 - Nicky Hochmuth (FHNW), initial release
;-

;+
; :description:
;    This internal routine calls the stx_fsw_flare_selection to perform the flare selection
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
;   this function returns a stx_fsw_flare_selection_result with:
;   result.flare_times   : type:stx_time(*,2)
;   
;-
function stx_fsw_module_flare_selection::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  return, stx_fsw_flare_selection(in.flare_flag, in.cfl)
  
  
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
pro stx_fsw_module_flare_selection__define
  compile_opt idl2, hidden
  
  void = { stx_fsw_module_flare_selection, $
    inherits ppl_module }
end
