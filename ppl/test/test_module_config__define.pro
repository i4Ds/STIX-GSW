function test_module_config::init, module, input_type, configfile
  return, self->ppl_module::init(module, input_type, configfile)
end

function test_module_config::_execute, in, configuration
  compile_opt hidden
  
  help, in
  
  help, configuration
  
  return, {type : 'test_struct'}
  
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
function test_module_config::_verify_input, in
  compile_opt hidden
  
  if ~self->ppl_module::_verify_input(in) then return, 0
  
  ;do additional checking here
  return, 1
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
function test_module_config::_verify_configuration, configuration
  compile_opt hidden
  
  if ~self->ppl_module::_verify_configuration(configuration) then return, 0
  
  ;do additional checking here
  return, 1
end


;+
; :description:
;    Cleanup of this class
;-
pro test_module_config::cleanup
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
pro test_module_config__define
  compile_opt idl2, hidden
  
  void = { test_module_config, $
    inherits ppl_module }
end
