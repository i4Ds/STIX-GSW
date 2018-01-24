;+
; :file_comments:
;    This module is part of the Data Simulation (DS) package. It filters
;    the input eventlist and removes (but counts) events that occur 
;    to close to one another.
;
; :categories:
;    Data Simulation, filtering, module
;
; :examples:
;    obj = new_obj('stx_ds_module_filter_eventlist')
;
; :history:
;    01-apr-2014 - Laszlo I. Etesi (FHNW), initial release
;    06-May-2014 - Laszlo I. Etesi, removed routines that are inherited from ppl_module
;-

;+
; :description:
;    This internal routine calibrates the accumulator data
;
; :params:
;    in : in, required, type="defined in 'factory function'"
;        this is a stx_sim_source_structure object
;
;    configuration : in, required, type="stx_configuration_manager"
;        this is the configuration manager object containing the
;        configuration parameters for this module
;
; :returns:
;   this function returns a filtered stx_sim_detector_eventlist
;   
; :history:
;   06-May-2014 - Laszlo I. Etesi (FHNW), updated code to return proper data type
;-
function stx_ds_module_filter_eventlist::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  if(~conf.do_filter) then return, in
  
  latency_time = conf.latency_time
  readout_time = conf.readout_time
  
  filtered_events = stx_sim_timefilter_eventlist(in.detector_events, triggers_out=triggers_out, T_L=latency_time, T_R=readout_time)
  filtered_eventlist = stx_construct_sim_detector_eventlist(detector_events=filtered_events, sources=in.sources, start_time=in.start_time)
  trigger_eventlist = stx_construct_sim_detector_eventlist(detector_events=triggers_out, sources=in.sources, start_time=in.start_time)
  return, stx_construct_ds_result_data(eventlist=in, filtered_eventlist=filtered_eventlist, triggers=trigger_eventlist, sources=in.sources)
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
pro stx_ds_module_filter_eventlist__define
  compile_opt idl2, hidden
  
  void = { stx_ds_module_filter_eventlist, $
    inherits ppl_module }
end
