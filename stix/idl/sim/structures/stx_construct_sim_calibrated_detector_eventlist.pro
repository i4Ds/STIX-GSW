;+
; :description:
;   This function constructs a calibrated detector event list for the flight software simulation.
;
; :categories:
;    flight software, constructor, simulation
;
; :keywords:
;    start_time : in, type="stx_time", default="stx_time()"
;                 this is the absolut start time for this calibrated event list; all event entries are relative to this time
;    detector_events : in, type="array of stx_sim_calibrated_detector_event", default="array(1) of stx_sim_calibrated_detector_event"
;                     this is a flat array of instances of stx_sim_calibrated_detector_event
;    sources : in, type="array pf stx_sim_source_structure", default="array(1) of stx_sim_source_structure"
;              this ia flat array of instances of stx_sim_source_structure; allows for multi-source structures
;
; :returns:
;    a stx_sim_calibrated_detector_eventlist structure
;
; :examples:
;    calib_events = stx_construct_sim_calibrated_detector_eventlist(...)
;
; :history:
;     23-jan-2014, Laszlo I. Etesi (FHNW), initial release
;     10-may-2016, Laszlo I. Etesi (FHNW), minor updates to accomodate structure changes
;
;-
function stx_construct_sim_calibrated_detector_eventlist, start_time=start_time, detector_events=detector_events, sources=sources
  eventlist = stx_sim_calibrated_detector_eventlist(no_events=n_elements(detector_events), no_sources=n_elements(sources))
  
  if(keyword_set(start_time)) then eventlist.time_axis = stx_construct_time_axis(stx_time2any(start_time) + [0, detector_events[-1].relative_time])
  if(keyword_set(detector_events)) then eventlist.detector_events = detector_events
  if(keyword_set(sources)) then eventlist.sources = sources
  
  return, eventlist
end