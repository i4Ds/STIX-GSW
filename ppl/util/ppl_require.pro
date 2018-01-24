;+
; :description:
;    This routine does parameter and type checking
;    a) verify one/many parameters are present
;    b) verify all parameters are present and have proper types
;    b) verify one parameter is present and has proper type
;    
;    The default behaviour is to raise an error using 'message'.
;
; :keywords:
;    keyword : in, optional, type='string or strarr()'
;      if 'keyword' is not present, 'extra' must only contain one
;      parameter and that parameter is checked against 'type';
;      if 'keyword' is present, it is verified that all parameters
;      are present in 'extra'
;    type : in, optional, type='string or strarr()'
;      if 'type' is present, all parameters in 'keyword' are
;      checked against 'type' (one-to-one comparison); if there
;      is only one parameter present in 'keyword', 'type' can contain
;      a list of valid types
;      NB: a type can have an asterisk appended, which indicates that
;      both the type and the array type are allowed, e.g. 'int*'
;    raise_error : in, optional, type='bool', default='true'
;      if set to true, ppl_require will raise an error using 'message'
;      otherwise ppl_require will stay silent (use in combination
;      with 'out_successful'
;    raw : in, optional, type='bool'
;      if set to true, 'ppl_require, type='int', in=1' and 
;      'ppl_require, type='int', in=[1, 2, 3]' are both correct
;      NB: if 'raw' is set, ALL parameters are array types!
;    out_successful : out, optional, type='bool'
;       is set to true if all conditions have been satisfied, or false
;       otherwise
;      
; :categories:
;    utility, error handling, pipeline
;    
; :examples:
;    ppl_require, in=[1,2], type='int_array' ; ok
;    ppl_require, in=[1,2], type='int*' ; ok
;    ppl_require, keyword=['some', 'var'], type=['int', 'string'], /some, var=5b ; not ok: incorrect datatypes
;    ppl_require, keyword=['some', 'var'], /some ; not ok: 'var' is missing
;    ppl_require, in='hello', type=['string', 'string_array', 'ppl_error'] ; ok
;    
; :history:
;    29-Apr-2014 - Laszlo I. Etesi (FHNW), initial release (of doc)
;    05-May-2014 - Laszlo I. Etesi (FHNW), added array type functionality ('type*')
;    19-May-2014 - Laszlo I. Etesi (FHNW), bugfix
;    07-Jul-2015 - Laszlo I. Etesi (FHNW), better error handling in case of multi-keyword <-> multi-input 
;    07-Jan-2016 - Laszlo I. Etesi (FHWN), bugfix: proper handling of multi-input - multi-keyword
;-
pro ppl_require, keyword=keyword, type=type, raise_error=raise_error, out_successful=out_successful, raw=raw, _extra=extra
  on_error, 2
  
  default, raise_error, 1
  overload = 0
  out_successful = 0
  
  if(~isvalid(keyword)) then begin
    if(n_tags(extra) gt 1) then message, "The input keyword parameter 'keyword' can only be empty or undefined if 'extra' contains only one element." $
    else if (n_tags(extra) eq 0) then message, "Could not find any keywords ('extra' is empty). Check that not all keywords are 'undefined'." $
    else default, keyword, strlowcase(tag_names(extra))
  endif
  
  if(keyword_set(type)) then begin
    if(n_elements(keyword) le 1 && n_elements(type) gt 1) then overload = 1 $
    else if (n_elements(keyword) gt 1 && n_elements(keyword) ne n_elements(type)) then message, "The dimensions of the parameters 'keyword' and 'type' disagree."
  endif
  
  missing_keywords = bytarr(n_elements(keyword))
  incorrect_types = (~overload) ? bytarr(n_elements(keyword)) : bytarr(n_elements(type))
  
  arrays_allowed = stregex(type, '.*\*$', /boolean)
  allow_array_and_not = ((keyword_set(raw)) ? raw : 0) or arrays_allowed
  actual_types = type
  if(max(arrays_allowed) eq 1) then actual_types[where(arrays_allowed eq 1)] = str_replace(actual_types[where(arrays_allowed eq 1)], '*', '')
  
  for i = 0L, n_elements(keyword)-1 do begin
    if(~tag_exist(extra, keyword[i])) then missing_keywords[i] = 1b $
    else if(keyword_set(type)) then begin
      if(~overload) then incorrect_types[i] = ~ppl_typeof(extra.(tag_index(extra, keyword[i])), compareto=actual_types[i], raw=allow_array_and_not[i]) $
      else for j = 0L, n_elements(type)-1 do incorrect_types[j] = ~ppl_typeof(extra.(tag_index(extra, keyword[i])), compareto=actual_types[j], raw=allow_array_and_not[j])
    endif
  endfor
  
  if(~overload && max([max(missing_keywords), max(incorrect_types)]) eq 0 || (overload && max([max(missing_keywords), min(incorrect_types)]) eq 0)) then begin
    out_successful = 1
    return
  endif

  missing_keywords_string = ''
  incorrect_types_string = ''
  
  if(max(missing_keywords) gt 0) then $
    missing_keywords_string = 'Missing required keyword(s): ' + arr2str(keyword[where(missing_keywords ne 0)])
  
  if(~overload) then begin
    if(max(incorrect_types) gt 0) then begin
      inc_t_idx = where(incorrect_types ne 0)
      actual_types = strarr(n_elements(inc_t_idx))
      for index = 0L, n_elements(inc_t_idx)-1 do actual_types[index] = ppl_typeof(extra.(tag_index(extra, keyword[inc_t_idx[index]])), raw=allow_array_and_not[inc_t_idx[index]])
  
      incorrect_types_string = 'Incorrect data type(s): ' + arr2str(keyword[inc_t_idx] + ':' + type[inc_t_idx] + '[' + actual_types + ']')
    endif
  endif else begin
    if(min(incorrect_types) eq 1) then begin
      incorrect_types_string = strarr(n_elements(keyword))
      for index = 0L, n_elements(keyword)-1 do begin
        incorrect_types_string[index] = keyword[index] + ':' + type[index] + '[' + ppl_typeof(extra.(tag_index(extra, keyword[index])), raw=raw) + ']'
      endfor

      incorrect_types_string = 'No matching types found: ' + arr2str(incorrect_types_string, ',')
    endif
  endelse

  error_message = missing_keywords_string 
  if(strlen(missing_keywords_string) gt 0 && strlen(incorrect_types_string) gt 0) then error_message += string(10b)
  error_message += incorrect_types_string
  
  if(raise_error) then message, error_message $
  else return
end