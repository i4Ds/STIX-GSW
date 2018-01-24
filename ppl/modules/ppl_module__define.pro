;+
; :file_comments:
;    This is the base object for all pipeline processing modules
;
; :categories:
;    pipeline processing, definition
;
; :history:
;       17-Sep-2012, nicky.hochmuth@fhnw.ch, initial release
;       29-Apr-2014, Laszlo I. Etesi (FHNW), updated type checking with ppl_require, and allowing multiple input types (either or)
;       05-May-2014, Laszlo I. Etesi (FHNW), updated input types to be a) 1 input with X possible types or b) N inputs with each 1 specific type
;       22-May-2014, Laszlo I. Etesi (FHNW), cleanup
;-

;+
; :description:
;    Initialization of this class
;
; :params:
;    module : in, required, type='string'
;      is the modules name, e.g. ppl_module_example
;    input_type : in, required, type='string or strarr()'
;      is the expected input type as string, or a multiple allowed types as a string array (use typename());
;      see also 'additional_inputs'
;    additional_inputs : in, optional, type='string or strarr()', default='in'
;      the positional input parameter 'in' is required when calling 'execute'; in certain cases
;      additional input parameters are desired, which can be named here (in addition to 'in');
;      NB: when specifying additional inputs, the input types specified must match 'in' and 'additional_inputs' one-to-one
;
; :returns:
;    True if successful, otherwise false
;-
function ppl_module::init, module, input_types, input_keywords
  ; Only accept strings that begin with 'ppl_module_'
  if (~is_string(module) and str_lastpos(module, '_module_') eq -1) then return, 0
  self.module = module
  
  default, input_keywords, 'in'
  
  ppl_require, type='string*', input_types=input_types
  ppl_require, type='string*', input_keywords=input_keywords
  
  self.input_types = ptr_new(input_types)
  
  self.input_keywords = isvalid(input_keywords) ? ptr_new(input_keywords) : ptr_new('in')
  return, 1
end

;+
; :description:
;    Cleanup of this class
;
; :returns:
;    True if successful, otherwise false
;-
pro ppl_module::cleanup
  destroy, self.input_types
  destroy, self.input_keywords
end

;+
; :description:
;    This is the module execution routine. It must be overridden and called
;    by the other modules at the beginning of their implementation of execute.
;
; :params:
;    in is the input parameter that will be used for processing. It will be checked for validity
;    out is the output parameter. The processed data will be passed back through this parameter
;
; :keywords:
;    configuration is the configuration parameter. If not set, the default configuration is used
;
; :returns: true if successful, otherwise it returns false
;-
function ppl_module::execute, in, out, history, configuration
  ; Verify 'history' parameter
  ppl_require, type='ppl_history', history=history
  
  ; Verify 'in' parameter
  if((*self.input_keywords)[0] ne 'in') then ppl_require, keyword=*self.input_keywords, type=*self.input_types, _extra=in $
  else ppl_require, type=*self.input_types, in=in
  
  ppl_require, type='pointer', configuration=configuration
  ppl_require, type='ppl_configuration_manager', configuration=*configuration  
  
  out = self->_execute(in, configuration)
  
  ;history->add, self.module, in, out, configuration
  
  return, 1
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
function ppl_module::_execute, in, configuration
  compile_opt hidden
  message, "To be overidden", /block
end

;+
; :description:
;    Constructor
;
; :hidden:
;-
pro ppl_module__define
  compile_opt idl2, hidden
  void = { ppl_module, $
    module     : '', $
    input_types : ptr_new(), $
    input_keywords : ptr_new() $
    }
end
