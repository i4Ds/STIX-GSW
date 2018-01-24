;+
; :description:
;    Create a new stx_module_create_map object
;
; returns the new module
;-
function stx_module_create_map
  return, obj_new('stx_module_create_map','stx_module_create_map','stx_visibility_bag'+['','_array'])
end
