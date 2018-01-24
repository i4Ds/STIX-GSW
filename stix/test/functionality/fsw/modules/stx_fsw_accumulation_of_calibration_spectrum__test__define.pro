;+
;  :file_comments:
;    Test routine for the FSW module routine for the accumulation of the calibration spectrum
;
;  :categories:
;    Flight Software Simulator, accumulation of calibration spectrum, testing
;
;  :examples:
;    res = iut_test_runner('stx_fsw_accumulation_of_calibration_spectrum__test')
;
;  :history:
;    25-mar-2014 - Laszlo I. Etesi (FHNW), initial release
;    22-sep-2015 - Laszlo I. Etesi (FHNW), * fixed the function call to the calibration spectra routine
;                                         * disabled the test (for now) since they cannot work
;    30-oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;   
;  :todo:
;    01-apr-2014 - Laszlo I. Etesi (FHNW), also add test for overflow, for addressing, timing
;-

;+
; :description:
;   Setup of this test. The testing is done with a predefined eventlist. The eventlist
;   is constructed with the goal to cover many realistic and relevant pulse scenarios.
;   1. Start event at exactly tq, 1 more event tq + 0.001 apart (goal: count both)
;   2. Event at 1, and one more tq/2 apart (goal: count first only)
;   3. Event at 2, and three more each tq/4 apart (goal: count first only)
;   4. Event at 4 - tq/2, and one at 4 (goal: test boundary condition -> count first only)
;   5. Event at 8 - tq, one at 8 - tq/2, one at 8, and one at 8 + 2 * tq (goal: test boundary condition -> count 8 - tq and 8 + 2 * tq)
;   
;   The a/d channels, pixels indeces, and detector indeces are assigned randomly.
;-
pro stx_fsw_accumulation_of_calibration_spectrum__test::beforeclass
  default, tq, 0.1
  ; construct event times
  relative_times = [ $
    tq, 2 * tq + 0.001, $
    1 , 1 + tq/2., $
    2, 2 + tq/4, 2 + tq/2, 2 + tq, $
    4 - tq/2., 4, $
    8 - tq, 8 - tq/2., 8, 8 + 2 * tq]
  
  events = replicate(stx_sim_detector_event(), n_elements(relative_times))
  events.relative_time = relative_times
  
  events.detector_index = fix(randomu(seed, n_elements(events)) * 32 + 1)
  events.pixel_index = fix(randomu(seed, n_elements(events)) * 12)
  events.energy_ad_channel = fix(randomu(seed, n_elements(events)) * 4096)
  
  self.eventlist = ptr_new(stx_construct_sim_detector_eventlist(start_time=0, detector_events=events, sources=stx_sim_source_structure()))
  self.tq = tq
end


;+
; cleanup at object destroy
;-
pro stx_fsw_accumulation_of_calibration_spectrum__test::afterclass


end

;+
; cleanup after each test case
;-
pro stx_fsw_accumulation_of_calibration_spectrum__test::after


end

;+
; init before each test case
;-
pro stx_fsw_accumulation_of_calibration_spectrum__test::before


end

;+
; :description:
;   Sets tq to a very high value, thereby enforcing the gate to be constantly closed.
;   Accumulated counts should be zero.
;   Live time should be zero
;-
;pro stx_fsw_accumulation_of_calibration_spectrum__test::test_no_quiet_time
;  stx_fsw_accumulation_of_calibration_spectrum, (*self.eventlist).detector_events, tq=8, calibration_spectrum=calibration_spectrum
;  
;  assert_true, total(calibration_spectrum.accumulated_counts) eq 7
;  assert_true, calibration_spectrum.live_time eq 0
;end

;+
; :description:
;   Run the calibration_spectrum accumulation with one event.
;   Accumulated counts should be 1. Live time cannot be properly calculated.
;-
;pro stx_fsw_accumulation_of_calibration_spectrum__test::test_one_event 
;  stx_fsw_accumulation_of_calibration_spectrum, (*self.eventlist).detector_events[0], calibration_spectrum=calibration_spectrum
;  
;  assert_true, total(calibration_spectrum.accumulated_counts) eq 1
;  ;assert_true, calibration_spectrum.live_time eq (short_eventlist[0].detector_events.relative_time)
;end

;pro stx_fsw_accumulation_of_calibration_spectrum__test::test_all_events
;  stx_fsw_accumulation_of_calibration_spectrum, (*self.eventlist).detector_events, calibration_spectrum=calibration_spectrum
;  
;  assert_true, total(calibration_spectrum.accumulated_counts) eq 7
;  
;  tq = self.tq
;  
;  total_active = 8 + 2 * tq + tq; last pulse
;  total_times_gate_closed = 8 * tq + tq/2. ; 7 * tq + tq/2 + tq/4 + tq/4 + tq/4 + tq/2 + tq/2 + tq/2
;  
;  assert_true, calibration_spectrum.live_time eq (total_active - total_times_gate_closed)
;end

;+
; Define instance variables.
;-
pro stx_fsw_accumulation_of_calibration_spectrum__test__define
  compile_opt idl2, hidden

  define = { stx_fsw_accumulation_of_calibration_spectrum__test, $
    eventlist : ptr_new(), $
    tq : 0., $
    inherits iut_test }
end

