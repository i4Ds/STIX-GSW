;+
; :description:
;    this function add two stix_times or a given timespan in seconds
;
; :categories:
;    STIX, time
;
; :params:
;    old_time       : in, required, type='stx_time'
;                     the left time to add
;                      
; :keywords:
;    add_time       : in, optional, type='stx_time'
;                     the right time to add
;                       
;    seconds        : in, optional, type='double'
;                     a time span to add
;                                            
; :returns:
;   a new stx_time struct with the added time value                
;                     
; :examples:
;    time = stx_construct_time(time="2002-12-12:14:00")
;    ptim, stx_time2any(time), stx_time2any(stx_time_add(time,seconds=60))
;    
; :history:
;    05-Jul-2014 - Nicky Hochmuth (FHNW), initial release (documentation)
;    10-May-2016 - Laszlo I. Etesi (FHNW), spell check
;    
; 
;-
function stx_time_add, old_time, add_time=add_time, seconds = seconds
  if ~ppl_typeof(old_time,compareto='stx_time',/raw) then return, 0
  
  current_time = stx_time2any(old_time)
  add_seconds = (ppl_typeof(add_time, compareto='stx_time') ? stx_time2any(add_time) : seconds)
 
  new_time = stx_construct_time(time=current_time+add_seconds)
  
  return, new_time
end
