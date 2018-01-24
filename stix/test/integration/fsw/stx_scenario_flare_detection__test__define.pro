;+
; :file_comments:
;   This is a test class for scenario-based testing; specifically the flare detection test
;
; :categories:
;   data simulation, flight software simulator, software, testing
;
; :examples:
;   iut_test_runner('stx_scenario_flare_detection__test', keep_detector_eventlist=0b, show_fsw_plots=0b)
;   iut_test_runner('stx_scenario_flare_detection__test')
;
; :history:
;   05-Feb-2015 - Laszlo I. Etesi (FHNW), initial release
;   27-Feb-2015 - ECMD (Graz), Simplified flare detection test
;                              added the testing modules:
;                              test_flag_number
;                              test_flag_starts
;                              test_flag_end
;                              test_flag_length
;                              test_flag_positve
;                              test_thermal_long_minimum
;                              test_thermal_long_threshold1
;                              test_thermal_long_threshold2
;                              test_thermal_short_minimum
;                              test_thermal_short_threshold1
;                              test_thermal_short_threshold2
;                              test_nonthermal_long_minimum
;                              test_nonthermal_long_threshold1
;                              test_nonthermal_long_threshold2
;                              test_nonthermal_short_minimum
;                              test_nonthermal_short_threshold1
;                              test_nonthermal_short_threshold2
;   10-Feb-2016 - ECMD (Graz), minor changes to reflect updated scenario file
;                              tolerance for nonthermal threshold2 tests increased to account for spread in background
;   10-may-2016, Laszlo I. Etesi (FHNW), minor updates to accomodate structure changes
;
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
function stx_scenario_flare_detection__test::init, _extra=extra
  self.test_name = 'flare_detection'
  self.test_type = 'basic'
  
  return, self->stx_scenario_test::init(_extra=extra)
end



;+
;
; :description:
;
;   this procedure compares the number of intervals the flare flag is active
;   to the number of sources in the scenario.
;
;-
pro stx_scenario_flare_detection__test::test_flag_number
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = flare_flag_str.flare_flag
  ff_positive = flare_flag < 1

  status = 1 + ff_positive - shift([ff_positive,0],1)
  num_flags = n_elements(where(status eq 2))
  
  mess = 'Flag number test failure - Expected number of flags: ' + strtrim(4,2) +$
    ', but found number of flags: ' + strtrim(num_flags,2)
    
  assert_equals, num_flags, 4, mess
end




;+
;
; :description:
;
;   this procedure compares the start intervals for the simulated flare flag
;   to the expected start intervals estimated by the _estimate_scenario_counts module
;   The test is passed if the start intervals differ by no more than 2
;
;-
pro stx_scenario_flare_detection__test::test_flag_starts
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = flare_flag_str.flare_flag
  ff_positive = flare_flag <1

  status = 1 + ff_positive - shift([ff_positive,0],1)
  
  start_sim = where(status eq 2)
  num_flags = 4
  st_pred = [30.,60.,98.,128]
  
  agree = where(start_sim le st_pred+1 and start_sim ge st_pred-1,count)
  
  
  mess = 'Flag activation test failure: ' + strtrim(count,2) + $
    ' out of ' + strtrim(num_flags,2) + ' intervals match.'  +$
    string(13B) + 'Expected activation indices: ' + strjoin(trim(st_pred),",") +$
    string(13B) + 'but found activation indices: ' + strjoin(trim(start_sim),",")
    
  assert_true, count - num_flags ge 0, mess
end

;+
;
; :description:
;
;   this procedure compares the end intervals for the simulated flare flag
;   to the expected end intervals estimated by the _estimate_scenario_counts module
;   The test is passed if the start intervals differ by no more than 2
;
;-
pro stx_scenario_flare_detection__test::test_flag_end
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = flare_flag_str.flare_flag
  ff_positive = flare_flag <1

  status = 1 + ff_positive - shift([ff_positive,0],1)
  end_sim = where(status eq 0)
  
  num_flags = 4
  end_pred = [45,68,113,135]
  
  agree = where(end_sim le end_pred+1 and end_sim ge end_pred-1,count)
  
  mess = 'Flag deactivation test failure: ' + strtrim(count,2) + $
    ' out of ' + strtrim(num_flags,2) + ' intervals match.'  +$
    string(13B) + 'Expected deactivation indices: ' + strjoin(trim(end_pred),",") +$
    string(13B) + 'but found deactivation indices: ' + strjoin(trim(end_sim),",")
    
    
  assert_true, count - num_flags ge 0,mess
end


