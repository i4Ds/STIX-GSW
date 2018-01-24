;+
; :description:
;    this function searches for timepoints on a given time axis
;
; :categories:
;    STIX, time
;
; :params:
;    time_axis      : in, required, type='stx_time_axis'
;                     the time axis to lacate the time point on
;                     
;    times          : in, required, type='stx_time'
;                     scalar or array of time points 
; :returns:
;   a scalar or array of corresponding indices on the time axis where the time points was found
;   index value -1 for not found                
;                     
; :examples:
;    time_axis = stx_construct_time_axis(findgen(100))
;    time = stx_construct_time(time=40.6)  
;    i = stx_time_locate(time_axis,time) 
;    ptim, time_axis.time_start[i].value,time_axis.time_end[i].value
;    
; :history:
;    05-Jul-2014 - Nicky Hochmuth (FHNW), initial release (documentation)
;    
; :todo:
;    speed up the search
;-
function stx_time_locate, time_axis, times

  ppl_require, in=times, type='stx_time*'
  ppl_require, in=time_axis, type='stx_time_axis'
  
  result=lon64arr(n_elements(times))
  
  
  ;todo: N.H. speed that up
  foreach time, times, i do result[i] = min(where(stx_time_ge(time,time_axis.time_start) AND  stx_time_le(time,time_axis.time_end)))
  
   ;utplot, time_axis.time_start.value, time_axis.duration, yrange=[0,5], psym=1 
   ;outplot, times.value, replicate(2,n_elements(times)), psym=2  
  
  return, result
end