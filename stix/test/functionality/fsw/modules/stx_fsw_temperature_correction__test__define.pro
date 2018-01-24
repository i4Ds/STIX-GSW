;+
;  :description
;    Unit test for temperature correction ["tc"] module in the flight software simulator.
;
;  :categories:
;    Flight Software Simulator, temperature correction, testing
;
;  :examples:
;    res = iut_test_runner('stx_fsw_temperature_correction__test')
;   
;  :history:
;    28-jun-2015 - Aidan O'Flannagain (TCD), initial release
;    30-Oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;-
pro stx_fsw_temperature_correction__test::beforeclass
  ;prepare input to detector failure module
  num_events = 1000
  events = replicate(stx_sim_detector_event(), num_events)

  ;prepare an energy array with evenly sampled values in the range [0, 4095]
  energy_ad_channels = fix(findgen(num_events)/num_events*4095)
  
  events.energy_ad_channel = energy_ad_channels
  events.detector_index = uint(dindgen(num_events)/num_events*32)+1
  events.pixel_index = fix(dindgen(num_events)/num_events* 12)
  relative_time = randomu(seed, num_events) * 4.
  ;time-order the events
  events.relative_time = relative_time[sort(relative_time)] 
  eventlist = ptr_new(stx_construct_sim_detector_eventlist(start_time=0, detector_events=events, sources=stx_sim_source_structure()))
  
  ;set the list types to their "correct" names
  (*eventlist).type = 'stx_sim_sdetector_eventlist'
  
  ;finally, generate a temperature correction table
  temperature_correction_table = findgen(32,12)/10.
  temperature_correction_table -= average(temperature_correction_table)
  
  self.eventlist = eventlist
  self.temperature_correction_table = temperature_correction_table

end

;+
; cleanup at object destroy
;-
pro stx_fsw_temperature_correction__test::afterclass


end

;+
; cleanup after each test case
;-
pro stx_fsw_temperature_correction__test::after


end

;+
; init before each test case
;-
pro stx_fsw_temperature_correction__test::before


end

;+
; :description:
;   Run the module script with an adjusted temperature correction table such that a predetermined
;   number of events have their energies shifted out of the range [0, 4095].
;   Isolate the subset of events whose shifted energy is within the above range, and compare
;   the shifted values with the values produced by the module. If any differ, the test is failed.
;-
pro stx_fsw_temperature_correction__test::test_correct_shift
  eventlist = *self.eventlist
  temperature_correction_table = self.temperature_correction_table
  
  ;determine the subset of events which should not be shifted out of the range [0,4095]
  shifted_channels = eventlist.detector_events.energy_ad_channel + temperature_correction_table[eventlist.detector_events.detector_index,eventlist.detector_events.pixel_index]
  where_inrange = where(shifted_channels ge 0 and shifted_channels le 4095)
  
  ;run the module
  ad_temp_corrected = stx_fsw_temperature_correction(*self.eventlist, self.temperature_correction_table)
  non_match = where(shifted_channels[where_inrange] eq float(ad_temp_corrected.detector_events[where_inrange].energy_ad_channel), num_non_match)
  mess = ''
  if num_non_match ne 0 then mess = strjoin(["Correct shift test: following idx not shifted correctly:" , strcompress(non_match)])
  assert_true, num_non_match eq 0 , mess
end

;+
; :description:
;   Run the module script with an adjusted temperature correction table such that a predetermined
;   number of events have their energies shifted out of the range [0, 4095].
;   Isolate the subset of events whose shifted energy is below the above range. If any remain outside,
;   this range, the test is failed.
;-
pro stx_fsw_temperature_correction__test::test_low_edge
  eventlist = *self.eventlist
  temperature_correction_table = self.temperature_correction_table
  
  ;determine the subset of events which should not be shifted out of the range [0,4095]
  shifted_channels = eventlist.detector_events.energy_ad_channel + temperature_correction_table[eventlist.detector_events.detector_index,eventlist.detector_events.pixel_index]
  where_belowrange = where(shifted_channels lt 0)
  
  ;run the module
  ad_temp_corrected = stx_fsw_temperature_correction(*self.eventlist, self.temperature_correction_table)
  
  outside_range = where(ad_temp_corrected.detector_events[where_belowrange].energy_ad_channel lt 0 or $
                         ad_temp_corrected.detector_events[where_belowrange].energy_ad_channel gt 4095, num_fail)
  mess = ''
  if num_fail ne 0 then mess = strjoin(["Low edge test: following idx not in range [0,4095]:" , strcompress(outside_range)])
  assert_true, num_fail eq 0 , mess
end

;+
; :description:
;   Run the module script with an adjusted temperature correction table such that a predetermined
;   number of events have their energies shifted out of the range [0, 4095].
;   Isolate the subset of events whose shifted energy is above the above range. If any remain outside,
;   this range, the test is failed.
;-
pro stx_fsw_temperature_correction__test::test_high_edge
  eventlist = *self.eventlist
  temperature_correction_table = self.temperature_correction_table
  
  ;determine the subset of events which should not be shifted out of the range [0,4095]
  shifted_channels = eventlist.detector_events.energy_ad_channel + temperature_correction_table[eventlist.detector_events.detector_index,eventlist.detector_events.pixel_index]
  where_belowrange = where(shifted_channels gt 4095)
  
  ;run the module
  ad_temp_corrected = stx_fsw_temperature_correction(*self.eventlist, self.temperature_correction_table)
  
  outside_range = where(ad_temp_corrected.detector_events[where_belowrange].energy_ad_channel lt 0 or $
                         ad_temp_corrected.detector_events[where_belowrange].energy_ad_channel gt 4095, num_fail)
  mess = ''
  if num_fail ne 0 then mess = strjoin(["High edge test: following idx not in range [0,4095]:" , strcompress(outside_range)])
  assert_true, num_fail eq 0 , mess
end

;+
; Define instance variables.
;-
pro stx_fsw_temperature_correction__test__define
  compile_opt idl2, hidden

  define = {stx_fsw_temperature_correction__test,$
    eventlist:ptr_new(),$
    temperature_correction_table:fltarr(32,12),$
    inherits iut_test}
end