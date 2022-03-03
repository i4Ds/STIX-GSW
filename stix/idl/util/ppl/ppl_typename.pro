;+
; :description:
;    Evaluates the type of a variable and returns the type as a string.
;    Only for pre IDL 8.0 and in conjunction with ppl_typeof
;
; :params:
;    variable : in, required, type=any
;      the input variable for which the type is evaluated
;      (can be a primitive type, an object, a structure, etc.)
;      
; :returns:
;    the type of the input variable as a string
;      
; :categories:
;    utility, legacy, pipeline
;    
; :examples:
;    t = 'hello'
;    type = ppl_typename(t) ; type = STRING
;    
; :history:
;    2012/08/01 richard.schwartz@nasa.gov, initial release
;    2012/08/25, laszlo.etesi@fhnw.ch, added objref compatibility
;-
function ppl_typename, variable name = size(/tname, variable) if name eq 'STRUCT' then begin  name = size(/sname, variable)  name = name eq '' ? 'ANONYMOUS' : name endif if name eq 'OBJREF' then begin  help, variable, out=name  name = strsplit(name, '(.*)', /ex)  name = name[1] endif return, nameend