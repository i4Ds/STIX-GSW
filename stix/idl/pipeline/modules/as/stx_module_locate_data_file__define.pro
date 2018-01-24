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

function stx_module_locate_data_file::init, module, input_type
  ret = self->ppl_module::init(module, input_type)
  if ret then begin  
    return, 1
  end
  return, ret
end

function stx_module_locate_data_file::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  data_location = conf.data_location
  
  start_time = in.start_time
  end_time = in.end_time
  
  if(tag_exist(in, 'compression_level')) then compression_level = trim(string(in.compression_level)) $
  else compression_level = '3'
  
  ; locate file
  start_date_string = arr2str(strsplit((strsplit(anytim(start_time, /yymmdd), ',', /extract))[0], '/', /extract), delimiter='_')
  end_date_string = arr2str(strsplit((strsplit(anytim(start_time, /yymmdd), ',', /extract))[0], '/', /extract), delimiter='_')
  data_files = concat_dir(data_location, concat_dir(compression_level, [start_date_string, end_date_string] + '_data.fits'))
  
  return, data_files
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
function stx_module_locate_data_file::_verify_input, in
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
function stx_module_locate_data_file::_verify_configuration, configuration
  compile_opt hidden
  
  if ~self->ppl_module::_verify_configuration(configuration) then return, 0
  
  ;do additional checking here
  return, 1
end

;+
; :description:
;    Cleanup of this class
;-
pro stx_module_locate_data_file::cleanup
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
pro stx_module_locate_data_file__define
  compile_opt idl2, hidden
  
  void = { stx_module_locate_data_file, $
           inherits ppl_module }
end
