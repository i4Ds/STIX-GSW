;+
; PROJECT:          STIX
;
; NAME:             stx_module_calibrate_visibilities Object
;
; PURPOSE:          Wrapping the visibiity creation for the pipeline
;
; CATEGORY:         STIX PIPELINE
;
; CALLING SEQUENCE: modul = stx_module_calibrate_visibilities()
;                   modul->execute(in, out, history, configuration=configuration)
;
; HISTORY:
;     16-Jul-2013 - Marina Battaglia (FHNW)
;-

function stx_module_calibrate_visibilities::init, module, input_type
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
function stx_module_calibrate_visibilities::_execute, visibility_bags, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  n_inputs = n_elements(visibility_bags)
  
  calibration_file = conf.calibration_file
  ; structure=routine_that_reads_calbiration_file()
  ; ; then: calibrated_visibility_cube = stx_viscalib(visibility_cube, structure)
  ; or else: calibrated_visibility_cube = stx_viscalib(visibility_cube, calibration_file) -> read the calibration file in stx_viscalib
  ; call stx_viscalib
  
  for i=0L, n_inputs-1  do begin
    visibility_bags[i].visibility = stx_viscalib(visibility_bags[i].visibility)
    visibility_bags[i].visibility.calibrated = 1
  endfor
  
  return, visibility_bags 
  
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
function stx_module_calibrate_visibilities::_verify_input, in
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
function stx_module_calibrate_visibilities::_verify_configuration, configuration
  compile_opt hidden
  
  if ~self->ppl_module::_verify_configuration(configuration) then return, 0
  
  ;do additional checking here
  return, 1
end


;+
; :description:
;    Cleanup of this class
;-
pro stx_module_calibrate_visibilities::cleanup
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
pro stx_module_calibrate_visibilities__define
  compile_opt idl2, hidden
  
  void = { stx_module_calibrate_visibilities, $
    inherits ppl_module }
end
