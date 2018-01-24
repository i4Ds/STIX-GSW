function stx_ds_result_data, no_events, no_filtered_events, no_triggers, no_sources=no_sources
  result_data = { $
    type : 'stx_ds_result_data', $
    eventlist : stx_sim_detector_eventlist(no_events, no_sources=no_sources), $
    filtered_eventlist : stx_sim_detector_eventlist(no_filtered_events, no_sources=no_sources), $
    triggers : stx_sim_detector_eventlist(no_triggers, event_structure={stx_sim_event_trigger}, no_sources=no_sources), $
    total_source_counts : ulon64arr(32)$ 
    }
    
    return, result_data
end