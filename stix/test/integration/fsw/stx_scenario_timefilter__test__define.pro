;+
; :file_comments:
;   This is a test class for scenario-based testing; specifically the timefiltering
;
; :categories:
;   data simulation, software, testing
;
; :examples:
;  res =  iut_test_runner('stx_scenario_timefilter__test', keep_detector_eventlist=0b, show_fsw_plots=0b)
;  res =  iut_test_runner('stx_scenario_timefilter__test')
;
; :history:
;   05-Feb-2015 - Laszlo I. Etesi (FHNW), initial release
;   02-Jun-2015 - ECMD (Graz), Statistical timefilter test modules added:
;                              test_unfiltered _events
;                              test_readout
;                              test_coincidence_weak
;                              test_coincidence_low
;                              test_coincidence_intermediate
;                              test_coincidence_moderate
;                              test_coincidence_high
;                              test_triggers_weak
;                              test_triggers_low
;                              test_triggers_intermediate
;                              test_triggers_moderate
;                              test_triggers_high
;                              beforeclass added
;   17-Aug-2015 - ECMD (Graz), updated estimated values and acceptable ranges
;-

;+
; :description:
;    this function initializes this module; make sure to adjust the variables "self.test_name" and "self.test_type";
;    they will control, where in $STX_SCN_TEST to look for this test's scenario and configuration files
;    (e.g. $STX_SCN_TEST/basic/calib_spec_acc)
;
; :keywords:
;   extra : in, optional
;     extra parameters interpreted by the base class (see stx_scenario_test__define)
;
; :returns:
;   this function returns true or false, depending on the success of initializing this object
;-
function stx_scenario_timefilter__test::init, _extra=extra

  self.test_name = 'timefilter'
  self.test_type = 'basic'
  
  return, self->stx_scenario_test::init(_extra=extra)
end


;+
; :description:
;   this procedure runs the test setup and the data simulation but not the flight software simulator
;
;-
pro stx_scenario_timefilter__test::beforeclass

  self->_setup_test
  
  self->_setup_test_environment
  
  self->_run_data_simulation
  
  t_r = 10d-6
  t_l = 2d-6
  
  no_time_bins = long(self.dss->getdata(scenario_name = self.scenario_name, output_target = 'scenario_length') / 4d)
  readout_rates = lonarr(no_time_bins)
  
  for time_bin = 0L, no_time_bins-1 do begin
    
    ds_result_data = self.dss->getdata(output_target='stx_ds_result_data', time_bin=time_bin, $
                                scenario=self.scenario_name, rate_control_regime = 0, t_l = 0.0 ,t_r = t_r)
      
    if(ds_result_data eq !NULL) then continue
    readout_rates[time_bin] = n_elements(ds_result_data.filtered_eventlist.detector_events)
  endfor
  
  found_readout_rate = mean( reform(readout_rates, 4 ,5 ), dim = 1)
  
  
  
  unfiltered_rates = lonarr(no_time_bins)
  
  for time_bin = 0L, no_time_bins-1 do begin
    ds_result_data = self.dss->getdata(output_target='stx_sim_detector_eventlist', time_bin=time_bin, $
      scenario=self.scenario_name, rate_control_regime = 0, t_r = t_r, t_l = t_l)
      
    if(ds_result_data eq !NULL) then continue
    unfiltered_rates[time_bin] = n_elements(ds_result_data.detector_events)
  endfor
  
  found_unfiltered_rate = mean( reform( unfiltered_rates, 4, 5 ), dim = 1)
  
  
  event_rates = lonarr(no_time_bins)
  trigger_rates = lonarr(no_time_bins)
  
  for time_bin = 0L, no_time_bins-1 do begin
    ds_result_data = self.dss->getdata(output_target='stx_ds_result_data', time_bin=time_bin, $
      scenario=self.scenario_name, rate_control_regime = 0, t_l = t_l, t_r = t_r)
      
    if(ds_result_data eq !NULL) then continue
    event_rates[time_bin]   = n_elements(ds_result_data.filtered_eventlist.detector_events)
    trigger_rates[time_bin] = n_elements(ds_result_data.triggers.trigger_events)
    
  endfor
  
  found_event_rate = mean(reform(event_rates, 4, 5), dim = 1)
  
  found_trigger_rate = mean(reform(trigger_rates, 4, 5), dim = 1)
  
  self.found_event_rate = found_event_rate
  self.found_trigger_rate = found_trigger_rate
  self.found_readout_rate = found_readout_rate
  self.found_unfiltered_rate = found_unfiltered_rate
  
end


pro stx_scenario_timefilter__test::test_unfiltered_events

  no_time_bins = long(self.dss->getdata(scenario_name=self.scenario_name, output_target='scenario_length') / 4d)
  
  found_event_rate = self.found_unfiltered_rate
  
  expected_event_rate = [352., 35332., 1767251., 3534718., 7069366.]
  range = [84., 846., 5982., 8460., 11965.]
  
  
  expected_event_ll = expected_event_rate - range
  expected_event_ul = expected_event_rate + range
  
  mess = 'Expected event rate : ' + strjoin(trim(expected_event_rate),",") + ' but found event rate ' + strjoin(trim(found_event_rate),",")

  assert_true,(product(found_event_rate ge expected_event_ll)and product(found_event_rate le expected_event_ul)),mess