;+
;
; :description:
;
;   this procedure compares the duration of the simulated flare flag
;   to the duration expected by the _estimate_scenario_counts module
;   The test is passed if the durations of each interval differ by no more than 2
;
;-
pro stx_scenario_flare_detection__test::test_flag_length
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = flare_flag_str.flare_flag
  ff_positive = flare_flag <1
  status = 1 + ff_positive - shift([ff_positive,0],1)
  
  ff_start = where(status eq 2)
  ff_end = where(status eq 0)
  duration = ff_end - ff_start
  
  num_flags = 4
  dur_pred = [15,8,15,7]
  
  agree = where(duration le dur_pred+2 and duration ge dur_pred-2,count)
  
  mess = 'Flag duration test failure: ' + strtrim(count,2) + $
    ' out of ' + strtrim(num_flags,2) + ' intervals match.'  +$
    string(13B) + 'Expected durations: ' + strjoin(trim(dur_pred),",") +$
    string(13B) + 'but found durations: ' + strjoin(trim(duration),",")
    
  assert_true, count - num_flags ge 0, mess
end

;+
;
; :description:
;
;   this procedure compares intervals where the simulated flare flag is
;   greater than 0 to those expected by the _estimate_scenario_counts module
;   The test is passed if the 95% of the bins for the simulated and estimated
;   flare flags match
;
;-
pro stx_scenario_flare_detection__test::test_flag_positve
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = flare_flag_str.flare_flag
  pos_sim = flare_flag < 1

  pos_pred = bytarr(n_elements(pos_sim))
  
  st_pred = [30,60,98,128]
  
  dur_pred = [15,8,15,7]
  
  for i=0, 3 do pos_pred[st_pred[i]] = replicate(1b, dur_pred[i])
  
  agree = where(pos_sim eq pos_pred,count)
  
  frac_match = float(count)/n_elements(pos_sim)
  
  mess = 'Flag positive test failure: ' +$
    string(13B) + 'Fraction of matching bins is: ' + string(frac_match,format='(F0.2)') +$
    string(13B) + 'Expected flag array:' + strjoin(trim(fix(pos_pred)),",") +$
    string(13B) + 'but found flag array: ' + strjoin(trim(fix(pos_sim)),",")
    
  assert_true,  frac_match ge  0.95,mess
end


;+
;
; :description:
;
;   this procedure the calculates where the simulated flare magnitude index
;   for the thermal energy band using the long baseline changes from 0 to 1
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_scenario_flare_detection__test::test_thermal_long_minimum
  tolerance = 1
  mins = 15
  maxs = 53
  
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)[mins:maxs]
  therm_lon_base_sim = (flare_flag and 3B)
  
  expect = 30 - mins
  
  found = min(where(therm_lon_base_sim gt 0))
  
agree = where(found le expect + tolerance and found ge expect - tolerance , count )
  
  mess = 'Flare magnitude index thermal long baseline - ' +$
    string(13B) + ' minimum start test failure: ' +$
    string(13B) + 'Expected start indices:' + strjoin(trim(fix(expect)),",") +$
    string(13B) + 'but found start indices: ' + strjoin(trim(fix(found)),",")
    
    
  assert_true, count, mess
end


;+
;
; :description:
;
;   this procedure the calculates where the simulated flare magnitude index
;   for the thermal energy band using the long baseline changes from 1 to 2
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_scenario_flare_detection__test::test_thermal_long_threshold1
  tolerance = 1
  mins = 15
  maxs = 53
  
  threshold = 1
  
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)[mins:maxs]
  therm_lon_base_sim = (flare_flag and 3B)
  therm_lon_base_sim -= threshold
  
  expect = 35 - mins
  
  found = min(where(therm_lon_base_sim gt 0))
  
agree = where(found le expect + tolerance and found ge expect - tolerance , count )
  
  mess = 'Flare magnitude index thermal long baseline - ' +$
    string(13B) + ' threshold 1 start test failure: ' +$
    string(13B) + 'Expected start indices:' + strjoin(trim(fix(expect)),",") +$
    string(13B) + 'but found start indices: ' + strjoin(trim(fix(found)),",")
    
    
  assert_true, count, mess
end

;+
;
; :description:
;
;   this procedure the calculates where the simulated flare magnitude index
;   for the thermal energy band using the long baseline changes from 2 to 3
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_scenario_flare_detection__test::test_thermal_long_threshold2

  tolerance = 1
  mins = 15
  maxs = 53
  
  threshold = 2
  
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)[mins:maxs]
  therm_lon_base_sim = (flare_flag and 3B)
  therm_lon_base_sim -= threshold
  
  expect = 40 - mins
  
  found = min(where(therm_lon_base_sim gt 0))
  
agree = where(found le expect + tolerance and found ge expect - tolerance , count )
  
  mess = 'Flare magnitude index thermal long baseline - ' +$
    string(13B) + ' threshold 2 start test failure: ' +$
    string(13B) + 'Expected start indices:' + strjoin(trim(fix(expect)),",") +$
    string(13B) + 'but found start indices: ' + strjoin(trim(fix(found)),",")
    
  assert_true, count, mess
