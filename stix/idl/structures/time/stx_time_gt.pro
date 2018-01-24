;+
; :description:
;    this function checks of the left time is greater than the right time
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
;    print, stx_time_gt(time_l,time_r)
;    
; :history:
;    05-Jul-2014 - Nicky Hochmuth (FHNW), initial release (documentation)
;    
; 
;-
function stx_time_gt, left, right
  return, stx_time_le(right, left)
end

