;+
; :description:
;    Pretty print routine for ppl_error structures.
;    The error message and stack trace is printed to the IDL console window
;    
; :params:
;    ppl_error : in, required, type='ppl_error'
;      a ppl_error structure to print ot the IDL console window
;      
; :categories:
;    utility, error handling, pipeline
;    
; :examples:
;    ppl_print_error, ppl_construct_error(message='test')
;    
; :history:
;    29-Apr-2014 - Laszlo I. Etesi (FHNW), initial release
;    05-Sep-2014 - Laszlo I. Etesi (FHNW), slightly improved output
;-
pro ppl_print_error, ppl_error
  ; do input checking
  ppl_require, type='ppl_error', ppl_error=ppl_error

  ndim = size(ppl_error.stacktrace, /dimensions)
  
  print, ''
  print, '**********************************************************************************************************'
  print, ppl_error.message
  
  if(n_elements(ndim) gt 1) then begin
    for index = 0L, ndim[1]-1 do begin
      print, '% ' + ppl_error.stacktrace[0, index] + ((ppl_error.stacktrace[1, index] eq '') ? '' : ':   ' + ppl_error.stacktrace[1, index] + ' ' + ppl_error.stacktrace[2, index])
    endfor
  endif
  print, '**********************************************************************************************************'
  print, ''
end