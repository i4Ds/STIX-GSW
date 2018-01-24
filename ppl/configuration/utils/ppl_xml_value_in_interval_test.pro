;+
; :description:
;    This utility routine is used for validating XML configuration values.
;    It tests if a value is between two boundaries.
;
; :categories:
;    xml, configuration, utility, validation
;
; :params:
;    value : in, required, type='number'
;      any value to be tested
;      
;    array : in, required, type='array of numbers'
;      an array with two values (upper, lower bounds)
;      
; :returns:
;    if test is successful 1 is returned
;
; :examples:
;    successful = ppl_xml_value_in_interval_test(1d, [0d, 1d])
;    IDL> help, successful
;    SUCCESSFUL     BYTE      =    1
;
; :history:
;    21-Aug-2014 - Laszlo I. Etesi (FHNW), initial release
;-
function ppl_xml_value_in_interval_test, value, array
  if(~isvalid(value)) then return, 0
  if(~isarray(array)) then return, 0
  return, value le max(array) and value ge min(array)
end