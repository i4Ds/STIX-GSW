;+
; :description:
;    This illustrates the results of the stx_sim_timefilter_eventlist
;
; :categories:
;    flight software simultaion, plotting
;
; :params:
;    events : in, required, type="stx_sim_detector_event"
;             the time orderd detector events
;             
;    filteredevents : in, required, type="stx_sim_detector_event" 
;             the filtered time orderd detector events
;    
;    trigger : in, required, type="stx_sim_event_trigger"
;             the generated triggers by the filtering
;             
; :keywords:
;    T_L :         in, type="double", optional, default="2 microseconds"
;                  the latency time for the detector coincidence time filtering
;                   
;    T_R :         in, type="double", optional, default="10 microseconds"
;                  the read out time for the detector coincidence time filtering
;    
;    timerange : in and out, type="double(2)", optional, default:  [0d,0.05d]
;               the time range for plotting
;               the timerange is shifted after the plotting and passd out for the next plot call
;    
;    adgroup : in, type="uint", required
;               the analog digital converter unit group
;               
; :examples:
;    restore, filename="stx_sim_detector_eventlist.sav", /ver
;    filteredlist = stx_sim_timefilter_eventlist(list.detector_events, triggers_out=triggers_out, T_L=T_L, T_R=T_R)
;    timerange=[0.13700000d,0.13800000]+(0.13700000d - 0.13800000)
;    stx_sim_timefilter_eventlist_plot, list.detector_events, filteredlist, triggers_out, T_L=T_L, T_R=T_R, timerange=timerange
;
; :history:
;    27-Feb-2014 - Nicky Hochmuth (FHNW), initial release
;
;-
pro stx_sim_timefilter_eventlist_plot, events, filteredevents, trigger, timerange=timerange, T_L=T_L, T_R=T_R, adgroup=adgroup
  default, timerange, [0d,0.05d]
  default, adgroup, 1
  
  
  timerange = double(timerange)
  
  n_events = n_elements(events)
  
  hsi_linecolors

  group_idx_event = where(stx_sim_detectoridx2adgroup(events.detector_index) eq adgroup)
  group_idx_filterdevent = where(stx_sim_detectoridx2adgroup(filteredevents.detector_index) eq adgroup)
  group_idx_trigger = where(trigger.adgroup_index eq adgroup)
  
  n_trigger = n_elements(group_idx_trigger)
  
  plot, events.relative_time, replicate(0,n_events), xrange=timerange, yrange=[0,17], /nodata, /ystyle, /xstyle  
  
  xt = reform([transpose(trigger[group_idx_trigger].relative_time),transpose(trigger[group_idx_trigger].relative_time),transpose(trigger[group_idx_trigger].relative_time)],3 * n_trigger)
  yt = reform([transpose(replicate(-1,n_trigger)),transpose(replicate(20,n_trigger)), transpose(replicate(-1, n_trigger))], 3 * n_trigger)
  oplot, xt, yt, psym=10, color=4, linestyle=2
  oplot, events[group_idx_event].relative_time, events[group_idx_event].pixel_index,  psym=2, color=1 
  
  oplot, [timerange[0],timerange[0]+T_L], [6,6], color=5, thick=3
  oplot, [timerange[0]+T_L,timerange[0]+T_L+T_R], [6,6], color=6, thick=3
    
  oplot, filteredevents[group_idx_filterdevent].relative_time, filteredevents[group_idx_filterdevent].pixel_index+0.2,  psym=2, color=3
  
  
  
  timerange += (timerange[1]-timerange[0])
end  
  