;+
; :file_comments:
;    this file contains the data locator module; it is a very first prototype version
;
; :categories:
;    pipeline, data, reader, telemetry
;
; :properties:
;    module
;      
;    input_type
;    
;    configfile
;
; :examples:
;    module = stx_module_read_data()
;    module->execute(in, out, history, configuration=configuration)
;
; :history:
;    07-Jun-2013 - Laszlo I. Etesi (FHNW), initial release
;-

function stx_module_read_data::init, module, input_type
  ret = self->ppl_module::init(module, input_type)
  if ret then begin  
    return, 1
  end
  return, ret
end

function stx_module_read_data::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  files_to_read = in.data_files[uniq(in.data_files)]
  files_already_read = tag_exist(in, 'data_files_buffered') ? in.data_files_buffered : ['']
  
  foreach ftr, files_to_read do begin
    if(where(files_already_read eq ftr) ne -1) then continue
    data = { type:'stx_data_from_file', data:mrdfits(ftr, 1), file:ftr }
    if(isvalid(out)) then out = [out, data] $
    else out = data
  endforeach
  return, data
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
function stx_module_read_data::_verify_input, in
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
function stx_module_read_data::_verify_configuration, configuration
  compile_opt hidden
  
  if ~self->ppl_module::_verify_configuration(configuration) then return, 0
  
  ;do additional checking here
  return, 1
end

;+
; :description:
;    Cleanup of this class
;-
pro stx_module_read_data::cleanup
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
pro stx_module_read_data__define
  compile_opt idl2, hidden
  
  void = { stx_module_read_data, $
           inherits ppl_module }
end
