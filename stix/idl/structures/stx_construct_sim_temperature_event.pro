;+
; :description:
;   This function constructs a detector event for the flight software simulation.
;
; :categories:
;    flight software, constructor, simulation
;
; :keywords:
;    relative_time : in, type="dblarr", default="0d"
;                          this is the relative time range in ms (start time); relative to the start_time in stx_sim_calibrated_detector_eventlist
;    detector_index : in, type="byte", default="0b"
;                     detector index [0,31]
;    temperature : in, type="uint", default="uint(0)"
;                  temperature 
;
; :returns:
;    a stx_sim_temperature_event structure
;
; :examples:
;    temperature_event = stx_construct_sim_temperature_event(...)
;
; :history:
;     17-Jun-2015, Marek Steslicki (SRC Wro), initial release
;
;-
function stx_construct_sim_temperature_event, relative_time=relative_time, detector_index=detector_index,  temperature=temperature
  temperature_event = {stx_sim_temperature_event}
  
  if(keyword_set(relative_time)) then temperature_event.relative_time = relative_time
  if(keyword_set(detector_index)) then temperature_event.detector_index = detector_index
  if(keyword_set(temperature)) then temperature_event.temperature = temperature
  
  return, temperature_event
end