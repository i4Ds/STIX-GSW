pro _pretty_print, tag, value, lun=lun
  p_tag = tag
  
  if(size(value[0], /type) eq 1) then value = fix(value) ; prevent byte from being printed as ASCII character

  if(isarray(value)) then p_value = '[' + arr2str(trim(string(value)), ',') + ']' $
  else if(is_string(value)) then p_value = value $
  else p_value = trim(string(value))
  
  sep = arr2str(strarr(30 - strlen(p_tag) > 1), delimiter=' ')
  
  printf, lun, p_tag + sep + ': ' + p_value
end
pro stx_telemetry_print_all, input, lun=lun, file=file, init=init, curr_ref=curr_ref, pre_ref=pre_ref, noref=noref
  default, init, 0
  default, file, 'output.txt'
  default, is_init_caller, 0
  default, curr_ref, 0
  default, pre_ref, 0
  default, noref, 0
  
  if(~init) then begin
    is_init_caller = 1
    init = 1
    delvar, lun
    openw, lun, file, /get_lun
  endif
 
  type = ppl_typeof(input, isarray=isarray, /raw)

  if(isarray && type eq 'pointer') then for i = 0L, n_elements(input)-1 do stx_telemetry_print_all, input[i], lun=lun, file=file, init=init, curr_ref=ptr_valid(input[i], /get_heap_identifier), pre_ref=curr_ref, noref=noref else $
  if(isarray && is_struct(input)) then for i = 0L, n_elements(input)-1 do stx_telemetry_print_all, input[i], lun=lun, file=file, init=init, curr_ref=obj_valid(input[i], /get_heap_identifier), pre_ref=curr_ref, noref=noref else $
  if(type eq 'pointer' && ptr_valid(input[0])) then stx_telemetry_print_all, *input[0], lun=lun, file=file, init=init, curr_ref=ptr_valid(input[0], /get_heap_identifier), pre_ref=curr_ref, noref=noref $
  else begin
    if(is_struct(input)) then begin
      tags = tag_names(input)
      
      help, input, out=out
      
      str_ref = (stregex(out[0], '<([a-z0-9]*)>', /subexpr, /extract))[1]
      
      if(noref) then printf, lun, '{ ref' $
      else printf, lun, '{ ref ' + (curr_ref gt 0 ? trim(string(curr_ref)) + ':' : '') + str_ref
      
      for i = 0L, n_tags(input)-1 do begin
        tag = strlowcase(tags[i])
        tag_val = input.(i)
        
        vt = ppl_typeof(tag_val, /raw, isarray=vt_isarray)
        
        if(is_struct(tag_val[0])) then begin
          help, tag_val[0], out=tag_out
          tag_str_ref = (stregex(tag_out[0], '<([a-z0-9]*)>', /subexpr, /extract))[1]
           
          _pretty_print, tag, '<obj ref' + (noref ? '' : (': ' + (pre_ref gt 0 ? trim(string(pre_ref)) + '-' : '') + tag_str_ref + '>')), lun=lun
        endif $
        else if(vt eq 'pointer' && ptr_valid(tag_val[0])) then _pretty_print, tag, '<ptr ref' + (noref ? '' : (': ' + (pre_ref gt 0 ? trim(string(pre_ref)) + '-' : '') + trim(string(ptr_valid(tag_val[0], /get_heap_identifier))))) + '>', lun=lun $
        else if(vt eq 'pointer') then _pretty_print, tag, '<null pointer>', lun=lun $
        else _pretty_print, tag, tag_val, lun=lun
      endfor
      
      printf, lun, '}'

      for i = 0L, n_tags(input)-1 do stx_telemetry_print_all, input.(i), lun=lun, file=file, init=init, noref=noref;, curr_ref=ptr_valid(input.(i), /get_heap_identifier)
    endif else $
    if(n_elements(curr_ref) eq 1 && curr_ref gt 0) then _pretty_print, 'ptr ref: ' + (noref ? '' : ((pre_ref gt 0 ? trim(string(pre_ref)) + '-' : '') + trim(string(curr_ref)))), input, lun=lun
  endelse
  
  if(is_init_caller) then free_lun, lun
end