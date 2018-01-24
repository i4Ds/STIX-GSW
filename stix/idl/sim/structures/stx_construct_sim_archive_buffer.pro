;+
; :description:
;   This function constructs an archive buffer for the flight software simulation, which differs
;   slightly from the archive buffer format used in the analysis software (stx_archive_buffer).
;
; :categories:
;    flight software, constructor, simulation
;
; :keywords:
;    relative_time_range : in, type="dblarr(2)", default="dblarr(2)"
;                          this is the relative time range in ms (start time, end time); the 
;                          first element in sequence has start time = 0
;    detector_index : in, type="byte", default="0b"
;                     detector index [0,31]
;    pixel_index : in, type="byte", default="0b"
;                  pixel index [0,11]
;    energy_science_channel : in, type="byte", default="0b"
;                  energy science channel [0,31]
;    counts : in, type="ulong", default="ulong(0)"
;             the integrated number of counts
;    trigger_count : in, type="ulong", default="ulong(0)"
;             the number of counted triggers. each arriving photon triggers a count; if there 
;             are two triggers too close to each other, the photons are not counted. inside
;             the simulation this is realized by filtering the event list.
;             
; :returns:
;    a stx_sim_archive_buffer structure
;
; :examples:
;    ab = stx_construct_sim_archive_buffer(...)
;
; :history:
;     23-jan-2014, Laszlo I. Etesi (FHNW), initial release
;
;-
function stx_construct_sim_archive_buffer, relative_time_range=relative_time_range, detector_index=detector_index, pixel_index=pixel_index, energy_science_channel=energy_science_channel, counts=counts, trigger_count=trigger_count 
  archive_buffer = stx_sim_archive_buffer()
  
  if(keyword_set(relative_time_range)) then archive_buffer.relative_time_range = relative_time_range
  if(keyword_set(detector_index)) then archive_buffer.detector_index = detector_index
  if(keyword_set(pixel_index)) then archive_buffer.pixel_index = pixel_index
  if(keyword_set(energy_science_channel)) then archive_buffer.energy_science_channel = energy_science_channel
  if(keyword_set(counts)) then archive_buffer.counts = counts
  if(keyword_set(trigger_count)) then archive_buffer.trigger_count = trigger_count
  
  return, archive_buffer
end