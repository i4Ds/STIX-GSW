;+
; :description:
;    this function appends to stx time axis
;
; :categories:
;    STIX, time
;
; :params:
;    left           : in, required, type='stx_time'
;                     the main time axis to append on
;    right          : in, required, type='stx_time'
;                     the tail of the new axis
;                     
; :keywords:
;    checkconsistent: in, optional, type='flag[0/1]'
;                     if set a check is performed to test if both time axes do not overlap                                            
; :returns:
;   a new stx_time_axis as concatinatio of both given ones                
;                     
; :examples:
;    time_axis_l = stx_construct_time_axis(findgen(10))
;    time_axis_r = stx_construct_time_axis(findgen(10)+20)
;    ptim, stx_time2any((stx_time_axis_append(time_axis_l, time_axis_r)).time_start)
;    
; :history:
;    05-Jul-2014 - Nicky Hochmuth (FHNW), initial release (documentation)
;    
; 
;-
function stx_time_axis_append, left , right, checkconsistent=checkconsistent
  
  ppl_require, in=left, type='stx_time_axis'
  ppl_require, in=right, type='stx_time_axis'
   
  if keyword_set(checkconsistent) then assert_true, stx_time_le(left.time_end[-1], right.time_start[0]) 

  time_axis = stx_time_axis(n_elements(left.duration)+n_elements(right.duration))
  time_axis.time_start  = [left.time_start, right.time_start]
  time_axis.time_end    = [left.time_end ,right.time_end]
  time_axis.mean        = [left.mean, right.mean]
  time_axis.duration    = [left.duration, right.duration]
  
  return, time_axis
end
