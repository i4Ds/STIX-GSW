;+
; :description:
;    This utility routine is used for validating XML configuration values.
;    It tests if a value is listed in an array (X in Y)
;
; :categories:
;    xml, configuration, utility, validation
;
; :params:
;    value : in, required, type='anyting'
;      any value to be tested
;      
;    array : in, required, type='array of anything'
;      an array with values for testing against
;      
; :returns:
;    if test is successful 1 is returned
;
; :examples:
;    successful = ppl_xml_value_in_array_test('n', ['a', 'b'])
;    IDL> help, successful
;    SUCCESSFUL     BYTE      =    0
;
; :history:
;    21-Aug-2014 - Laszlo I. Etesi (FHNW), initial release
;-
function ppl_xml_value_in_array_test, value, array
  if(~isvalid(value)) then return, 0
  if(~isarray(array)) then return, 0
  return, (where(value eq array))[0] ne -1
end