;+
;  :description
;    Unit test for the quicklook accumulation ["qla"] module in the flight software simulator.
;
;  :categories:
;    Flight Software Simulator, quicklook accumulation, testing
;
;  :examples:
;    res = iut_test_runner('stx_fsw_quicklook_accumulation__test')
;   
;  :history:
;    29-jun-2015 - Aidan O'Flannagain (TCD), initial release
;    01-jul-2015 - Aidan O'Flannagain (TCD), now use $SSW_STIX environment variable to get to config file
;    30-oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;    26-feb-2016 - Laszlo I. Etesi (FHNW), changed the total TL/QL tests slightly to include the upper energy bound
;    10-may-2016 - Laszlo I. Etesi (FHNW), using construct time and removed +1 index in test
;-
pro stx_fsw_quicklook_accumulation__test::beforeclass

  ;prepare input to detector failure module
  num_events = 32*12*5
  events = replicate(stx_sim_calibrated_detector_event(), num_events)

  ;prepare an energy array with randomly sampled values in the range [0, 4095]
  energy_science_channel = randomu(seed, num_events)*32
  events.energy_science_channel = energy_science_channel
  
  ;choose indices such that it's certain each pixel/detector combination registers
  ;at least one event
  events.detector_index = uint(dindgen(num_events)/num_events*32)+1
  events.pixel_index = indgen(num_events) mod 12
  relative_time = randomu(seed, num_events) * 4.
  ;time-order the events
  events.relative_time = relative_time[sort(relative_time)] 
  eventlist = ptr_new(stx_construct_sim_detector_eventlist(start_time=0, detector_events=events, sources=stx_sim_source_structure()))
  triggerlist = ptr_new(stx_construct_sim_detector_eventlist(start_time=0, detector_events=events, sources=stx_sim_source_structure()))
  
  ;set the list types to their "correct" names
  (*eventlist).type = 'stx_sim_calibrated_detector_eventlist'
  (*triggerlist).type = 'stx_sim_event_triggerlist'
  
  interval_start_time = stx_construct_time(time=0)
  
  active_detectors = bytarr(32) + 1
  
  ;finally, prepare the configuration parameters
    conf_file = getenv('SSW_STIX') + "/dbase/conf/qlook_accumulators.csv"
  quicklook_config_struct = ptr_new(stx_fsw_ql_accumulator_table2struct(conf_file))
  
  self.eventlist = eventlist
  self.triggerlist = triggerlist
  self.interval_start_time = interval_start_time
  self.active_detectors = active_detectors
  self.quicklook_config_struct = quicklook_config_struct

end

;+
; cleanup at object destroy
;-
pro stx_fsw_quicklook_accumulation__test::afterclass


end

;+
; cleanup after each test case
;-
pro stx_fsw_quicklook_accumulation__test::after


end

;+
; init before each test case
;-
pro stx_fsw_quicklook_accumulation__test::before


end

;+
; :description:
;   loop over each of the QL accumulators, and generate a QL product. Based on the QL configuration
;   for each accumulator, calculate the expected dimensions of the product. Compare the expected
;   with actual dimensions. If they are not identical, the test is failed.
;-
pro stx_fsw_quicklook_accumulation__test::test_dimensions_ql

  eventlist = *self.eventlist
  interval_start_time = self.interval_start_time
  active_detectors = self.active_detectors
  quicklook_config_struct = self.quicklook_config_struct
  
  ;string array of non-matching accumulators
  non_match = []
  
  ;loop through the QL products, following the method of
  ;stx_fsw_module_ql_accumulation__define.pro (as of 29 June 2015)
  for index = 0, n_elements(*quicklook_config_struct)-1 do begin
    quicklook_config = (*quicklook_config_struct)[index]
    
    ;disregard livetime accumulators (they are addressed in a separate test)
    if ~quicklook_config.livetime then begin
      ;calculate the expected dimensions of the output: d_en, d_pi, d_de, d_ti
      d_en = n_elements(*quicklook_config.channel_bin) - 1
      
      if quicklook_config.sum_pix then d_pi = 1$
        ;pixel_sub_sum accounts for the CORNERS pixel configuration of flare_location_1
        else if quicklook_config.pixel_sub_sum then d_pi = 4$
        else d_pi = n_elements(*quicklook_config.pixel_index_list)
        
      if quicklook_config.sum_det then d_de = 1$
        else d_de = n_elements(*quicklook_config.det_index_list)
        
      d_ti = fix(4./quicklook_config.dt)
      
      expected_size = size(ulonarr(d_en, d_pi, d_de, d_ti))
      
      result = stx_fsw_eventlist_accumulator(eventlist, interval_start_time = interval_start_time, _extra=quicklook_config, active_detectors=active_detectors)
      
      ;determine the dimensions of result.accumulated_counts
      result_size = size(result.accumulated_counts)

      size_compare = where((result_size eq expected_size) ne 1, num_not_match)
      if num_not_match ne 0 then non_match = [non_match,' ', quicklook_config.accumulator]
    endif
  endfor
  
  mess = ''
  if n_elements(non_match) ne 0 then mess = $
    strjoin(['Dimensions QL test: following accumulators had unexpected dimensions:',non_match])
  assert_true, n_elements(non_match) eq 0, mess
  
