;+
; :description:
;    This utility routine is used for validating the validity conditions
;    in the configuration XML.
;    a) it verifies that 'value' is of type 'type'
;    b) it executes 'condition' with 'value' plugged in
;
; :categories:
;    xml, configuration, utility
;
; :params:
;    value : in, required, type='anyting'
;      any value for verification
;      
;    condition : in, required, type='string'
;      this condition is a either an expression with variable 'X'
;      representing 'value' or a test/verification function
;      
;    type : in, required, type='string'
;      a type, e.g. 'byte', 'byte_array', etc.
;      
; :returns:
;    if tests are successful 1 is returned
;
; :examples:
;    successful = ppl_xml_validate_value(4.5d, 'X gt 4 and X lt 5', 'double')
;    IDL> help, successful
;    SUCCESSFUL     BYTE      =    1
;
; :history:
;    21-Aug-2014 - Laszlo I. Etesi (FHNW), initial release
;-
function ppl_xml_validate_value, value, condition, type
  ; test if value is proper type
  isvalid = ppl_typeof(value, compareto=type)
  if(~isvalid) then return, 0
  
  ; test if value meets condition
  res = execute('isvalid=' + str_replace(condition, 'X', 'value'))
  
  return, res && isvalid
end