;---------------------------------------------------------------------------
; Document name: stx_module_create_visibilities__define.pro
; Created by:    nicky.hochmuth 30.08.2012
;---------------------------------------------------------------------------
;+
; PROJECT:          STIX
;
; NAME:             stx_module_create_visibilities Object
;
; PURPOSE:          Wrapping the visibiity creation for the pipeline
;
; CATEGORY:         STIX PIPELINE
;
; CALLING SEQUENCE: modul = stx_module_create_visibilities()
;                   modul->execute(in, out, history, configuration=configuration)
;
; HISTORY:
;       30-Aug-2012 - Nicky Hochmuth (FHWN), initial release
;       07-Jan-2013 - Richard Schwartz, fix for uppercase/lowercase string comparison
;       14-Jan-2013 - Shaun Bloomfield (TCD), revised subcollimator structure tags
;       14-Apr-2013 - Laszlo I. Etesi (FHNW), changed subcollimator
;                     parameter file reading (temporary)
;       25-Oct-2013 - Shaun Bloomfield (TCD), renamed subcollimator
;                     reading routine stx_construct_subcollimator.pro
;-
function stx_module_create_visibilities::init, module, input_type
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
function stx_module_create_visibilities::_execute, pixel_data, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  ; read subcollimator configuration data
  ; bugfix for ssw compatibility, introduced v0r3, temporary
  subc_str = stx_construct_subcollimator(conf.subc_file)
  
  ; call stx_visgen
  
  n_inputs = n_elements(pixel_data)
  
  for i=0L, n_inputs-1  do begin
   
     bag = {$
        type          : "stx_visibility_bag", $
        time_range    : pixel_data[i].time_range, $
        energy_range  : pixel_data[i].energy_range, $
        datasource    : "ASW generated", $
        visibility    : stx_visgen(pixel_data[i], subc_str, f2r_sep=conf.f2r_sep) $
     }
   
     if i eq 0 then all_bags = replicate(bag,n_inputs) else all_bags[i]=bag
    
  endfor
  
  return, all_bags
  
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
function stx_module_create_visibilities::_verify_input, in
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
function stx_module_create_visibilities::_verify_configuration, configuration
  compile_opt hidden
  
  if ~self->ppl_module::_verify_configuration(configuration) then return, 0
  
  ;do additional checking here
  return, 1
end


;+
; :description:
;    Cleanup of this class
;-
pro stx_module_create_visibilities::cleanup
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
pro stx_module_create_visibilities__define
  compile_opt idl2, hidden
  
  void = { stx_module_create_visibilities, $
    inherits ppl_module }
end
