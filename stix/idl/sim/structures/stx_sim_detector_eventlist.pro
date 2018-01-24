;+
;  :description:
;    This function creates an uninitialized detector event list structure for the flight software simulation.
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
;    no_triggers : in, type="uint", default="n/a"
;      number of triggers
;      
;    event_structure : (optional), if provided this structure is used as the constructor type for the event words
;
;  :returns:
;    an uninitialized stx_sim_detector_eventlist structure
;
;  :examples:
;    det_eventlist = stx_sim_detector_eventlist()
;
;  :history:
;    23-jan-2014 - Laszlo I. Etesi (FHNW), initial release
;    10-apr-2014 - richard.schwartz@nasa.gov, added event_structure keyword for 
;       added flexibility
;    22-apr-2014 - richard.schwartz@nasa.gov, changed type tag value to lowercase
;    05-may-2014 - Laszlo I. Etesi (FHNW), added failsave if no_sources = 0
;    28-jul-2014 - Laszlo I. Etesi (FHNW), using new __define for named structures
;    30-oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;    10-may-2016 - Laszlo I. Etesi (FHNW), minor updates to accomodate structure changes
;-
function stx_sim_detector_eventlist, no_events, no_sources=no_sources, event_structure=event_structure, time_axis=time_axis
  default, no_sources, 1
  default, event_structure, {stx_sim_detector_event}
  default, time_axis, stx_construct_time_axis([0,1])
  
  struct_name = tag_names( /struct, event_structure )
  empty_struct = create_struct( name = struct_name )
  is_trigger = stregex(/boolean, /fold, struct_name, 'trigger' )
  ret = ~is_trigger ? { type:strlowcase( struct_name + 'LIST' ), $
            time_axis: time_axis, $
            sources: replicate(stx_sim_source_structure(), max([no_sources, 1])), $
            detector_events: replicate( empty_struct, no_events) $
          } $
          : $
          { type:strlowcase( struct_name + 'LIST'), $
            time_axis: time_axis, $
            sources: replicate(stx_sim_source_structure(), max([no_sources, 1])), $
            trigger_events: replicate( empty_struct, no_events) $
            }
  return, ret
end