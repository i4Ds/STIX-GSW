;---------------------------------------------------------------------------
; Document name: stx_module_sum_over_pixels__define.pro
; Created by:    nicky.hochmuth 30.08.2012
;---------------------------------------------------------------------------
;+
; PROJECT:          STIX
;
; NAME:             stx_module_sum_over_pixels Object
;
; PURPOSE:          Wrapping the pixel summary for the pipeline
;
; CATEGORY:         STIX PIPELINE
;
; CALLING SEQUENCE: modul = stx_module_sum_over_pixels_create()
;                   modul->execute(in, out, history, configuration=configuration)
;
; HISTORY:
;       30.08.2012 nicky.hochmuth initial release
;       23.07.2013 richard.schwartz, change execute function to stx_pixel_sums from stx_pixel_summaries
;
;-
function stx_module_sum_over_pixels::init, module, input_type
  return, self->ppl_module::init(module, input_type)
end

;+
; :description:
;    This internal routine verifies the validity of the input parameter
;    It uses typename() to perform the verification. For anonymous structures
;    a tag 'type' is assumed and that type is checked against the internal input
;    type.
;
; :params:
;    in is the input parameter to be verified
;
; :hidden:
;
; :returns: true if 'in' is valid, false otherwise
;-
function stx_module_sum_over_pixels::_execute, in, configuration
  compile_opt hidden
  config = *configuration->get(module=self.module)
  return, stx_pixel_sums_old(in, config.sumcase)
end

;+
; :description:
;    This internal routine verifies the validity of the input parameter
;    It uses typename() to perform the verification. For anonymous structures
;    a tag 'type' is assumed and that type is checked against the internal input
;    type.
;
; :params:
;    in is the input parameter to be verified
;
; :hidden:
;
; :returns: true if 'in' is valid, false otherwise
;-
function stx_module_sum_over_pixels::_verify_input, in
  compile_opt hidden
  
  if ~self->ppl_module::_verify_input(in) then return, 0
  ;do additional checking here
  
  return , 1
end

;+
; :description:
;    This internal routine verifies the validity of the configuration
;    parameter
;
; :params:
;    configuration is the input parameter to be verified
;
; :hidden:
;
; :returns: true if 'configuration' is valid, false otherwise
;-
function stx_module_sum_over_pixels::_verify_configuration, configuration
  compile_opt hidden
  
  if ~self->ppl_module::_verify_configuration(configuration) then return, 0
  
  ;do additional checking here
  
  return, 1
end


;+
; :description:
;    Cleanup of this class
;-
pro stx_module_sum_over_pixels::cleanup
  self->ppl_module::cleanup
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
pro stx_module_sum_over_pixels__define
  compile_opt idl2, hidden
  void = { stx_module_sum_over_pixels, $
    inherits ppl_module }
end