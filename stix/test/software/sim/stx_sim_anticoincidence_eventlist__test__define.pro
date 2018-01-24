;+
; :file_comments:
;   Test routine for the FSW module routine for the accumulation of the calibration spectrum
;
; :categories:
;   Flight Software Simulator, accumulation of calibration spectrum, testing
;
; :examples:
;   res = iut_test_runner('stx_sim_anticoincidence_eventlist__test')
;
; :history:
;   11-May-2015 - ECMD (Graz), initial release
;   09-Jun-2015 - ECMD (Graz), Changed expected behavior on boundary where t2 = t_l +t_r, now both events are detected
;   25-Sep-2015 - ECMD (Graz), now using stx_adg_sc_table to get sc twins
;   19-Feb-2016 - ECMD (Graz), T_ignore  parameter added 
;-

;+
; :description:
;
;-
pro stx_sim_anticoincidence_eventlist__test::beforeclass
    default, T_L, 2d-6 ;2 microseconds
    default, T_R, 10d-6 ;10 microseconds
  
events = []
adg = stx_adg_sc_table()
twins = adg[sort( adg.sc )].sc_twin
  
 for i_block = 0,3 do begin 
  
  first_event_times = findgen(8)+8*i_block
 
r = randomu(seed,4)
  ; construct event times
second_event_times = first_event_times + [ 0, r[0]*t_l, t_l, $
    r[1]*(t_r-t_l)+t_l , t_r, $
    r[2]*(t_l) + t_r,  t_l + t_r, (1+r[3])*(t_l+t_r)]

   relative_times = [first_event_times, second_event_times]
   relative_times = relative_times[sort(relative_times)]
   
  events_block = replicate(stx_sim_detector_event(), n_elements(relative_times))
  events_block.relative_time = relative_times

  case i_block of
   0: begin 
     detector_indices1 = fix(randomu(seed, n_elements(first_event_times)) * 32 + 1)
   pixel_indices1 = fix(randomu(seed, n_elements(first_event_times)) * 12)
   ad_channels1 = fix(randomu(seed, n_elements(first_event_times)) * 4096)
   detector_indices2 = detector_indices1
   pixel_indices2 = pixel_indices1
   ad_channels2 = fix(randomu(seed, n_elements(first_event_times)) * 4096)
   end
    
   1: begin 
   detector_indices1 = fix(randomu(seed, n_elements(first_event_times)) * 32 + 1)
   detector_indices2 =  twins[detector_indices1]
   pixel_indices1 = fix(randomu(seed, n_elements(first_event_times)) * 12)
   ad_channels1 = fix(randomu(seed, n_elements(first_event_times)) * 4096)
   pixel_indices2 = pixel_indices1
   ad_channels2 = fix(randomu(seed, n_elements(first_event_times)) * 4096)
   end
   
   2:  begin
     detector_indices1 = fix(randomu(seed, n_elements(first_event_times)) * 32 + 1)
   pixel_indices1 = fix(randomu(seed, n_elements(first_event_times)) * 12)
   ad_channels1 = fix(randomu(seed, n_elements(first_event_times)) * 4096)
   detector_indices2 = detector_indices1
   ad_channels2 = fix(randomu(seed, n_elements(first_event_times)) * 4096)
   pixel_indices2 = pixel_indices1
   for i = 0,n_elements(first_event_times)-1 do begin  
    while pixel_indices2[i] eq  pixel_indices1[i] do pixel_indices2[i] = fix(randomu(seed) * 12)
    endfor
    end
    
   3: begin
   detector_indices1 = fix(randomu(seed, n_elements(first_event_times)) * 32 + 1)
   pixel_indices1 = fix(randomu(seed, n_elements(first_event_times)) * 12)
   ad_channels1 = fix(randomu(seed, n_elements(first_event_times)) * 4096)
   detector_indices2 = detector_indices1
   ad_channels2 = fix(randomu(seed, n_elements(first_event_times)) * 4096)
   pixel_indices2 = pixel_indices1
   detector_indices1_same_ad =  twins[detector_indices1]
   for i = 0, n_elements(first_event_times)-1 do begin  
    while ((detector_indices2[i] eq detector_indices1[i]) or(detector_indices2[i] eq detector_indices1_same_ad[i])) do detector_indices2[i] = fix(randomu(seed) * 32 + 1)
    endfor
    end
   endcase
   
   even_indices = 2.*findgen(8)
   odd_indices = even_indices +1
   
  events_block[even_indices].energy_ad_channel = ad_channels1
  events_block[even_indices].detector_index = detector_indices1
  events_block[even_indices].pixel_index = pixel_indices1
  events_block[odd_indices].energy_ad_channel = ad_channels2
  events_block[odd_indices].detector_index = detector_indices2
  events_block[odd_indices].pixel_index = pixel_indices2
  
  
  events = [events, events_block]
  endfor
  
  
  self.eventlist = ptr_new(stx_construct_sim_detector_eventlist(start_time=0, detector_events=events, sources=stx_sim_source_structure()))
  self.t_l = t_l
  self.t_r = t_r
  self.t_ig = 0.0d
