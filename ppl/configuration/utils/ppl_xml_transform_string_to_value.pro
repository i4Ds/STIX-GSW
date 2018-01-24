;+
; :description:
;    This routine takes a string (value, expression) and transforms that string into
;    a real value (e.g. double value, calulated value).
;
; :categories:
;    xml, configuration, utility
;
; :params:
;    value_string : in, required, type='string'
;      an expression or value that can be executed
; :returns:
;    the executed "value" of the input expression
;
; :examples:
;    value = ppl_xml_transform_string_to_value('0b')
;    IDL> help, value
;    VALUE           BYTE      =    0
;
; :history:
;    21-Aug-2014 - Laszlo I. Etesi (FHNW), initial release
;-

function ppl_xml_transform_string_to_value, value_string
  if(value_string eq '') then return, !NULL
  
  transformation = 'ret=' + value_string
  res = execute(transformation)
  
  return, ret
end