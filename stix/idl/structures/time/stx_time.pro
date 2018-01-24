;+
; :description:
;    a abstraction type for a time in the stix analysys software
;
; :categories:
;    STIX, time
;   
; :returns:
;   a anonymous time struct
;   the default time is set to 79/01/01
;
;                     
; :examples:
;    time = stx_time()
;    ptim, stx_time2any(time)
;    
; :history:
;    01-May-2013 - Nicky Hochmuth (FHNW), initial release (documentation)
;    08-Oct-2015 - Laszlo I. Etesi (FHNW), changed initial mjd value to 0, so it can be tested for "not initialized"
; 
;-
function stx_time
  t = {stx_time}
  t.value.mjd = 0L ; changed to 0, so it can be tested for "not initialized"
  return, t
end