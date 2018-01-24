;+
; :Description:
;    Describe the procedure.
;
; :Params:
;    rate - event rate for imaging detectors in events per second, default, 1e3
;
; :Keywords:
;    duration - double precision time array of integration time intervals (seconds)
;         default, duration, dindgen( 20 ) / 5.0 + 1.0
;
; :Author:
;   richard.schwartz@nasa.gov
; :History:
;   
;   18-april-2015, richard.schwartz@nasa.gov

;-
function stx_triggergram_construction_4test, rate, duration = duration
  default, duration, dindgen( 20 ) / 5.0 + 1.0
  ntbin = n_elements( duration ) 
  default, rate, 1e3
  
  time_axis = stx_construct_time_axis([0, total( duration, /cum)])
  ntbin = n_elements( duration )
  ratem = rate+fltarr(32)
  
  det_select = (stx_vis()).isc  ;imaging subcollimators
  all_det    = indgen( 32 ) + 1
  nofourier  = all_det [ where_arr( all_det, det_select, /notequal) ]
  ratem[ nofourier-1 ] = 0 ;very small rates in the background and flare location detectors
  eventm = ratem # duration
  
  
  events = poidev( eventm ) ;ordered
  ndet = n_elements( det_select )
  ;build the 16 trigger values from events
  trigger = lonarr( 16, ntbin )
  ixpair = stx_ltpair_assignment( /pairs ) -1 ;det_index (0:31) of components of each trigger
  for i = 0, 15 do trigger[i,0] = transpose(  total( events[ ixpair[*,i], * ], 1) )
  
  triggergram = stx_triggergram( trigger, time_axis )
  return, triggergram
  end
  