end

;+
;
; :description:
;
;   this procedure the calculates where the simulated flare magnitude index
;   for the thermal energy band using the short baseline changes from 0 to 1
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_scenario_flare_detection__test::test_thermal_short_minimum
  mins = 53
  maxs = 83
    tolerance = 1
    
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)[mins:maxs]
  therm_short_base =(ishft(flare_flag,-2)and 3B)
  
  expect = 60 - mins
  
  found = min(where(therm_short_base gt 0))
  
agree = where(found le expect + tolerance and found ge expect - tolerance , count )
  
  mess = 'Flare magnitude index thermal short baseline - ' +$
    string(13B) + ' minimum start test failure: ' +$
    string(13B) + 'Expected start indices:' + strjoin(trim(fix(expect)),",") +$
    string(13B) + 'but found start indices: ' + strjoin(trim(fix(found)),",")
    
  assert_true, count, mess
end



;+
;
; :description:
;
;   this procedure the calculates where the simulated flare magnitude index
;   for the thermal energy band using the short baseline changes from 1 to 2
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_scenario_flare_detection__test::test_thermal_short_threshold1
  threshold = 1
  mins = 53
  maxs = 83
  tolerance = 1
    
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)[mins:maxs]
  therm_short_base =(ishft(flare_flag,-2)and 3B)
  therm_short_base -= threshold
  
  expect = 64 - mins
  
  found = min(where(therm_short_base gt 0))
  
agree = where(found le expect + tolerance and found ge expect - tolerance , count )
  
  mess = 'Flare magnitude index thermal short baseline - ' +$
    string(13B) + ' threshold 1 start test failure: ' +$
    string(13B) + 'Expected start indices:' + strjoin(trim(fix(expect)),",") +$
    string(13B) + 'but found start indices: ' + strjoin(trim(fix(found)),",")
    
  assert_true, count, mess
end


;+
;
; :description:
;
;   this procedure the calculates where the simulated flare magnitude index
;   for the thermal energy band using the short baseline changes from 2 to 3
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_scenario_flare_detection__test::test_thermal_short_threshold2
  threshold = 2
  mins = 53
  maxs = 83
  tolerance = 1
    
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)[mins:maxs]
  therm_short_base =(ishft(flare_flag,-2)and 3B)
  therm_short_base -= threshold
  
  expect = 66 - mins
  
  found = min(where(therm_short_base gt 0))
  
agree = where(found le expect + tolerance and found ge expect - tolerance , count )
  
  mess = 'Flare magnitude index thermal short baseline - ' +$
    string(13B) + ' threshold 2 start test failure: ' +$
    string(13B) + 'Expected start indices:' + strjoin(trim(fix(expect)),",") +$
    string(13B) + 'but found start indices: ' + strjoin(trim(fix(found)),",")
    
  assert_true, count, mess
end





;+
;
; :description:
;
;   this procedure the calculates where the simulated flare magnitude index
;   for the nonthermal energy band using the long baseline changes from 0 to 1
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_scenario_flare_detection__test::test_nonthermal_long_minimum
  mins = 83
  maxs = 121
  tolerance = 1
    
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)[mins:maxs]
  nontherm_long_base_sim =(ishft(flare_flag,-4)and 3B)
  
  expect = 98 - mins
  
  found = min(where(nontherm_long_base_sim gt 0))
  
agree = where(found le expect + tolerance and found ge expect - tolerance , count )
  
  mess = 'Flare magnitude index nonthermal long baseline - ' +$
    string(13B) + ' minimum start test failure: ' +$
    string(13B) + 'Expected start indices:' + strjoin(trim(fix(expect)),",") +$
    string(13B) + 'but found start indices: ' + strjoin(trim(fix(found)),",")
    
  assert_true, count, mess
end


;+
;
; :description:
;
;   this procedure the calculates where the simulated flare magnitude index
;   for the nonthermal energy band using the long baseline changes from 1 to 2
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_scenario_flare_detection__test::test_nonthermal_long_threshold1
  threshold = 1
  mins = 83
  maxs = 121
  tolerance = 1
    
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)[mins:maxs]
  nontherm_long_base_sim =(ishft(flare_flag,-4)and 3B)
  nontherm_long_base_sim -= threshold
  
  expect = 105 - mins
  
  found = min(where(nontherm_long_base_sim gt 0))
  
agree = where(found le expect + tolerance and found ge expect - tolerance , count )
  
  mess = 'Flare magnitude index nonthermal long baseline - ' +$
    string(13B) + ' threshold 1 start test failure: ' +$
    string(13B) + 'Expected start indices:' + strjoin(trim(fix(expect)),",") +$
    string(13B) + 'but found start indices: ' + strjoin(trim(fix(found)),",")
    
  assert_true, count, mess
