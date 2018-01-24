;+
; :description:
;    Extracts the type from a given input variable; optionally
;    allows comparing to a desired type for validation
;
; :params:
;    variable : in, required, type='any'
;      the input variable for which the type is evaluated
;      (can be a primitive type, an variable, a structure, etc.)
; 
; :keywords:
;    compareto : in, optional, type='string'
;      the type name of 'compareto' is compared to the type
;      name of 'variable' and true or false is returned
;    raw : in, optional
;      if set to 1, the return type does not have '_array' attached
;      even if it is an array
;    isarray : out, optional
;      is set to 1 if 'variable' is an array, 0 otherwise
;    dimensions : out, optional
;      is set to the 'variable' dimension
;      
; :returns:
;    it knows to return types:
;    a) type string ('string', 'int', 'ppl_error', 'string_array')
;    b) true, false (1, 0) in combination with 'compareto'
;      
; :categories:
;    utility, legacy, pipeline
;    
; :examples:
;    t = 'hello'
;    type = ppl_typeof(t) ; type = STRING
;    
;    is_string = ppl_typeof(t, compareto='string') ; is_string = 1
;    is_int_array = ppl_typeof(t, compareto='int_array') ; is_int_array = 0
;    
; :history:
;    29-Apr-2014 - Laszlo I. Etesi (FHNW), initial release (of doc)
;-
function ppl_typeof, variable, compareto=compareto, isarray=isarray, dimensions=dimensions, raw=raw
  object_t = strlowcase(ppl_typename(variable))
  switch (object_t) of
    'struct': begin
      object_t = strlowcase(ppl_typename(variable[0]))
      if(tag_exist(variable, 'type')) then object_t = variable.type
      break
    end
    'anonymous': begin
      if(tag_exist(variable, 'type')) then object_t = (variable.type)[0]
      break
    end
    else: begin
    ; NOOP
    end
  endswitch
  
  if(n_elements(variable) gt 1 and ~keyword_set(raw)) then object_t = object_t + '_array'
  isarray = n_elements(variable) gt 1
  dimensions = size(variable, /dimensions)
  
  if(keyword_set(compareto)) then return, object_t eq strlowcase(compareto)
  
  return, object_t
end