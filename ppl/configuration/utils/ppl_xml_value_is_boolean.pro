;+
; :description:
;    This utility routine is used for validating XML configuration values.
;    It tests if a value is zero or one
;
; :categories:
;    xml, configuration, utility, validation
;
; :params:
;    value : in, required, type='anyting'
;      any value to be tested for 0 or 1
;      
; :returns:
;    if test is successful 1 is returned
;
; :examples:
;    successful = ppl_xml_value_is_boolean(2)
;    IDL> help, successful
;    SUCCESSFUL     BYTE      =    0
;
; :history:
;    27-Aug-2014 - Laszlo I. Etesi (FHNW), initial release
;-
function ppl_xml_value_is_boolean, value
  if(~isvalid(value)) then return, 0
  return, ppl_xml_value_in_array_test(value, [0b,1b])
end