;+
; :Description:
;    The base string needed for all queries and requests to
;    the pub023 server at fhnw
;
;
;
;
;
; :Author: rschwartz70@gmail.com
; :History: Valid 4-aug-2020
; 6-aug-2020, password not needed
;-
function stx_pub023_query_base
  return, 'http://pub023.cs.technik.fhnw.ch/'
end