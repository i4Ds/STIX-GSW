;+
; :description:
;    Create a new STX_MODULE_LOCATE_DATA_FILE object
;
; returns the new module
;-
function stx_module_locate_data_file
  return , obj_new('stx_module_locate_data_file','stx_module_locate_data_file','anonymous')
end
