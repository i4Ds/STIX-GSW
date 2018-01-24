;+
; :description:
;    sorts stx_sim_detector_events by time
;
; :params:
;    stx_sim_detector_events a flat array of stx_sim_detector_event
;
; :returns:
;    a flat array of stx_sim_detector_event in time order
;
; :history: 
;   24-feb-2014, nicky.hochmuth@fhnw.ch , initial release
;   19-aug-2014, Laszlo I. Etesi (FHNW), using bsort instead of sort
;-
function stx_sim_timeorder_eventlist, stx_sim_detector_events
    return, stx_sim_detector_events[bsort(stx_sim_detector_events.relative_time)]
end