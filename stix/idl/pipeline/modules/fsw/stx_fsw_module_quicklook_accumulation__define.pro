;+
; :file_comments:
;    This module is part of the Flight Software Simulator Module (FSW) and
;    accumulates all quicklook data.
;
; :categories:
;    Flight Software Simulator, quicklook accumulation, module
;
; :examples:
;    obj = new_obj('stx_fsw_module_quicklook_accumulation')
;
; :history:
;    28-feb-2014 - Laszlo I. Etesi (FHNW), initial release
;    19-may-2014 - Laszlo I. Etesi (FHNW), integrated actual ql accumulation
;    22-may-2014 - Laszlo I. Etesi (FHNW), returning a structure instead of an array of pointers
;    30-Oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;    06-Mar-2017 - Laszlo I. Etesi (FHNW), live time (that is "triggers") only have 16 groups not 32; reducing output from 32 to 16
;-

;+
; :description:
;    This internal routine converts the calibrated detector event list to 
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
;   this function returns a stx_fsw_ql_accumulators structure
;-
function stx_fsw_module_quicklook_accumulation::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  if(max(in.detector_monitor.active_detectors) gt 1) then stop ; active_detectors eq 1 or active_detectors eq 11 $ ; <- don't really know why, but that's how it was before in the call to this module
  
  self->update_io_data, conf
  
  ; create an empty accumulator
  ql_accumulators = hash()
  
  quicklook_config_struct = (self.lut_data)["quicklook_config_struct"]
  
  for index = 0, n_elements(quicklook_config_struct)-1 do begin
    quicklook_config = quicklook_config_struct[index]
    
    active_detectors = quicklook_config.livetime ? stx_set_active_detectors4ltime(in.detector_monitor.active_detectors) : in.detector_monitor.active_detectors
    
    if(quicklook_config.livetime) then quicklook_config = add_tag(quicklook_config, 1, 'a2d_only')
    
    result = stx_fsw_eventlist_accumulator(quicklook_config.livetime ? in.triggerlist : in.eventlist, interval_start_time=in.interval_start_time, _extra=quicklook_config, active_detectors=active_detectors)
    
    ;help, result.ACCUMULATED_COUNTS
    
    ql_accumulators['stx_fsw_ql_' + quicklook_config.accumulator] = result
  endfor
  
  return, ql_accumulators
 end

pro stx_fsw_module_quicklook_accumulation::update_io_data, conf
    ;read the thermal boundary LUT
    
  if self->is_invalid_config("accumulator_definition_file", conf.accumulator_definition_file) then begin  
    (self.lut_data)["quicklook_config_struct"] = stx_fsw_ql_accumulator_table2struct(conf.accumulator_definition_file)
  end
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
pro stx_fsw_module_quicklook_accumulation__define
  compile_opt idl2, hidden
  
  void = { stx_fsw_module_quicklook_accumulation, $
    inherits ppl_module_lut }
end
