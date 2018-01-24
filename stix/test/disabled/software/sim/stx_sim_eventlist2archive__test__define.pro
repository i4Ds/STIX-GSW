

;+
; init at object instanciation
;-
pro stx_sim_eventlist2archive__test::beforeclass


end


;+
; cleanup at object destroy
;-
pro stx_sim_eventlist2archive__test::afterclass


end

;+
; cleanup after each test case
;-
pro stx_sim_eventlist2archive__test::after


end

;+
; init before each test case
;-
pro stx_sim_eventlist2archive__test::before


end


;pro stx_sim_eventlist2archive__test::test_create
;  no_events = 5
;  eventlist = stx_sim_calibrated_detector_eventlist(no_events)
;  eventlist.start_time.value.time = 34
;  
;  eventlist.detector_events[0].relative_time = 80
;  eventlist.detector_events[0].detector_index = 6
;  eventlist.detector_events[0].pixel_index = 3
;  eventlist.detector_events[0].energy_science_channel = 2 
;  
;  eventlist.detector_events[1].relative_time = 1010
;  eventlist.detector_events[1].detector_index = 27
;  eventlist.detector_events[1].pixel_index = 7
;  eventlist.detector_events[1].energy_science_channel = 12
;  
;  eventlist.detector_events[2].relative_time = 1033
;  eventlist.detector_events[2].detector_index = 27
;  eventlist.detector_events[2].pixel_index = 7
;  eventlist.detector_events[2].energy_science_channel = 12
;
;  eventlist.detector_events[3].relative_time = 1099
;  eventlist.detector_events[3].detector_index = 27
;  eventlist.detector_events[3].pixel_index = 7
;  eventlist.detector_events[3].energy_science_channel = 12
;
;  eventlist.detector_events[4].relative_time = 2256
;  eventlist.detector_events[4].detector_index = 31
;  eventlist.detector_events[4].pixel_index = 11
;  eventlist.detector_events[4].energy_science_channel = 31
;  
;  archive_buffer = stx_sim_eventlist2archive(eventlist)
;  
;  ;3 archive buffer entries should exists
;  assert_equals, n_elements(archive_buffer), 3
;  
;  ;the total count should be equal to the number off all events
;  assert_equals, total(archive_buffer.COUNTS), no_events
;  
;  ;... 
;end


pro stx_sim_eventlist2archive__test__define
  compile_opt idl2, hidden
  
  void = {stx_sim_eventlist2archive__test, $
    inherits iut_test }
end

