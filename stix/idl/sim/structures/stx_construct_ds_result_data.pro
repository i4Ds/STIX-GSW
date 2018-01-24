;+
; :description:
;    Construct a data simulation result data package (containing the event list,
;    filtered event list, and trigger event list)
;
; :categories:
;    construction, data simulation, event list
;
; :keywords:
;    channel_bin_use : in, optional, type='intarr()', default='undefined'
;      an int array of energies (energy axis); required for quicklook accumulators, optional for livetime accumulators
;    is_trigger_event : in, optional, type='boolean', default=0
;      if set to 1 it indicates that the type to create is a livetime accumulator, or a quicklook accumulator otherwise
;      
; :returns:
;    stx_fsw_ql_XXX or stx_fsw_ql_XXX_lt structure
;
; :history:
;    22-May-2014 - Laszlo I. Etesi (FHNW), initial release
;-
function stx_construct_ds_result_data, sources=sources, eventlist=eventlist, triggers=triggers, filtered_eventlist=filtered_eventlist, total_source_counts=total_source_counts

  
  result_data = stx_ds_result_data(n_elements(eventlist.detector_events), n_elements(filtered_eventlist.detector_events), n_elements(triggers.trigger_events), no_sources=n_elements(sources))
  if(keyword_set(eventlist)) then result_data.eventlist = eventlist
  if(keyword_set(filtered_eventlist)) then result_data.filtered_eventlist = filtered_eventlist
  if(keyword_set(triggers)) then result_data.triggers = triggers
  if(keyword_set(total_source_counts)) then result_data.total_source_counts = total_source_counts
   
  return, result_data
end