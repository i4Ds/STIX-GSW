;+
; :file_comments:
;    
;
; :categories:
;    
;
; :examples:
;    obj = new_obj('ppl_module_lut')
;
; :history:
;    09-Jul-2014 - Nicky Hochmuth (FHNW), initial release
;-

function ppl_module_lut::init, module, input_types, input_keywords
    
    res = self->ppl_module::init(module, input_types, input_keywords)
    
    self.lut_data = hash()
    self.lut_files = hash()
    
    return, res
end

pro ppl_module_lut::cleanup
  self->ppl_module::cleanup
  
  self.lut_data->remove, /all
  destroy, self.lut_data
  self.lut_files->remove, /all
  destroy, self.lut_files

end

function ppl_module_lut::is_invalid_config, key, conf_entry
  res = ~self.lut_files.hasKey(key) || ~strcmp(conf_entry, (self.lut_files)[key], /fold_case )
  if res then (self.lut_files)[key] = conf_entry
  return, res  
end

pro ppl_module_lut::update_io_data, conf
    
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
pro ppl_module_lut__define
  compile_opt idl2, hidden
  
  void = { ppl_module_lut, $
    lut_data  : hash(), $
    lut_files : hash(), $
    inherits ppl_module }
end
