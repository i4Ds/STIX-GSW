;+
; :file_comments:
;    This module is part of the Data Simulation (DS) package. It applies the time
;    and energy profiles and tests if a photon hits a detector.
;
; :categories:
;    Data Simulation, photon simulation, module
;
; :examples:
;    obj = new_obj('stx_ds_module_photon_detection_test')
;
; :history:
;    01-Apr-2014 - Laszlo I. Etesi (FHNW), initial release
;    06-May-2014 - Laszlo I. Etesi, removed routines that are inherited from ppl_module
;    28-Jul-2014 - Laszlo I. Etesi, using new __define for named structures
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
;   this function returns an array of stx_sim_photon_structure
;-
function stx_ds_module_photon_detection_test::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  time_order_photon_list = conf.time_order_photon_list
  ;start_time = conf.start_time
  
  ph_hits = stx_sim_energyfilter(in.events)
  
  ; transform the input photons into detector events
  events = replicate({stx_sim_detector_event}, n_elements(ph_hits))
  events.relative_time = ph_hits.time
  events.detector_index = ph_hits.subc_d_n
  events.pixel_index = ph_hits.pixel_n
  events.energy_ad_channel = stx_sim_energy2ad_channel(ph_hits.energy)
  
  ; sort event list if desired
  if(time_order_photon_list) then return, stx_construct_sim_detector_eventlist(detector_events=stx_sim_timeorder_eventlist(events), source=in.source, start_time=in.start_time) $
  else return, stx_construct_sim_detector_eventlist(detector_events=events, source=in.source, start_time=in.start_time)
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
pro stx_ds_module_photon_detection_test__define
  compile_opt idl2, hidden
  
  void = { stx_ds_module_photon_detection_test, $
    inherits ppl_module }
end
