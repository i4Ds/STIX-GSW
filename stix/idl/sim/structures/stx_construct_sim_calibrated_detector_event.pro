;+
; :description:
;   This function constructs a calibrated detector event for the flight software simulation.
;
; :categories:
;    flight software, constructor, simulation
;
; :keywords:
;    relative_time : in, type="dblarr", default="0d"
;                          this is the relative time range in ms (start time); relative to the start_time in stx_sim_calibrated_detector_eventlist
;    detector_index : in, type="byte", default="0b"
;                     detector index [0,31]
;    pixel_index : in, type="byte", default="0b"
;                  pixel index [0,12], 12 is used for trigger
;    energy_science_channel : in, type="byte", default="0b"
;                  energy science channel [0,31]
;
; :returns:
;    a stx_sim_calibrated_detector_event structure
;
; :examples:
;    calib_det_event = stx_construct_sim_calibrated_detector_event(...)
;
; :history:
;     23-jan-2014, Laszlo I. Etesi (FHNW), initial release
;
;-
function stx_construct_sim_calibrated_detector_event, relative_time=relative_time, detector_index=detector_index, pixel_index=pixel_index, energy_science_channel=energy_science_channel
  detector_event = stx_sim_calibrated_detector_event()
  
  if(keyword_set(relative_time)) then detector_event.relative_time = relative_time
  if(keyword_set(detector_index)) then detector_event.detector_index = detector_index
  if(keyword_set(pixel_index)) then detector_event.pixel_index = pixel_index
  if(keyword_set(energy_science_channel)) then detector_event.energy_science_channel = energy_science_channel
  
  return, detector_event
end