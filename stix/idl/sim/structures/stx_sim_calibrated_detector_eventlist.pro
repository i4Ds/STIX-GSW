;+
;  :description:
;    This function creates an uninitialized calibrated detector event structure for the flight software simulation.
;
;  :categories:
;    flight software, structure definition, simulation
;    
;  :keywords:
;    no_events : in, type="ulong", default="n/a"
;      number of simulated detector events
;      
;    no_sources : in, type="uint", default="1"
;      number of sources in this calibrated event list (1 for single source, n for multi-source simulation)
;
;  :returns:
;    an uninitialized stx_sim_calibrated_detector_eventlist structure
;
;  :examples:
;    calib_det_eventlist = stx_sim_calibrated_detector_eventlist()
;
;  :history:
;    23-jan-2014 - Laszlo I. Etesi (FHNW), initial release
;    22-jul-2015 - Laszlo I. Etesi (FHNW), small bugfix: ensuring that no_sources is ge 1
;    30-oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;    10-may-2016 - Laszlo I. Etesi (FHNW), minor updates to accomodate structure changes
;
;-
function stx_sim_calibrated_detector_eventlist, no_events=no_events, no_sources=no_sources, time_axis=time_axis
  if(~keyword_set(no_events)) then message, 'Please specify the number of events'
  
  ; make sure the default source number is 1
  default, no_sources, 1
  no_sources = no_sources > 1
  
  default, time_axis, stx_construct_time_axis([0,1])
  
  return, { type: 'stx_sim_calibrated_detector_eventlist', $
            time_axis: time_axis, $
            sources: replicate(stx_sim_source_structure(), no_sources), $
            detector_events: replicate(stx_sim_calibrated_detector_event(), no_events) $
          }
end