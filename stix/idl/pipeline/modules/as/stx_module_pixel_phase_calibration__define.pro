;---------------------------------------------------------------------------
; Document name: stx_module_pixel_phase_calibration__define.pro
; Created by:    nicky.hochmuth 02.05.2013
;---------------------------------------------------------------------------
;+
; PROJECT:          STIX
;
; NAME:             stx_module_pixel_phase_calibration Object
;
; PURPOSE:          Wrapping the pixel phase calibration for the pipeline
;
; CATEGORY:         STIX PIPELINE
;
; CALLING SEQUENCE: modul = stx_module_pixel_phase_calibration()
;                   modul->execute(in, out, history, configuration=configuration)
;
; HISTORY:
;       11.02.2013 nicky.hochmuth initial (empty) release
;-


function stx_module_pixel_phase_calibration::init, module, input_type
  ret = self->ppl_module::init(module, input_type)
  if ret then begin
         
    return, 1
  end
  return, ret
end


function stx_module_pixel_phase_calibration::_execute, in, configuration
  compile_opt hidden
  
  return, in
  
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
function stx_module_pixel_phase_calibration::_verify_input, in
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
function stx_module_pixel_phase_calibration::_verify_configuration, configuration
  compile_opt hidden
  
  if ~self->ppl_module::_verify_configuration(configuration) then return, 0
  
  ;do additional checking here
  return, 1
end

;+
; :description:
;    Cleanup of this class
;-
pro stx_module_pixel_phase_calibration::cleanup
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
pro stx_module_pixel_phase_calibration__define
  compile_opt idl2, hidden
  
  void = { stx_module_pixel_phase_calibration, $
           inherits ppl_module }
end
