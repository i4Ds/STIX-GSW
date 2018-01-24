;+
; :file_comments:
;    This module is part of the Flight Software Simulator Module (FSW) and
;    accumulates all quicklook data.
;
; :categories:
;    Flight Software Simulator, quicklook accumulation, module
;
; :examples:
;    obj = new_obj('stx_fsw_module_ql_accumulation')
;
; :history:
;    28-feb-2014 - Laszlo I. Etesi (FHNW), initial release
;    19-may-2014 - Laszlo I. Etesi (FHNW), integrated actual ql accumulation
;    22-may-2014 - Laszlo I. Etesi (FHNW), returning a structure instead of an array of pointers
;    30-Oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
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
function stx_fsw_module_ql_accumulation::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  self->update_io_data, conf
  
  ; create an empty accumulator
  ql_accumulators = hash()
  
  quicklook_config_struct = (self.lut_data)["quicklook_config_struct"]
  
  for index = 0, n_elements(quicklook_config_struct)-1 do begin
    quicklook_config = quicklook_config_struct[index]
    
    ;exclude the inactive detectors from the definition 
;    det_index_list_old = *quicklook_config.det_index_list
;    det_index_mask = bytarr(32) 
;    det_index_mask[det_index_list_old-1] = 1
;    det_index_mask = det_index_mask AND in.active_detectors
;    
;    det_index_list = where(det_index_mask gt 0)
;    ;detectors count from 1
;    det_index_list++
;    
;    quicklook_config.det_index_list = ptr_new(det_index_list)
;    
;    ;if ~ARRAY_EQUAL(det_index_list_old,det_index_list) then stop
    
    active_detectors = quicklook_config.livetime ? stx_set_active_detectors4ltime(in.active_detectors) : in.active_detectors
    
    result = stx_fsw_eventlist_accumulator(quicklook_config.livetime ? in.triggerlist : in.eventlist, interval_start_time=in.interval_start_time, _extra=quicklook_config, active_detectors=active_detectors)
    
    ;help, result.ACCUMULATED_COUNTS
    
    ql_accumulators["stx_fsw_ql_"+quicklook_config.accumulator] = result
  endfor
  
  return, ql_accumulators
 end

pro stx_fsw_module_ql_accumulation::update_io_data, conf
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
pro stx_fsw_module_ql_accumulation__define
  compile_opt idl2, hidden
  
  void = { stx_fsw_module_ql_accumulation, $
    inherits ppl_module_lut }
end
