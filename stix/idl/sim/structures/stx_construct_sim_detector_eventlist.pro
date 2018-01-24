;+
;  :description:
;    This function constructs a detector event list for the flight software simulation.
;    Does also support the creation of triggerlists by passing in triggers with detector_events
;
;  :categories:
;    flight software, constructor, simulation
;
;  :keywords:
;    start_time : in, type="stx_time", default="stx_time()"
;                 this is the absolut start time for this calibrated event list; all event entries are relative to this time
;    detector_events : in, type="array of stx_sim_calibrated_detector_event", default="array of stx_sim_calibrated_detector_event or triggers"
;                     this is a flat array of instances of stx_sim_calibrated_detector_event
;                     will also accept 'stx_sim_event_trigger_event' array structure
;    sources : in, type="array pf stx_sim_source_structure", default="array(1) of stx_sim_source_structure"
;              this ia flat array of instances of stx_sim_source_structure; allows for multi-source structures
;
;  :returns:
;    a stx_sim_calibrated_detector_eventlist structure
;
;  :examples:
;    calib_events = stx_construct_sim_calibrated_detector_eventlist(...)
;
;  :history:
;    23-jan-2014, Laszlo I. Etesi (FHNW), initial release
;    10-apr-2014, richard.schwartz@nasa.gov, added capability to put trigger_events in parallel structure
;       by modifying stx_sim_detector_eventlist as well
;    30-oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;    10-may-2016 - Laszlo I. Etesi (FHNW), minor updates to accomodate structure changes
;-
function stx_construct_sim_detector_eventlist, start_time=start_time, end_time=end_time, detector_events=detector_events, sources=sources
  eventlist = stx_sim_detector_eventlist( n_elements(detector_events), no_sources = n_elements(sources), event_struct = detector_events )
  default, start_time, detector_events[0].relative_time
  default, end_time, detector_events[-1].relative_time
  
  eventlist.time_axis = stx_construct_time_axis([stx_time2any(start_time), stx_time2any(end_time)])
  if(keyword_set(detector_events)) then if ~max(stregex( tag_names(eventlist), /boolean, /fold, 'trigger' )) then $
    eventlist.detector_events = detector_events else eventlist.trigger_events = detector_events
  if(keyword_set(sources)) then eventlist.sources = sources
  if(keyword_set(triggers)) then eventlist.triggers = triggers
  
  return, eventlist 
end