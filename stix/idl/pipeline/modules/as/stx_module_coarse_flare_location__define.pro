;---------------------------------------------------------------------------
; Document name: stx_module_coarse_flare_location__define.pro
; Created by:    nicky.hochmuth 02.05.2013
;---------------------------------------------------------------------------
;+
; PROJECT:          STIX
;
; NAME:             stx_module_coarse_flare_location Object
;
; PURPOSE:          Wrapping the coarse flare location for the pipeline
;
; CATEGORY:         STIX PIPELINE
;
; CALLING SEQUENCE: modul = stx_module_coarse_flare_location()
;                   modul->execute(in, out, history, configuration=configuration)
;
; HISTORY:
;       11.02.2013 nicky.hochmuth initial (empty) release
;-


function stx_module_coarse_flare_location::init, module, input_type
  ret = self->ppl_module::init(module, input_type)
  if ret then begin
         
    return, 1
  end
  return, ret
end


function stx_module_coarse_flare_location::_execute, pixel_data, configuration
  compile_opt hidden
  
  n_inputs = n_elements(pixel_data)
  all_locations = fltarr(2,n_inputs)
  
; TODO: N.H. enable again  
;  for i=0L, n_inputs-1  do begin
;    location = stx_flare_location(pixel_data[i])
;    all_locations[*,i]=location
;  endfor
  
  return, all_locations
  
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
function stx_module_coarse_flare_location::_verify_input, in
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
function stx_module_coarse_flare_location::_verify_configuration, configuration
  compile_opt hidden
  
  if ~self->ppl_module::_verify_configuration(configuration) then return, 0
  
  ;do additional checking here
  return, 1
end

;+
; :description:
;    Cleanup of this class
;-
pro stx_module_coarse_flare_location::cleanup
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
pro stx_module_coarse_flare_location__define
  compile_opt idl2, hidden
  
  void = { stx_module_coarse_flare_location, $
           inherits ppl_module }
end
