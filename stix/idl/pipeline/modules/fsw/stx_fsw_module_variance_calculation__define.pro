;+
; :file_comments:
;    This module is part of the flight software (FSW) package and
;    calculates the variance on quicklook accumulated data
;
; :categories:
;    flight software, variance, quicklook accumulated data , module
;
; :examples:
;    obj = stx_fsw_module_variance_calculation()
;
; :history:
;    26-jun-2014 - Nicky Hochmuth (FHNW), initial release
;    10-May-2016 - Laszlo I. Etesi (FHNW), updated structure type names
;-

;+
; :description:
;    This internal routine call the variance calculation
;
; :params:
;    in : in, required, type="defined in 'factory function'"
;        this is a STX_FSW_QL_... object
;
;    configuration : in, required, type="stx_configuration_manager"
;        this is the configuration manager object containing the
;        configuration parameters for this module
;
; :returns:
;   this function returns an array of the variance
;   
; :history:
;   26-jun-2014 - Nicky Hochmuth (FHNW), initial release
;-
function stx_fsw_module_variance_calculation::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  no_var = conf.no_var
  bit16 = tag_exist(conf, bit16) ? conf.bit16 : 0 
  
  return, stx_fsw_m_variance(variance=stx_fsw_ql_variance_calc(in.ql_data, no_var=no_var))
  
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
pro stx_fsw_module_variance_calculation__define
  compile_opt idl2, hidden
  
  void = { stx_fsw_module_variance_calculation, $
    inherits ppl_module }
end
