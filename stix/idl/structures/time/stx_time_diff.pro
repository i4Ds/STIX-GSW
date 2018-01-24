;+
; :description:
;    this function calculates to time span in seconds between two given times
;    performs: left - right in seconds
;
; :categories:
;    STIX, time
;
; :params:
;    left           : in, required, type='stx_time'
;                     the left time point
;    right          : in, required, type='stx_time'
;                     the right time point
;   
; :keywords:
;    abs            : in, optional, type='flag[0|1]'
;                     the time differnece is set to its absolute value                                              
; :returns:
;   the amount of seconds between left and right as double value
;   as absolute value if set so
;                     
; :examples:
;    time_l = stx_construct_time(time='2012-12-12 5:00')
;    time_r = stx_construct_time(time='2012-12-12 6:00')
;    print, stx_time_diff(time_l,time_r,/abs)
;    
; :history:
;    05-Jul-2014 - Nicky Hochmuth (FHNW), initial release (documentation)
;    
; 
;-
function stx_time_diff, left, right, abs=abs
  if ~ppl_typeof(left,compareto="stx_time",/raw) || ~ppl_typeof(right,compareto="stx_time",/raw) then return, 0
  duration = anytim(left.value)-anytim(right.value)
  return, keyword_set(abs) ? abs(duration) : duration
end
