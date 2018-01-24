;+
; :description:
;    Construct a ppl_error structure based on user input or 'help, /traceback, out=message'
;
; :keywords:
;    message : in, optional, type='string', default='n/a'
;              the message associated with this error (can be anything);
;              if 'parse' is set to 1, 'message' is expected to be the output
;              of 'help, /traceback, out=message'
;    idl_error_state : in, optional, type='{ERROR_STATE}', default='!ERROR_STATE'
;              the IDL error state structure
;    stacktrace : in, optional, type='string', default='n/a'
;              an IDL stacktrace e.g. generated with 'help, /traceback, out=stacktrace'.
;    parse : in, optional, type='int', default='undefined'
;              if set it will cause this routine to try and extract the stacktrace 
;              information from 'message' into 'stacktrace'. 
;
; :returns:
;    a ppl_error structure
;
; :categories:
;    utility, error handling, pipeline
;
; :examples:
;    help, /traceback, out=message
;    ppl_print_error, ppl_construct_error(message=message)
;
; :history:
;    29-Apr-2014 - Laszlo I. Etesi (FHNW), initial release
;    05-Sep-2014 - Laszlo I. Etesi (FHNW), fixed a bug that caused an error a) on small screens or b) with long error messages (line breaks in message)
;-

function ppl_construct_error, message=message, idl_error_state=idl_error_state, stacktrace=stacktrace, parse=parse
  default, message, 'n/a'
  default, idl_error_state, !ERROR_STATE
  
  if(keyword_set(stacktrace) && keyword_set(parse)) then message, "Either keyword 'stacktrace' or 'parse' can be set."
  
  default, stacktrace, 'n/a'
  
  if(keyword_set(parse) && n_elements(message) gt 1) then begin
    ; copy and clean message    
    last_message = message
    
    ; combine messages that contain line breaks
    wlb_idx = where(trim(last_message, 1) ne last_message, wlb_count)
    while (wlb_count ne 0) do begin
      last_message[wlb_idx[0]-1] = trim(last_message[wlb_idx[0]-1])
      last_message[wlb_idx[0]-1] += ' ' + trim(last_message[wlb_idx[0]], 1)
      last_message = last_message[where(last_message ne last_message[wlb_idx[0]])]
      wlb_idx = where(trim(last_message, 1) ne last_message, wlb_count)
    endwhile
    
    last_message = str_replace(last_message, '%', '')
    last_message = str_replace(last_message, ' Execution halted at:', '')
    last_message = trim(last_message)
    
    ; extract message
    local_message = last_message[0]
    
    ; extract stacktrace
    stacktrace = strarr(3, n_elements(last_message) - 1)
    for index = 1L, n_elements(last_message)-1 do begin
      extract = strsplit(last_message[index], ' ', /extract)
      idx = min([(size(stacktrace))[0],n_elements(extract)-1])
      stacktrace[0:idx,index-1] = extract[0:idx]
    endfor
    
  endif else local_message = message
  
  new_ppl_error = { $
    type : 'ppl_error', $
    message : local_message, $
    idl_error_state : idl_error_state, $
    stacktrace : stacktrace $
    }
    
  return, new_ppl_error
end