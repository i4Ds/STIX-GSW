;+
; :file_comments:
;    This module is part of the Flight Software Simulator Module (FSW)
;    "Calibrate Event Binning Module".
;
; :categories:
;    Flight Software Simulaton, accumulator calibration, module
;
; :examples:
;    obj = new_obj('stx_fsw_module_calibrate_accumulators__define')
;
; :history:
;    25-feb-2014 - Laszlo I. Etesi (FHNW), initial release
;    26-May-2015 - Laszlo I. Etesi (FHNW), updated to handle new calibration spectrum routine
;    30-Jul-2015 - Laszlo I. Etesi (FHNW), using new parameters active_detectors and exclude_bad_detectors
;    30-Oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;    16-Dec-2015 - Laszlo I. Etesi (FHNW), added TS to configuration and passing it in
;    10-May-2016 - Laszlo I. Etesi (FHNW), minor renaming of variable
;-

;+
; :description:
;    This internal routine calibrates the accumulator data
;
; :params:
;    in : in, required, type="defined in 'factory function'"
;        this is a stx_sim_detector_eventlist object
;         
;    configuration : in, required, type="stx_configuration_manager"
;        this is the configuration manager object containing the 
;        configuration parameters for this module
;
; :returns:
;   this function returns an intarr(32, 12, 1024) containing the 
;   accumulated calibration spectra
;-
function stx_fsw_module_accumulate_calibration_spectrum::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  ; extract optional parameters
  tq = conf.tq
  active_detectors = conf.active_detectors
  exclude_bad_detectors = conf.exclude_bad_detectors
  ts = conf.ts
  t_bin_width = 4.d
  
  spectrum = in.previous_calibration_spectrum
  eventlist = in.eventlist.detector_events
  
  stx_fsw_accumulation_of_calibration_spectrum, eventlist,calibration_spectrum=spectrum, tq=tq, ts=ts, t_bin_width=t_bin_width, active_detectors=active_detectors, exclude_bad_detectors=exclude_bad_detectors 
  
  return, spectrum
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
pro stx_fsw_module_accumulate_calibration_spectrum__define
  compile_opt idl2, hidden
  
  void = { stx_fsw_module_accumulate_calibration_spectrum, $
    inherits ppl_module }
end
