;+
; :file_comments:
;    This module is part of the Flight Software Simulator Module (FSW)
;    "Background Monitor".
;
; :categories:
;    Flight Software Simulaton, background monitor
;
; :examples:
;    obj = stx_fsw_module_background_determination()
;
; :history:
;    28-may-2014 - Laszlo I. Etesi (FHNW), initial release
;    02-jul-2015 - Laszlo I. Etesi (FHNW), added new pixel mask parameter to config and passing it in to the module
;    30-may-2016 - Laszlo I. Etesi (FHNW), updated routine call to background determination
;-


;+
; :description:
;    This internal routine calls the background determination algorithm
;
; :params:
;    in : in, required, type="defined in 'factory function'"
;        this is a stx_fsw_ql_accumulators structure
;
;    configuration : in, required, type="stx_configuration_manager"
;        this is the configuration manager object containing the
;        configuration parameters for this module
;
; :returns:
;   this function returns a two element array with the calculated [x, y] source position
;-
function stx_fsw_module_background_determination::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)

  return, stx_fsw_background_determination( $
      in.ql_bkgd_acc, $
      conf.enable, $
      default_background=conf.default_background, $
      int_time=in.int_time)
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
pro stx_fsw_module_background_determination__define
  compile_opt idl2, hidden
  
  void = { stx_fsw_module_background_determination, $
    inherits ppl_module }
end