end


;+
;
; :description:
;
;   this procedure the calculates where the simulated flare magnitude index
;   for the nonthermal energy band using the long baseline changes from 2 to 3
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_scenario_flare_detection__test::test_nonthermal_long_threshold2
  threshold = 2
  mins = 83
  maxs = 121
  tolerance = 2
  
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)[mins:maxs]
  nontherm_long_base_sim =(ishft(flare_flag,-4)and 3B)
  nontherm_long_base_sim -= threshold
  
  expect = 108 - mins
  
  found = min(where(nontherm_long_base_sim gt 0))
  
  agree = where(found le expect + tolerance and found ge expect - tolerance , count )
  
  mess = 'Flare magnitude index nonthermal long baseline - ' +$
    string(13B) + ' threshold 2 start test failure: ' +$
    string(13B) + 'Expected start indices:' + strjoin(trim(fix(expect)),",") +$
    string(13B) + 'but found start indices: ' + strjoin(trim(fix(found)),",")
    
  assert_true, count, mess
end

;+
;
; :description:
;
;   this procedure the calculates where the simulated flare magnitude index
;   for the nonthermal energy band using the short baseline changes from 0 to 1
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_scenario_flare_detection__test::test_nonthermal_short_minimum
  mins = 121
  maxs = 139
  tolerance = 1
  
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)[mins:maxs]
  nontherm_short_base_sim =(ishft(flare_flag,-6)and 3B)
  
  expect = 128 - mins
  
  found = min(where(nontherm_short_base_sim gt 0))
  
agree = where(found le expect + tolerance and found ge expect - tolerance , count )
  
  mess = 'Flare magnitude index nonthermal short baseline - ' +$
    string(13B) + ' minimum start test failure: ' +$
    string(13B) + 'Expected start indices:' + strjoin(trim(fix(expect)),",") +$
    string(13B) + 'but found start indices: ' + strjoin(trim(fix(found)),",")
    
  assert_true, count, mess
end



;+
;
; :description:
;
;   this procedure the calculates where the simulated flare magnitude index
;   for the nonthermal energy band using the short baseline changes from 1 to 2
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_scenario_flare_detection__test::test_nonthermal_short_threshold1
  threshold = 1
  mins = 121
  maxs = 139
  tolerance = 1
  
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)[mins:maxs]
  nontherm_short_base_sim =(ishft(flare_flag,-6)and 3B)
  nontherm_short_base_sim -= threshold
  
  expect = 132 - mins
  
  found = min(where(nontherm_short_base_sim gt 0))
  
agree = where(found le expect + tolerance and found ge expect - tolerance , count )
  
  mess = 'Flare magnitude index nonthermal short baseline - ' +$
    string(13B) + ' threshold 1 start test failure: ' +$
    string(13B) + 'Expected start indices:' + strjoin(trim(fix(expect)),",") +$
    string(13B) + 'but found start indices: ' + strjoin(trim(fix(found)),",")
    
  assert_true, count, mess
end


;+
;
; :description:
;
;   this procedure the calculates where the simulated flare magnitude index
;   for the nonthermal energy band using the short baseline changes from 2 to 3
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_scenario_flare_detection__test::test_nonthermal_short_threshold2
  threshold = 2
  mins = 121
  maxs = 139
  tolerance = 2
  
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)[mins:maxs]
  nontherm_short_base_sim =(ishft(flare_flag,-6)and 3B)
  nontherm_short_base_sim -= threshold
  
  expect = 133 - mins
  
  found = min(where(nontherm_short_base_sim gt 0))
  
agree = where(found le expect + tolerance and found ge expect - tolerance , count )
  
  mess = 'Flare magnitude index nonthermal short baseline - ' +$
    string(13B) + ' threshold 2 start test failure: ' +$
    string(13B) + 'Expected start indices:' + strjoin(trim(fix(expect)),",") +$
    string(13B) + 'but found start indices: ' + strjoin(trim(fix(found)),",")
    
  assert_true, count, mess
end


; :description:
;
;   this procedure creates a new data simulation object; if a user configuration is present
;   that configuration will be applied
;   it differs from stx_scenario__test::_setup_fsw in that a structure containing flare_detection_past
;   data is restored so that the flare detection module will run correctly from the start of the scenario
;
;-
pro stx_scenario_flare_detection__test::_setup_fsw, fsw_user_config=fsw_user_config
  restore, concat_dir('STX_SIM','bglowpast.sav')
  past=p.past
  print,'past restored'

  self->stx_scenario_test::_setup_fsw, fsw_user_config=fsw_user_config, flare_detection_past=past
end



pro stx_scenario_flare_detection__test__define
  compile_opt idl2, hidden
  
  void = { $
    stx_scenario_flare_detection__test, $
    inherits stx_scenario_test }
end
