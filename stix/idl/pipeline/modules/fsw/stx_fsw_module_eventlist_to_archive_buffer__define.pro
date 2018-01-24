;+
; :file_comments:
;    This module is part of the Flight Software Simulator Module (FSW) and
;    constructs archive buffer entries using calibrated detector event list data.
;
; :categories:
;    Flight Software Simulator, archive buffer, module
;
; :examples:
;    obj = stx_fsw_module_eventlist_to_archive_buffer()
;
; :history:
;    05-Jul-2014 - Nicky Hochmuth (FHNW), initial release
;    07-Jul-2015 - Laszlo I. Etesi (FHNW), - bugfixing: checking if there are leftovers (failsafe)
;                                          - allowing to pass in the parameter 'close_last_time_bin' using the input variable
;                                          - removed has_leftover and now using leftover tag
;    24-Sep-2015 - Mel Byrne (TCD), adjusted call to stx_sim_eventlist2archive
;    06-Oct-2015 - Laszlo I. Etesi (FHNW), added m_channel as config input to the accumulation module
;    30-Oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;    10-May-2016 - Laszlo I. Etesi (FHNW), updated structure type names
;    07-Jun-2016 - Laszlo I. Etesi (FHNW), using new archive buffer accumulator routine
;    20-Jun-2016 - Laszlo I. Etesi (FHNW), bugfix: incorrect return type of leftovers in case of no leftovers (new: calibrated det event)
;    06-Mar-2017 - Laszlo I. Etesi (FHNW), added failsafe in case emtpy list is inserted
;
;  :todo:
;     n.h. bring consitency into timing: the reletive time for this module is im ms
;-

;+
; :description:
;    This internal routine accumulate the event list into the archive buffer format
;    the archive buffer format
;
; :params:
;    in : in, required, type="defined in 'factory function'"
;        this is a stx_sim_calibrated_detector_eventlist object
;
;    configuration : in, required, type="stx_configuration_manager"
;        this is the configuration manager object containing the
;        configuration parameters for this module
;
; :returns:
;   this function returns a stx_sim_archive_buffer
;-
function stx_fsw_module_eventlist_to_archive_buffer::_execute, in, configuration
  compile_opt hidden

  conf = *configuration->get(module=self.module)

  ; copy out input data
  events = in.eventlist
  start_time = long(in.starttime)
  close_last_time_bin = in.close_last_time_bin

  ; leftover detector event with relativ_time -1 means EMPTY
  if(in.leftovers[0].relative_time ge 0) then events = ppl_replace_tag(events, "detector_events", [in.leftovers, events.detector_events])

  ; prepare active detectors
  active_detectors = conf.m_acc and in.detector_monitor.active_detectors

  next_event = ulong64(0)

  ; accumulate archive buffer ; stx_fsw_evl2archive stx_sim_eventlist2archive
  if(events.detector_events[0].relative_time ne -1) then begin
    ab = stx_fsw_evl2archive(events, start_time, next_event, m_acc=active_detectors, $
      n_min=conf.n_min, t_max=conf.t_max, t_min=long(conf.t_min*10), close_last_time_bin=close_last_time_bin, $
      m_channel=conf.m_channel)
  endif

  ; test if archive buffer is a valid object
  ; if so, update certain fields, otherwise return 'null' value
  if(ppl_typeof(ab, compareto='stx_fsw_archive_buffer', /raw)) then begin
    ab_time = round(ab.relative_time_range * 10)/10d
    ab.relative_time_range = ab_time
    
    ; read out number of ab entries
    n_archive_buffer = n_elements(ab)

    ; create time axes
    time_edges = ab.relative_time_range
    time_edges = reform(time_edges, 2 * n_archive_buffer)
    time_edges = time_edges[uniq(time_edges, bsort(time_edges))]
    time_edges = time_edges[0:-2]
    
    ; read out number of time exges
    n_t = n_elements(time_edges)

    total_counts = ulon64arr(n_t)
    t_idx = n_t gt 1 ?  value_locate(time_edges, ab.relative_time_range[0,*]) : bytarr(n_archive_buffer)
    
    for i=ulong64(0), n_archive_buffer-1 do total_counts[t_idx[i]] += ab[i].counts
  end else begin
    ; no bins have been created
    ab = 0
    n_archive_buffer = 0
    total_counts = 0
    time_edges = 0
  end

  ; need to check if there are any more possible counts left (failover)
  if(next_event ne -1) then leftover = events.detector_events[next_event:-1] $
  else leftover = stx_sim_calibrated_detector_event()

  ab_result = { $
    type                : "stx_eventlist_to_archive_buffer_result", $
    archive_buffer      : ab, $
    n_entries           : n_archive_buffer, $
    starttime           : start_time, $
    leftovers           : leftover, $
    total_counts        : total_counts, $
    total_counts_times  : time_edges $
  }

  return, ab_result

end

;+
; :description:
;    Constructor
;
; :inherits:
;    hsp_module
;
; :hidden:
;-
pro stx_fsw_module_eventlist_to_archive_buffer__define
  compile_opt idl2, hidden

  void = { stx_fsw_module_eventlist_to_archive_buffer, $
    inherits ppl_module }
end
