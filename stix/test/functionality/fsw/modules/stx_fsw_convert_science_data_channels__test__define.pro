;+
;  :description
;    Unit test for convert science data channels ["csdc"] module in the flight software simulator.
;
;  :categories:
;    Flight Software Simulator, convert science data channels, testing
;
;  :examples:
;    res = iut_test_runner('stx_fsw_convert_science_data_channels__test')
;   
;  :history:
;    28-Jun-2015 - Aidan O'Flannagain (TCD), initial release
;    13-Aug-2015 - Aidan O'Flannagain (TCD), altered code to work with the new lookup table provided by the function stx_energy_lut_get( /full_table )
;    30-Oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;    15-Feb-2016 - ECMD (Graz), science channel array [0,*,*,] corresponds to detector 1
;-

pro stx_fsw_convert_science_data_channels__test::beforeclass
  ;prepare input to detector failure module
  num_events = 32*12
  events = replicate(stx_sim_detector_event(), num_events)

  ;prepare an energy array with evenly sampled values in the range [0, 4095]
  energy_ad_channels = fix(findgen(num_events)/num_events*4095)
  
  events.energy_ad_channel = energy_ad_channels
  events.detector_index = uint(dindgen(num_events)/num_events*32)+1
  events.pixel_index = indgen(num_events) mod 12
  relative_time = randomu(seed, num_events) * 4.
  ;time-order the events
  events.relative_time = relative_time[sort(relative_time)] 
  eventlist = ptr_new(stx_construct_sim_detector_eventlist(start_time=0, detector_events=events, sources=stx_sim_source_structure()))
  
  ;set the list types to their "correct" names
  (*eventlist).type = 'stx_sim_detector_eventlist'
  
  ;finally, generate a science channel table
  scc_table = stx_energy_lut_get( /full_table )
  
  self.eventlist = eventlist
  self.science_channels = scc_table

end

;+
; cleanup at object destroy
;-
pro stx_fsw_convert_science_data_channels__test::afterclass


end

;+
; cleanup after each test case
;-
pro stx_fsw_convert_science_data_channels__test::after


end

;+
; init before each test case
;-
pro stx_fsw_convert_science_data_channels__test::before


end

;+
; :description:
;   Run the module script on the synthetic eventlist using the default science_channel file, which
;   currently only has values within the range [121, 3081]. Isolate events which land within this range
;   (or, in fact, ge 121 and lt 3081), and compare the number of these events to the number returned 
;   by the module. If they are not the same, the test is failed.
;-
pro stx_fsw_convert_science_data_channels__test::test_total_number
  eventlist = *self.eventlist
  science_channels = self.science_channels
  
  ;determine the subset of events which lie in the extremes of the energy range given by the lookup table
  within_range = where(science_channels[eventlist.detector_events.detector_index-1, eventlist.detector_events.pixel_index, eventlist.detector_events.energy_ad_channel] ne 99, num_within)
  
  ;run the module
  calib_det_eventlist = stx_fsw_science_energy_application(eventlist, science_channels)
  num_events = n_elements(calib_det_eventlist.detector_events)
  
  mess = ''
  if num_events ne num_within then mess = strjoin(["Total number test: number of events within range:" , strcompress(num_within),$
                                               ", number returned by module:", strcompress(num_events)])
  assert_true, num_events eq num_within , mess
end

;+
; :description:
;   Run the module script on the synthetic eventlist using the default science_channel file, which
;   currently only has values within the range [121, 3081]. Isolate events which land outside of
;   this range, and make a new eventlist which includes only these events. If the module does not
;   return an empty eventlist, the test is failed.
;-
pro stx_fsw_convert_science_data_channels__test::test_number_invalid
  eventlist = *self.eventlist
  science_channels = self.science_channels
  
  ;determine the subset of events which lie in the extremes of the energy range (default [121, 3081])
  out_of_range = where(science_channels[eventlist.detector_events.detector_index-1, eventlist.detector_events.pixel_index, eventlist.detector_events.energy_ad_channel] eq 99)
  
  ;create a new event list which contains only the out of range events
  events = eventlist.detector_events[out_of_range]
  eventlist = stx_construct_sim_detector_eventlist(start_time=0, detector_events=events, sources=stx_sim_source_structure())
  
  ;run the module
  calib_det_eventlist = stx_fsw_science_energy_application(eventlist, science_channels)
  
  ;check if all events were removed (which would mean that only one event is left and it has
  ;an invalid detector index ( = 0 )
  test_passed = n_elements(calib_det_eventlist) eq 1 and calib_det_eventlist.detector_events.detector_index eq 0
  
  mess = ''
  if ~test_passed then mess = strjoin(["Number invalid test: number of out-of-range events which were not removed:" , strcompress(num_events)])
  assert_true, test_passed , mess
end

;+
; :description:
;   Run the module script on the synthetic eventlist using the default science_channel file, and
;   save the result. Run the module again on an altered conversion table. Compare the two calibrated
;   eventlists. If there is any similarity, the test is failed.
;-
pro stx_fsw_convert_science_data_channels__test::test_altered_conversion_table
  eventlist = *self.eventlist
  science_channels = self.science_channels
  
  ;run the module, producing an eventlist based on the default conversion
  calib_det_eventlist_default = stx_fsw_science_energy_application(eventlist, science_channels)
                             
  ;alter a row of the science_channels table
  ;we'll use the row corresponding to pixel 7 and detector 17
  science_channels[16,7,*] = shift(science_channels[16,7,*], -200)
  
  calib_det_eventlist_altered = stx_fsw_science_energy_application(eventlist, science_channels)
  
  ;calculate the index of the event detected by pixel 7, detector 17
  ;this is done after the module is run as the module will remove events
  event_of_interest_default = where(calib_det_eventlist_default.detector_events.pixel_index eq 7 and $
                             calib_det_eventlist_default.detector_events.detector_index eq 17)
  event_of_interest_altered = where(calib_det_eventlist_altered.detector_events.pixel_index eq 7 and $
                             calib_det_eventlist_altered.detector_events.detector_index eq 17)
  
  ;determine the converted energy value of the event of interest before and after the alteration
  science_channel_default = calib_det_eventlist_default.detector_events[event_of_interest_default].energy_science_channel
  science_channel_altered = calib_det_eventlist_altered.detector_events[event_of_interest_altered].energy_science_channel
  
  mess = ''
  if science_channel_default eq science_channel_altered then mess = "Altered converstion table test: Energy unchanged after alteration of conversion table."
  assert_true, science_channel_default ne science_channel_altered, mess
end

;+
; Define instance variables.
;-
pro stx_fsw_convert_science_data_channels__test__define
  compile_opt idl2, hidden

  define = {stx_fsw_convert_science_data_channels__test,$
    eventlist:ptr_new(),$
    science_channels:intarr(32, 12, 4096),$
    inherits iut_test}
end