end

;+
; :description:
;   loop over each of the LT accumulators, and generate a LT product. Based on the QL configuration
;   for each accumulator, calculate the expected dimensions of the product. Compare the expected
;   with actual dimensions. If they are not identical, the test is failed.
;-
pro stx_fsw_quicklook_accumulation__test::test_dimensions_lt

  triggerlist = *self.triggerlist
  interval_start_time = self.interval_start_time
  active_detectors = self.active_detectors
  quicklook_config_struct = self.quicklook_config_struct
  
  ;string array of non-matching accumulators
  non_match = []
  
  ;loop through the QL products, following the method of
  ;stx_fsw_module_ql_accumulation__define.pro (as of 29 June 2015)
  for index = 0, n_elements(*quicklook_config_struct)-1 do begin
    quicklook_config = (*quicklook_config_struct)[index]
    
    ;disregard quicklook accumulators (they are addressed in a separate test)
    if quicklook_config.livetime then begin
      ;calculate the expected dimensions of the output: d_en, d_pi, d_de, d_ti
      d_en = n_elements(*quicklook_config.channel_bin) - 1
      
      if quicklook_config.sum_pix then d_pi = 1$
        ;pixel_sub_sum accounts for the CORNERS pixel configuration of flare_location_1
        else if quicklook_config.pixel_sub_sum then d_pi = 4$
        else d_pi = n_elements(*quicklook_config.pixel_index_list)
        
      if quicklook_config.sum_det then d_de = 1$
        else d_de = n_elements(*quicklook_config.det_index_list)
        
      d_ti = fix(4./quicklook_config.dt)
      
      expected_size = size(ulonarr(d_en, d_pi, d_de, d_ti))
      
      result = stx_fsw_eventlist_accumulator(triggerlist, interval_start_time = interval_start_time, _extra=quicklook_config, active_detectors=active_detectors, livetime = 1)
      
      ;determine the dimensions of result.accumulated_counts
      result_size = size(result.accumulated_counts)

      size_compare = where((result_size eq expected_size) ne 1, num_not_match)
      if num_not_match ne 0 then non_match = [non_match,' ', quicklook_config.accumulator]
    endif
  endfor
  
  mess = ''
  if n_elements(non_match) ne 0 then mess = $
    strjoin(['Dimensions QL test: following accumulators had unexpected dimensions:',non_match])
  assert_true, n_elements(non_match) eq 0, mess
  
end

