;+
; :file_comments:
;    This module is part of the flight software (FSW) package and
;    updates a list of all valid detectors
;
; :categories:
;    flight software, housekeeping, quicklook accumulated data , module
;
; :examples:
;    obj = stx_fsw_module_detector_monitor()
;
; :history:
;    26-Jun-2014 - Nicky Hochmuth (FHNW), initial release
;    10-May-2016 - Laszlo I. Etesi (FHNW), updated code to work with new structures
;   
;-

;+
; :description:
;    This internal routine updatet the list of valid detectors
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
;   this function returns a validation mask ulong() for the 32 detectors 
;   
; :history:
;   26-Jun-2014 - Nicky Hochmuth (fhnw) 
;-
function stx_fsw_module_detector_monitor::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  flare_flag = in.flare_flag.flare_flag
  ql_accumulator = in.ql_counts
  lt_accumulator = in.lt_counts
  noisy_detectors = in.detector_monitor.noisy_detectors
  active_detectors = (in.detector_monitor.active_detectors)[*,-1]
  
  if(max(active_detectors) gt 1) then stop ; active_detectors eq 1 or active_detectors eq 11
  
  Kbad = conf.Kbad
  Rbad = conf.Rbad
  Nbad = conf.Nbad
  Mbad = conf.Mbad
  mask = conf.mask
  int_time = in.int_time
  trigger_duration = conf.trigger_duration
                                                   
  ; current implementation of this routine requires newest noisy value to be first, therefore -> reverse
  yellow = stx_fsw_detector_failure_identification(ql_accumulator, lt_accumulator, mask, flare_flag, reverse(noisy_detectors, 2), active_detectors, Kbad=Kbad, Rbad=Rbad, Nbad=Nbad, Mbad=Mbad, int_time=int_time, trigger_duration=trigger_duration)

  return, stx_fsw_m_detector_monitor(active_detectors=active_detectors[*,-1], noisy_detectors=yellow[*,0])
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
pro stx_fsw_module_detector_monitor__define
  compile_opt idl2, hidden
  
  void = { stx_fsw_module_detector_monitor, $
    inherits ppl_module }
end
