;+
; :description:
;    this function checks of the left time is lover or equal than the right time
;
; :categories:
;    STIX, time, comparison
;
; :params:
;    left           : in, required, type='stx_time'
;                     the scalar or array of times
;    right          : in, required, type='stx_time'
;                     the scalar or array of times
;   
; :returns:
;   true or false as a scalar or vector depending on the imput
;
;                     
; :examples:
;    time_l = stx_construct_time(time='2012-12-12 5:00')
;    time_r = stx_construct_time(time='2012-12-12 6:00')
;    print, stx_time_le(time_l,time_r)
;    
; :history:
;    05-Jul-2014 - Nicky Hochmuth (FHNW), initial release (documentation)
;    
; 
;-
function stx_time_le, left, right
  if ~ppl_typeof(left,compareto="stx_time",/raw) || ~ppl_typeof(right,compareto="stx_time",/raw) then return, 0
  return, left.value.MJD lt right.value.MJD OR (left.value.MJD eq right.value.MJD AND left.value.TIME le right.value.TIME) 
end