end



;+
;
; :description:
;
;   this procedure compares the number of intervals the flare flag is active
;   to the number of sources in the scenario.
;
;-
pro stx_scenario_timefilter__test::test_readout

  found_event_rate = self.found_readout_rate
  
  expected_event_rate = [352., 35133., 1379426., 2264231., 3334791.]
  range = [84., 843., 5285., 6771., 8218.]
  
  expected_event_ll = expected_event_rate - range
  expected_event_ul = expected_event_rate + range
    
  mess = 'Expected event rate : ' + strjoin(trim(expected_event_rate),",") + ' but found event rate ' + strjoin(trim(found_event_rate),",")
  
  assert_true,(product(found_event_rate ge expected_event_ll) and product(found_event_rate le expected_event_ul)),mess
end




;+
;
; :description:
;
;   this procedure compares event rate after time filtering for an initial photon flux of 100 photons
;   per second per cm2 to the expected analytic estimate.
;   The test is passed if simulation event rate differs from the expected value by no more than 2%
;
;-
pro stx_scenario_timefilter__test::test_coincidence_weak

  found_event_rate = (self.found_event_rate)[0]
  
  expected_event_rate = [352.]
  range = [84.]
  
  expected_event_ll = expected_event_rate - range
  expected_event_ul = expected_event_rate + range
    
  mess = 'Expected ' + strtrim(expected_event_rate, 2) + ' events per 4 second interval but found '$
    + strtrim(found_event_rate, 2) +' events per 4 second interval but found '
  
  assert_true,((found_event_rate ge expected_event_ll) and (found_event_rate le expected_event_ul)), mess
end


;+
;
; :description:
;
;   this procedure compares the trigger rate after time filtering for an initial photon flux of 100 photons
;   per second per cm2 to the expected analytic estimate.
;   The test is passed if simulation event trigger differs from the expected value by no more than 2%
;
;-
pro stx_scenario_timefilter__test::test_triggers_weak

  found_trigger_rate = (self.found_trigger_rate)[0]
  
  expected_trigger_rate = [352.]
  range = [84.]
  
  expected_trigger_ll = expected_trigger_rate - range
  expected_trigger_ul = expected_trigger_rate + range
    
  mess = 'Expected ' + strtrim(expected_trigger_rate, 2) + ' triggers per 4 second interval but found '$
    + strtrim(found_trigger_rate, 2) +' triggers per 4 second interval but found '
    
  assert_true,((found_trigger_rate ge expected_trigger_ll)and(found_trigger_rate le expected_trigger_ul)),mess
end

;+
;
; :description:
;
;   this procedure compares event rate after time filtering for an initial photon flux of 1x10^4 photons
;   per second per cm2 to the expected analytic estimate.
;   The test is passed if simulation event rate differs from the expected value by no more than 2%
;
;-
pro stx_scenario_timefilter__test::test_coincidence_low

  found_event_rate = (self.found_event_rate)[1]
  
  
  expected_event_rate = [35056.]
  range = [843.]
  
  expected_event_ll = expected_event_rate - range
  expected_event_ul = expected_event_rate + range
    
  
  mess = 'Expected ' + strtrim(expected_event_rate, 2) + ' events per 4 second interval but found '$
    + strtrim(found_event_rate, 2) +' events per 4 second interval but found '
    
  assert_true,((found_event_rate ge expected_event_ll)and (found_event_rate le expected_event_ul)),mess
end


;+
;
; :description:
;
;   this procedure compares the trigger rate after time filtering for an initial photon flux of 1x10^4 photons
;   per second per cm2 to the expected analytic estimate.
;   The test is passed if simulation event trigger differs from the expected value by no more than 2%
;
;-
pro stx_scenario_timefilter__test::test_triggers_low


  found_trigger_rate = (self.found_trigger_rate)[1]
  
  expected_trigger_rate = [35094.]
  range = [843.]
  
  expected_trigger_ll = expected_trigger_rate - range
  expected_trigger_ul = expected_trigger_rate + range
    
  
  mess = 'Expected ' + strtrim(expected_trigger_rate,2) + ' triggers per 4 second interval but found '$
    + strtrim(found_trigger_rate,2) +' triggers per 4 second interval but found '
    
  assert_true,((found_trigger_rate ge expected_trigger_ll) and(found_trigger_rate le expected_trigger_ul)), mess
end


;+
;
; :description:
;
;   this procedure compares event rate after time filtering for an initial photon flux of 5x10^5 photons
;   per second per cm2 to the expected analytic estimate.
;   The test is passed if simulation event rate differs from the expected value by no more than 2%
;
;-
pro stx_scenario_timefilter__test::test_coincidence_intermediate

  found_event_rate = (self.found_event_rate)[2]
  
  expected_event_rate = [ 1254447.]
  range = [5040.]
  
  expected_event_ll = expected_event_rate - range
  expected_event_ul = expected_event_rate + range
  
  mess = 'Expected ' + strtrim(expected_event_rate,2) + ' events per 4 second interval but found '$
    + strtrim(found_event_rate,2) +' events per 4 second interval but found '
    
  assert_true,((found_event_rate ge expected_event_ll) and(found_event_rate le expected_event_ul)),mess
