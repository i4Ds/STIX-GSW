;+
; :description:
;    Routine to identify current file and routine
;
; :keywords:
;    out_routine : out, optional, type='string'
;      returns the current routine from which this procedure
;      was called
;    out_filename : out, optional, type='string'
;      returns the current file in from which this procedure
;      was called
;      NB: will not return anything if called on $main$
;
; :categories:
;    utility, pipeline, process info
;
; :examples:
;    ppl_state_info, out_routine=out_routine, out_filename=out_filename
;
; :history:
;    05-May-2014 - Laszlo I. Etesi (FHNW), initial release
;-
pro ppl_state_info, out_routine=out_routine, out_filename=out_filename
  help, /traceback, out=trace
  
  ; combine messages that contain line breaks
  wlb_idx = where(trim(trace, 1) ne trace, wlb_count)
  while (wlb_count ne 0) do begin
    trace[wlb_idx[0]-1] = trim(trace[wlb_idx[0]-1])
    trace[wlb_idx[0]-1] += ' ' + trim(trace[wlb_idx[0]], 1)
    trace = trace[where(trace ne trace[wlb_idx[0]])]
    wlb_idx = where(trim(trace, 1) ne trace, wlb_count)
  endwhile
  
  split = strlowcase(trim(strsplit(trace[1], ' ', /extract)))
  
  out_routine=split[1]
  
  if(n_elements(split) ge 4) then out_filename = file_basename(split[3])
end