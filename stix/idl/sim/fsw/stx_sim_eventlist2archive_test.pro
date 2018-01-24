;+
; :DESCRIPTION:
;   Populates an array of stx_sim_calibrated_detector_eventlist, calls
;   stx_sim_eventlist2archive() and returns the resulting archive_buffer
;   array for inspection
;
; :PARAMS:
;   None
;
; :RETURNS:
;   archive_buffer: out, type="array"
;                   array of type stx_sim_archive_buffer
;
; :HISTORY:
;   14-Feb-2014 - Mel Byrne (TCD), created routine
;   30-Oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;-

function stx_sim_eventlist2archive_test
  no_events=21
  eventlist = stx_sim_calibrated_detector_eventlist(no_events=no_events)
  
  n = 0
  eventlist.detector_events[n].relative_time = 80
  eventlist.detector_events[n].detector_index = 6
  eventlist.detector_events[n].pixel_index = 3
  eventlist.detector_events[n].energy_science_channel = 2 
  
  n += 1
  eventlist.detector_events[n].relative_time = 140
  eventlist.detector_events[n].detector_index = 27
  eventlist.detector_events[n].pixel_index = 7
  eventlist.detector_events[n].energy_science_channel = 12

  n += 1
  eventlist.detector_events[n].relative_time = 600
  eventlist.detector_events[n].detector_index = 27
  eventlist.detector_events[n].pixel_index = 7
  eventlist.detector_events[n].energy_science_channel = 12

  n += 1
  eventlist.detector_events[n].relative_time = 1010
  eventlist.detector_events[n].detector_index = 27
  eventlist.detector_events[n].pixel_index = 7
  eventlist.detector_events[n].energy_science_channel = 12
  
  n += 1
  eventlist.detector_events[n].relative_time = 1033
  eventlist.detector_events[n].detector_index = 27
  eventlist.detector_events[n].pixel_index = 7
  eventlist.detector_events[n].energy_science_channel = 12

  n += 1
  eventlist.detector_events[n].relative_time = 1099
  eventlist.detector_events[n].detector_index = 27
  eventlist.detector_events[n].pixel_index = 7
  eventlist.detector_events[n].energy_science_channel = 12

  n += 1
  eventlist.detector_events[n].relative_time = 4795
  eventlist.detector_events[n].detector_index = 31
  eventlist.detector_events[n].pixel_index = 11
  eventlist.detector_events[n].energy_science_channel = 31
  
  n += 1
  eventlist.detector_events[n].relative_time = 4896
  eventlist.detector_events[n].detector_index = 32
  eventlist.detector_events[n].pixel_index = 11
  eventlist.detector_events[n].energy_science_channel = 31

  n += 1
  eventlist.detector_events[n].relative_time = 5100
  eventlist.detector_events[n].detector_index = 32
  eventlist.detector_events[n].pixel_index = 11
  eventlist.detector_events[n].energy_science_channel = 31

  n += 1
  eventlist.detector_events[n].relative_time = 5200
  eventlist.detector_events[n].detector_index = 32
  eventlist.detector_events[n].pixel_index = 11
  eventlist.detector_events[n].energy_science_channel = 31

  n += 1
  eventlist.detector_events[n].relative_time = 5300
  eventlist.detector_events[n].detector_index = 32
  eventlist.detector_events[n].pixel_index = 11
  eventlist.detector_events[n].energy_science_channel = 31

  n += 1
  eventlist.detector_events[n].relative_time = 5400
  eventlist.detector_events[n].detector_index = 32
  eventlist.detector_events[n].pixel_index = 11
  eventlist.detector_events[n].energy_science_channel = 31

  n += 1
  eventlist.detector_events[n].relative_time = 5500
  eventlist.detector_events[n].detector_index = 32
  eventlist.detector_events[n].pixel_index = 11
  eventlist.detector_events[n].energy_science_channel = 31

  n += 1
  eventlist.detector_events[n].relative_time = 5600
  eventlist.detector_events[n].detector_index = 32
  eventlist.detector_events[n].pixel_index = 11
  eventlist.detector_events[n].energy_science_channel = 31

  n += 1
  eventlist.detector_events[n].relative_time = 5700
  eventlist.detector_events[n].detector_index = 32
  eventlist.detector_events[n].pixel_index = 11
  eventlist.detector_events[n].energy_science_channel = 31

  n += 1
  eventlist.detector_events[n].relative_time = 5800
  eventlist.detector_events[n].detector_index = 32
  eventlist.detector_events[n].pixel_index = 11
  eventlist.detector_events[n].energy_science_channel = 31

  n += 1
  eventlist.detector_events[n].relative_time = 5900
  eventlist.detector_events[n].detector_index = 32
  eventlist.detector_events[n].pixel_index = 11
  eventlist.detector_events[n].energy_science_channel = 31

  n += 1
  eventlist.detector_events[n].relative_time = 6000
  eventlist.detector_events[n].detector_index = 32
  eventlist.detector_events[n].pixel_index = 11
  eventlist.detector_events[n].energy_science_channel = 31

  n += 1
  eventlist.detector_events[n].relative_time = 6100
  eventlist.detector_events[n].detector_index = 32
  eventlist.detector_events[n].pixel_index = 11
  eventlist.detector_events[n].energy_science_channel = 31

  n += 1
  eventlist.detector_events[n].relative_time = 6200
  eventlist.detector_events[n].detector_index = 31
  eventlist.detector_events[n].pixel_index = 11
  eventlist.detector_events[n].energy_science_channel = 31

  n += 1
  eventlist.detector_events[n].relative_time = 6300
  eventlist.detector_events[n].detector_index = 32
  eventlist.detector_events[n].pixel_index = 11
  eventlist.detector_events[n].energy_science_channel = 31

  start_time = 0
  next_event = 0
  archive_buffer = stx_sim_eventlist2archive_ng(eventlist, start_time, $
    next_event, t_min=0.5, t_max=5.0, n_min=100, masked_out_events = mo_events, /close_last_time_bin)

  print, 'N events ', n+1
  print, 'Next event index ', next_event
  print, 'Next bin start time ', start_time
  
  print, archive_buffer
  
  return, archive_buffer
end
