;+
; :description:
;    Create a new STX_MODULE_READ_DATA object
;
; returns the new module
;-
function stx_module_read_data
  return , obj_new('stx_module_read_data','stx_module_read_data','anonymous')
end
