;+
; :file_comments:
;    This module is part of the Flight Software Simulator Module (FSW) and
;    accumulates the trigger counts according to the time binning of the achrive buffer entries
;
; :categories:
;    Flight Software Simulator, archive buffer, livetime, module
;
; :examples:
;    obj = stx_fsw_module_triggerlist_to_livetime()
;
; :history:
;    09-Sep-2014 - Nicky Hochmuth (FHNW), initial release
;    07-Jul-2014 - Laszlo I. Etesi (FHNW), changes to accomodate removal of has_leftovers
;    22-Dec-2015 - Laszlo I. Etesi (FHNW), cosmetic changes
;    09-May-2016 - Laszlo I. Etesi (FHNW), introduced a quick fix to avoid floating point errors in time
;    10-May-2016 - Laszlo I. Etesi (FHNW), updated structure uses
;    07-Jun-2016 - Laszlo I. Etesi (FHNW), making sure the correct data type is returned in case of no trigger leftovers
;-

;+
; :description:
;    This internal routine accumulates all triggers according to the time binning of the achrive buffer entries  
;    for the livetime
;
; :params:
;    in : in, required, type="defined in 'factory function'"
;         
;    configuration : in, required, type="stx_configuration_manager"
;        this is the configuration manager object containing the 
;        configuration parameters for this module
;
; :returns:
;   this function returns a time bined trigger list
;-
function stx_fsw_module_triggerlist_to_livetime::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  triggers = in.triggers
  if(in.leftovers[0].relative_time ge 0)then triggers = ppl_replace_tag(triggers, "trigger_events", [in.leftovers, triggers.trigger_events])
  
  ;trim trigger list
  current_triggers = where(triggers.trigger_events.relative_time ge in.starttime AND triggers.trigger_events.relative_time lt in.endtime, count_current_triggers)
  ;new leftovers 
  new_leftovers = where(triggers.trigger_events.relative_time gt in.endtime, count_newleftovers)
  if(count_newleftovers gt 0) then new_leftovers = triggers.trigger_events[new_leftovers] $
  else new_leftovers = stx_sim_event_trigger()
  
  if count_current_triggers gt 0 then triggers = ppl_replace_tag(triggers, "trigger_events", triggers.trigger_events[current_triggers])
  ; quick fix to avoid floating point errors
   
  livetime = stx_fsw_eventlist_accumulator(triggers, livetime=1, time_bin = stx_time_add(triggers.time_axis.time_start, seconds=[in.timing, in.endtime]), accumulator="ab_livetime", det_index_list=conf.det_index_list, sum_det=conf.sum_det, /no_prefix, /a2d_only  )  
   
  livetime_arr = uint(reform(livetime.accumulated_counts))
  times = n_elements(in.timing)
  livetime_list = list()
  for t=0L, times-1 do livetime_list->add, livetime_arr[*,t], /no_copy
  
  new_triggers = livetime_list->toarray()
  dim_triggers = size(new_triggers, /dimensions)
  triggers_struct = replicate({stx_fsw_triggers}, dim_triggers[0])
  for tidx = 0L, dim_triggers[0]-1 do begin
    triggers_struct[tidx].relative_time_range = [stx_time2any(livetime.time_axis.time_start[tidx]), stx_time2any(livetime.time_axis.time_end[tidx])]
    triggers_struct[tidx].triggers = new_triggers[tidx, *]
  endfor

  ; TODO merge ab accumulation + trigger calculation
 
  return, { $
    type                : "stx_triggerlist_to_livetime_result", $
    triggers            : triggers_struct, $
    times               : livetime.time_axis, $
    leftovers           : new_leftovers $
  }
  
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
pro stx_fsw_module_triggerlist_to_livetime__define
  compile_opt idl2, hidden
  
  void = { stx_fsw_module_triggerlist_to_livetime, $
    inherits ppl_module }
end
