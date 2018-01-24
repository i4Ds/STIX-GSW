;+
; :description:
;   This function constructs a detector event for the flight software simulation.
;
; :categories:
;    flight software, constructor, simulation
;
; :keywords:
;   relative_time : in, type='dblarr', default='0d'
;     this is the relative time range in ms (start time); relative to the start_time in stx_sim_calibrated_detector_eventlist
;    
;   detector_index : in, type='byte', default='0b'
;     detector index [0,31]
;   
;   pixel_index : in, type='byte', default='0b'
;     pixel index [0,12], 12 is used for trigger
;   
;   energy_ad_channel : in, type='uint', default='uint(0)'
;     energy channel in a/d units [0, 4095] 
;   
;   attenuator_flag : in, type='byte', default='0b'
;     if set to 1, this detector event would be absorbed by the attenuator
;
; :returns:
;   a stx_sim_detector_event structure
;
; :examples:
;   det_event = stx_construct_sim_detector_event(...)
;
; :history:
;   23-jan-2014 - Laszlo I. Etesi (FHNW), initial release
;   23-jul-2014 - Laszlo I. Etesi (FHNW), added attenuator flag
;   03-jul-2015 - Laszlo I. Etesi (FHNW), added support for multi-event handling
;
;-
function stx_construct_sim_detector_event, relative_time=relative_time, detector_index=detector_index, pixel_index=pixel_index, energy_ad_channel=energy_ad_channel, attenuator_flag=attenuator_flag
  detector_event = replicate({stx_sim_detector_event}, n_elements(relative_time))
  
  if(keyword_set(relative_time)) then detector_event.relative_time = relative_time
  if(keyword_set(detector_index)) then detector_event.detector_index = detector_index
  if(keyword_set(pixel_index)) then detector_event.pixel_index = pixel_index
  if(keyword_set(energy_ad_channel)) then detector_event.energy_ad_channel = energy_ad_channel
  if(keyword_set(attenuator_flag)) then detector_event.attenuator_flag = attenuator_flag
  
  return, detector_event
end