;+
; :description:
;   loop over each of the QL accumulators, and generate a QL product. Based on the QL configuration
;   for each accumulator and the input event list, calculate the number of events that should be
;   accumulated. Compare these to the total of accumulated_events returned from the module. If 
;   the numbers are not the same, the test is failed.
;-
pro stx_fsw_quicklook_accumulation__test::test_total_number_ql

  eventlist = *self.eventlist
  interval_start_time = self.interval_start_time
  active_detectors = self.active_detectors
  quicklook_config_struct = self.quicklook_config_struct
  
  ;string array of accumulators with incorrect number of events
  non_match = []
  
  ;loop through the QL products, following the method of
  ;stx_fsw_module_ql_accumulation__define.pro (as of 29 June 2015)
  for index = 0, n_elements(*quicklook_config_struct)-1 do begin
    quicklook_config = (*quicklook_config_struct)[index]
    
    ;disregard livetime accumulators (they are addressed in a separate test)
    if ~quicklook_config.livetime then begin
    
      ;pull out the events this accumulator should include
      used_det = *quicklook_config.det_index_list
      used_pix = *quicklook_config.pixel_index_list
      used_en = indgen( (*quicklook_config.channel_bin)[-1] - (*quicklook_config.channel_bin)[0]) $
        + (*quicklook_config.channel_bin)[0]
      
      used_events = where(is_member(eventlist.detector_events.detector_index, used_det)$
                      and is_member(eventlist.detector_events.pixel_index, used_pix)$
                      and is_member(eventlist.detector_events.energy_science_channel, used_en), num_expected)
      
      ;run the module, and calculate the total accumulated events
      result = stx_fsw_eventlist_accumulator(eventlist, interval_start_time = interval_start_time, _extra=quicklook_config, active_detectors=active_detectors)
      num_events = long(total(result.accumulated_counts))
      
      if num_expected ne num_events then non_match = [non_match, ' ', quicklook_config.accumulator]
      
    endif
  endfor

  mess = ''
  if n_elements(non_match) ne 0 then mess = $
    strjoin(['Total number QL test: following accumulators had unexpected number of accumulated counts:',non_match])
  assert_true, n_elements(non_match) eq 0, mess

end


;+
; :description:
;   loop over each of the LT accumulators, and generate a LT product. Based on the QL configuration
;   for each accumulator and the input event list, calculate the number of events that should be
;   accumulated. Compare these to the total of accumulated_events returned from the module. If 
;   the numbers are not the same, the test is failed.
;-
pro stx_fsw_quicklook_accumulation__test::test_total_number_lt

  triggerlist = *self.triggerlist
  interval_start_time = self.interval_start_time
  active_detectors = self.active_detectors
  quicklook_config_struct = self.quicklook_config_struct
  
  ;string array of accumulators with incorrect number of events
  non_match = []
  
  ;loop through the QL products, following the method of
  ;stx_fsw_module_ql_accumulation__define.pro (as of 29 June 2015)
  for index = 0, n_elements(*quicklook_config_struct)-1 do begin
    quicklook_config = (*quicklook_config_struct)[index]
    
    ;disregard livetime accumulators (they are addressed in a separate test)
    if ~quicklook_config.livetime then begin
    
      ;pull out the events this accumulator should include
      used_det = *quicklook_config.det_index_list
      used_pix = *quicklook_config.pixel_index_list
      used_en = indgen( (*quicklook_config.channel_bin)[-1] - (*quicklook_config.channel_bin)[0]) $
        + (*quicklook_config.channel_bin)[0]
      
      used_events = where(is_member(triggerlist.detector_events.detector_index, used_det)$
                      and is_member(triggerlist.detector_events.pixel_index, used_pix)$
                      and is_member(triggerlist.detector_events.energy_science_channel, used_en), num_expected)
      
      ;run the module, and calculate the total accumulated events
      result = stx_fsw_eventlist_accumulator(triggerlist, interval_start_time = interval_start_time, _extra=quicklook_config, active_detectors=active_detectors, livetime = 1)
      num_events = long(total(result.accumulated_counts))
      
      if num_expected ne num_events then non_match = [non_match, ' ', quicklook_config.accumulator]
      
    endif
  endfor

  mess = ''
  if n_elements(non_match) ne 0 then mess = $
    strjoin(['Total number QL test: following accumulators had unexpected number of accumulated counts:',non_match])
  assert_true, n_elements(non_match) eq 0, mess

end

;+
; Define instance variables.
;-
pro stx_fsw_quicklook_accumulation__test__define
  compile_opt idl2, hidden

  define = {stx_fsw_quicklook_accumulation__test,$
    eventlist:ptr_new(),$
    triggerlist:ptr_new(),$
    interval_start_time:stx_time(),$
    active_detectors:bytarr(32),$
    quicklook_config_struct:ptr_new(),$
    inherits iut_test}
end