end


;+
;
; :description:
;
;   this procedure compares the trigger rate after time filtering for an initial photon flux of 5x10^5 photons
;   per second per cm2 to the expected analytic estimate.
;   The test is passed if simulation event trigger differs from the expected value by no more than 2%
;
;-
pro stx_scenario_timefilter__test::test_triggers_intermediate


  found_trigger_rate = (self.found_trigger_rate)[2]
  
  expected_trigger_rate = [1321991.]
  range = [5174.]
  
  expected_trigger_ll = expected_trigger_rate - range
  expected_trigger_ul = expected_trigger_rate + range
  
  mess = 'Expected ' + strtrim(expected_trigger_rate,2) + ' triggers per 4 second interval but found '$
    + strtrim(found_trigger_rate,2) +' triggers per 4 second interval but found '
    
  assert_true,((found_trigger_rate ge expected_trigger_ll)and(found_trigger_rate le expected_trigger_ul)),mess
end

;+
;
; :description:
;
;   this procedure compares event rate after time filtering for an initial photon flux of 1x10^6 photons
;   per second per cm2 to the expected analytic estimate.
;   The test is passed if simulation event rate differs from the expected value by no more than 2%
;
;-
pro stx_scenario_timefilter__test::test_coincidence_moderate

  found_event_rate = (self.found_event_rate)[3]
  
  expected_event_rate = [1904331.]
  range =[6210.]
  
  expected_event_ll = expected_event_rate - range
  expected_event_ul = expected_event_rate + range
  
  mess = 'Expected ' + strtrim(expected_event_rate,2) + ' events per 4 second interval but found '$
    + strtrim(found_event_rate,2) +' events per 4 second interval but found '
    
  assert_true,((found_event_rate ge expected_event_ll)and(found_event_rate le expected_event_ul)),mess
end


;+
;
; :description:
;
;   this procedure compares the trigger rate after time filtering for an initial photon flux of 1x10^6 photons
;   per second per cm2 to the expected analytic estimate.
;   The test is passed if simulation event trigger differs from the expected value by no more than 2%
;
;-
pro stx_scenario_timefilter__test::test_triggers_modetrate

  found_trigger_rate = (self.found_trigger_rate)[3]
  
  expected_trigger_rate = [2114223.]
  range =[6543.]
  
  expected_trigger_ll = expected_trigger_rate - range
  expected_trigger_ul = expected_trigger_rate + range
  
  mess = 'Expected ' + strtrim(expected_trigger_rate,2) + ' triggers per 4 second interval but found '$
    + strtrim(found_trigger_rate,2) +' triggers per 4 second interval but found '
    
  assert_true,((found_trigger_rate ge expected_trigger_ll)and(found_trigger_rate le expected_trigger_ul)),mess
end



;+
;
; :description:
;
;   this procedure compares event rate after time filtering for an initial photon flux of 2x10^6 photons
;   per second per cm2 to the expected analytic estimate.
;   The test is passed if simulation event rate differs from the expected value by no more than 2%
;
;-
pro stx_scenario_timefilter__test::test_coincidence_high

  found_event_rate = (self.found_event_rate)[4]
  
  expected_event_rate = [2453035.]
  range = [7048.]
  
  expected_event_ll = expected_event_rate - range
  expected_event_ul = expected_event_rate + range
  
  mess = 'Expected ' + strtrim(expected_event_rate,2) + ' events per 4 second interval but found '$
    + strtrim(found_event_rate,2) +' events per 4 second interval but found '
    
  assert_true,((found_event_rate ge expected_event_ll)and(found_event_rate le expected_event_ul)),mess
end


;+
;
; :description:
;
;   this procedure compares the trigger rate after time filtering for an initial photon flux of 2x10^6 photons
;   per second per cm2 to the expected analytic estimate.
;   The test is passed if simulation event trigger differs from the expected value by no more than 2%
;
;-
pro stx_scenario_timefilter__test::test_triggers_high

  found_trigger_rate = (self.found_trigger_rate)[4]
  
  expected_trigger_rate = [3021098.]
  range = [7822.]
  
  expected_trigger_ll = expected_trigger_rate - range
  expected_trigger_ul = expected_trigger_rate + range
  
  mess = 'Expected ' + strtrim(expected_trigger_rate,2) + ' triggers per 4 second interval but found '$
    + strtrim(found_trigger_rate,2) +' triggers per 4 second interval but found '
    
  assert_true,((found_trigger_rate ge expected_trigger_ll)and(found_trigger_rate le expected_trigger_ul)),mess
end





pro stx_scenario_timefilter__test__define
  compile_opt idl2, hidden
  
  void = { $
    stx_scenario_timefilter__test, $
    found_event_rate: fltarr(5), $
    found_trigger_rate: fltarr(5), $
    found_readout_rate: fltarr(5), $
    found_unfiltered_rate: fltarr(5), $
    inherits stx_scenario_test }
end