end


;+
; cleanup at object destroy
;-
pro stx_sim_anticoincidence_eventlist__test::afterclass


end

;+
; cleanup after each test case
;-
pro stx_sim_anticoincidence_eventlist__test::after


end

;+
; init before each test case
;-
pro stx_sim_anticoincidence_eventlist__test::before


end

;+
; :description:
;
;check that the total number of triggers out is exactly equal to the expected value
;
;-
pro stx_sim_anticoincidence_eventlist__test::test_number_triggers
  eventlist_out = stx_sim_timefilter_eventlist((*self.eventlist).detector_events,  t_l=self.t_l, t_r=self.t_r,  t_ig = self.t_ig, triggers_out=triggers_out, event = event)
  assert_true, n_elements(triggers_out) eq 46
end



;+
; :description:
; check that the total number of events out is exactly equal to the expected value
;-
pro stx_sim_anticoincidence_eventlist__test::test_number_events
  eventlist_out = stx_sim_timefilter_eventlist((*self.eventlist).detector_events,  t_l=self.t_l, t_r=self.t_r,  t_ig = self.t_ig, triggers_out=triggers_out, event = event)
  assert_true, n_elements(eventlist_out) eq 42
end


;+
; :description:
;
; Check that the triggers out are assigned the correct times
;-
pro stx_sim_anticoincidence_eventlist__test::test_time_triggers
eventlist_in = (*self.eventlist).detector_events
eventlist_out = stx_sim_timefilter_eventlist(eventlist_in, t_l=self.t_l, t_r=self.t_r,  t_ig = self.t_ig, triggers_out=triggers_out, event = event)
first_event_indices = 2*indgen(32)
second_event_indices = 2.*[6,7,14,15,findgen(10)+22]+1
events_causing_trigger = [first_event_indices,second_event_indices]
events_causing_trigger =events_causing_trigger[sort(events_causing_trigger)]

expected_times = eventlist_in[events_causing_trigger].relative_time
  assert_equals, expected_times ,  triggers_out.relative_time 

end



;+
; :description:
;
; Check that the events out are assigned the correct times
;
;-
pro stx_sim_anticoincidence_eventlist__test::test_time_events
eventlist_in = (*self.eventlist).detector_events
eventlist_out = stx_sim_timefilter_eventlist(eventlist_in, t_l=self.t_l, t_r=self.t_r, t_ig = self.t_ig, triggers_out=triggers_out, event = event)
first_event_indices = 2.*[indgen(8),indgen(6)+10,indgen(14)+18]
second_event_indices = 2.*[6,7,14,15,findgen(10)+22]+1
events_passing_filter = [first_event_indices,second_event_indices]
events_passing_filter =events_passing_filter[sort(events_passing_filter)]

expected_times = eventlist_in[events_passing_filter].relative_time


  assert_equals, expected_times ,  eventlist_out.relative_time 
end


;+
; :description:
;
; Check that the events out are assigned the correct energies
;-
pro stx_sim_anticoincidence_eventlist__test::test_energy_events
eventlist_in = (*self.eventlist).detector_events
eventlist_out = stx_sim_timefilter_eventlist(eventlist_in, t_l=self.t_l, t_r=self.t_r, t_ig = self.t_ig, triggers_out=triggers_out, event = event)
first_event_indices = 2.*[indgen(8),indgen(6)+10,indgen(14)+18]
second_event_indices = 2.*[6,7,14,15,findgen(10)+22]+1
events_passing_filter = [first_event_indices,second_event_indices]
events_passing_filter =events_passing_filter[sort(events_passing_filter)]
pileup_events_in = 2*[0,1]+1
pileup_events_out = [0,1]

expected_energies = eventlist_in[events_passing_filter].energy_ad_channel
expected_energies[pileup_events_out] += eventlist_in[pileup_events_in].energy_ad_channel 
expected_energies <= 4095
  assert_equals, expected_energies ,  eventlist_out.energy_ad_channel
end

;+
; Define instance variables.
;-
pro stx_sim_anticoincidence_eventlist__test__define
  compile_opt idl2, hidden

  define = { stx_sim_anticoincidence_eventlist__test, $
    eventlist : ptr_new(), $
    t_l  : 0., $
    t_r  : 0., $
    t_ig : 0., $
    inherits iut_test }
end

