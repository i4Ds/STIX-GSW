

;+
; init at object instanciation
;-
pro stx_sim_eventlist__test::beforeclass


end


;+
; cleanup at object destroy
;-
pro stx_sim_eventlist__test::afterclass


end

;+
; cleanup after each test case
;-
pro stx_sim_eventlist__test::after


end

;+
; init before each test case
;-
pro stx_sim_eventlist__test::before


end


;pro stx_sim_eventlist__test::test_time_filter
;  
;  
;  a = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=1,relative_time=100)
;  b = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=1,relative_time=101)
;  c = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=1,relative_time=102)
;  d = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=4,relative_time=103)
;  e = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=5,relative_time=104)
;  f = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=6,relative_time=105)
;  g = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=7,relative_time=106)
;  h = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=8,relative_time=107)
;  i = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=9,relative_time=108)
;  
;  j = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=1,relative_time=111)
;  k = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=1,relative_time=115)
;  l = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=1,relative_time=116)
;  
;  m = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=2,relative_time=121)
;  n = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=3,relative_time=122)
;  o = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=4,relative_time=123)
;  p = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=4,relative_time=124)
;  q = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=2,relative_time=126)
;  r = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=2,relative_time=127)
;  s = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=2,relative_time=128)
;  t = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=4,relative_time=129)
;  
;  u = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=4,relative_time=132)
;  v = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=4,relative_time=133)
;  w = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=4,relative_time=134)
;  x = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=4,relative_time=135)
;  
;  y = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=100,pixel_index=4,relative_time=145)
;  
;  
;  list = stx_construct_sim_detector_eventlist(detector_events=[a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y],start_time=0,sources=stx_sim_source_structure())
;  T_L = 3d
;  T_R = 6d
;  
;  list.detector_events = stx_sim_timeorder_eventlist(list.detector_events)
;  
;  filteredlist = stx_sim_timefilter_eventlist(list.detector_events, triggers_out=triggers_out, T_L=T_L, T_R=T_R)
;  
;  assert_equals, n_elements(filteredlist), 3
;  assert_equals, n_elements(triggers_out), 5
;  
;  ;reject
;  assert_equals, triggers_out[0].relative_time, 100
;  
;  ;single + TR
;  assert_equals, filteredlist[0].relative_time, 111
;  assert_equals, filteredlist[0].energy_ad_channel, 100
;  assert_equals, triggers_out[1].relative_time, 111
;  
;  ;reject
;  assert_equals, triggers_out[2].relative_time, 121
;  
;  ;pileup
;  assert_equals, filteredlist[1].relative_time, 132
;  assert_equals, filteredlist[1].energy_ad_channel, 400
;  assert_equals, triggers_out[3].relative_time, 132
;  
;  ;single
;  assert_equals, filteredlist[2].relative_time, 145
;  assert_equals, triggers_out[4].relative_time, 145
;  
;  stx_sim_timefilter_eventlist_plot, list.detector_events, filteredlist, triggers_out, T_L=T_L, T_R=T_R, timerange=[100,146], adgroup=stx_sim_detectoridx2adgroup(2)
;    
;end
;
;
;pro stx_sim_eventlist__test::test_time_order
;
;  a = stx_construct_sim_detector_event(detector_index=8,energy_ad_channel=180,pixel_index=8,relative_time=108)
;  b = stx_construct_sim_detector_event(detector_index=1,energy_ad_channel=110,pixel_index=1,relative_time=101)
;  c = stx_construct_sim_detector_event(detector_index=2,energy_ad_channel=120,pixel_index=2,relative_time=102)
;  d = stx_construct_sim_detector_event(detector_index=5,energy_ad_channel=150,pixel_index=5,relative_time=105)
;  e = stx_construct_sim_detector_event(detector_index=3,energy_ad_channel=130,pixel_index=3,relative_time=103)
;  f = stx_construct_sim_detector_event(detector_index=4,energy_ad_channel=140,pixel_index=4,relative_time=104)
;  g = stx_construct_sim_detector_event(detector_index=6,energy_ad_channel=160,pixel_index=6,relative_time=106)
;  h = stx_construct_sim_detector_event(detector_index=7,energy_ad_channel=170,pixel_index=7,relative_time=107)
;  i = stx_construct_sim_detector_event(detector_index=0,energy_ad_channel=100,pixel_index=0,relative_time=100)
;  
;  list = stx_construct_sim_detector_eventlist(detector_events=[a,b,c,d,e,f,g,h,i],start_time=0,sources=stx_sim_source_structure())
;  
;  list.detector_events = stx_sim_timeorder_eventlist(list.detector_events)
;  
;  assert_equals, n_elements(list.detector_events), 9
;  
;  assert_array_equals, list.detector_events.relative_time, [100,101,102,103,104,105,106,107,108]
;  
;  assert_array_equals, list.detector_events.energy_ad_channel, [100,110,120,130,140,150,160,170,180]
;  
;  assert_array_equals, list.detector_events.detector_index, [0,1,2,3,4,5,6,7,8]  
;  
;  
;end

;+
; Define instance variables.
;-
pro stx_sim_eventlist__test__define
  compile_opt idl2, hidden
  
  define = { stx_sim_eventlist__test, $
    ;your class variables here
    inherits iut_test }
end

