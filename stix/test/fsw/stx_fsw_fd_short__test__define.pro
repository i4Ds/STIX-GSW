;+
; :file_comments:
;   This is a test class for scenario-based testing; specifically the flare detection test
;
; :categories:
;   data simulation, flight software simulator, software, testing
;
; :examples:
;   iut_test_runner('stx_fsw_fd_short__test', keep_detector_eventlist=0b, show_fsw_plots=0b)
;   iut_test_runner('stx_fsw_fd_short__test')
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
;                              test_thermal_long
;                              test_thermal_short
;                              test_nonthermal_long
;                              test_nonthermal_short
;
;   10-Feb-2016 - ECMD (Graz), minor changes to reflect updated scenario file
;                              tolerance for nonthermal threshold2 tests increased to account for spread in background
;   10-may-2016, Laszlo I. Etesi (FHNW), minor updates to accomodate structure changes
;
;-



function stx_fsw_fd_short__test::init, _extra=extra

  self.sequence_name = 'stx_scenario_flare_detection_short_test'
  self.test_name = 'AX_QL_TEST_FD'
  self.configuration_file = 'stx_flight_software_simulator_ql_fd.xml'
  setenv, 'WRITE_CALIBRATION_SPECTRUM=false'

  return, self->stx_fsw__test::init(_extra=extra)
end

;+
;
; :description:
;
;   this procedure compares the number of intervals the flare flag is active
;   to the number of sources in the scenario.
;
;-
pro stx_fsw_fd_short__test::test_flag_number
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  
  flare_flag = flare_flag_str.flare_flag
  flare_flag[75:125] = 0

  ff_positive = flare_flag < 1

  n_expected_flags = 4

  status = 1 + ff_positive - shift([ff_positive,0],1)
  num_flags = n_elements(where(status eq 2))

  
  mess = 'Flag number test failure - Expected number of flags: ' + strtrim(n_expected_flags,2) +$
    ', but found number of flags: ' + strtrim(num_flags,2)

  assert_equals, num_flags, n_expected_flags, mess
  
end


pro stx_fsw_fd_short__test::test_flag_number_tm
  
  n_expected_flags = 4

  self.tmtc_reader->getdata, asw_ql_flare_flag_location=ffl_tm, solo_packet=solo_packets
  flare_flag = ffl_tm[0].flare_flag


  flare_flag[75+self.t_shift:125+self.t_shift] = 0

  ff_positive = flare_flag < 1

  status = 1 + ff_positive - shift([ff_positive,0],1)
  num_flags = n_elements(where(status eq 2))


  mess = 'Flag number test failure - Expected number of flags: ' + strtrim(n_expected_flags,2) +$
    ', but found number of flags: ' + strtrim(num_flags,2)

  assert_equals, num_flags, n_expected_flags, mess
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
pro stx_fsw_fd_short__test::test_flag_starts
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = flare_flag_str.flare_flag
  flare_flag[75:125] = 0

  ff_positive = flare_flag < 1

  status = 1 + ff_positive - shift([ff_positive,0],1)

  start_sim = where(status eq 2)
  num_flags = 4
  st_pred = [31.,44.,130,149]

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
;   this procedure compares the start intervals for the simulated flare flag
;   to the expected start intervals estimated by the _estimate_scenario_counts module
;   The test is passed if the start intervals differ by no more than 2
;
;-
pro stx_fsw_fd_short__test::test_flag_starts_tm
  self.tmtc_reader->getdata, asw_ql_flare_flag_location=ffl_tm, solo_packet=solo_packets
  flare_flag = ffl_tm[0].flare_flag
 
  flare_flag[75+self.t_shift:125+self.t_shift] = 0

  ff_positive = flare_flag < 1

  status = 1 + ff_positive - shift([ff_positive,0],1)

  start_sim = where(status eq 2)
  num_flags = 4
  st_pred = [31.,44.,130,149] + self.t_shift

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
pro stx_fsw_fd_short__test::test_flag_end
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = flare_flag_str.flare_flag
  flare_flag[75:125] = 0
  ff_positive = flare_flag <1
tol = 4

  status = 1 + ff_positive - shift([ff_positive,0],1)
  end_sim = where(status eq 0)

  num_flags = 4
  end_pred = [38,58,132,157]

  agree = where(end_sim le end_pred+tol and end_sim ge end_pred-tol,count)

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
;   this procedure compares the end intervals for the simulated flare flag
;   to the expected end intervals estimated by the _estimate_scenario_counts module
;   The test is passed if the start intervals differ by no more than 2
;
;-
pro stx_fsw_fd_short__test::test_flag_end_tm

  self.tmtc_reader->getdata, asw_ql_flare_flag_location=ffl_tm, solo_packet=solo_packets
  flare_flag = ffl_tm[0].flare_flag

  flare_flag[75+self.t_shift:125+self.t_shift] = 0

  ff_positive = flare_flag <1
  tol = 4

  status = 1 + ff_positive - shift([ff_positive,0],1)
  end_sim = where(status eq 0)

  num_flags = 4
  end_pred = [38,58,132,157] + self.t_shift

  agree = where(end_sim le end_pred+tol and end_sim ge end_pred-tol,count)

  mess = 'Flag deactivation test failure: ' + strtrim(count,2) + $
    ' out of ' + strtrim(num_flags,2) + ' intervals match.'  +$
    string(13B) + 'Expected deactivation indices: ' + strjoin(trim(end_pred),",") +$
    string(13B) + 'but found deactivation indices: ' + strjoin(trim(end_sim),",")


  assert_true, count - num_flags ge 0,mess
end

;
;;+
;;
;; :description:
;;
;;   this procedure compares the duration of the simulated flare flag
;;   to the duration expected by the _estimate_scenario_counts module
;;   The test is passed if the durations of each interval differ by no more than 2
;;
;;-
;pro stx_fsw_fd_short__test::test_flag_length
;  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
;  flare_flag = flare_flag_str.flare_flag
;  ff_positive = flare_flag <1
;  status = 1 + ff_positive - shift([ff_positive,0],1)
;
;  ff_start = where(status eq 2)
;  ff_end = where(status eq 0)
;  duration = ff_end - ff_start
;
;  num_flags = 4
;  dur_pred = [15,8,15,7]
;
;  agree = where(duration le dur_pred+2 and duration ge dur_pred-2,count)
;
;  mess = 'Flag duration test failure: ' + strtrim(count,2) + $
;    ' out of ' + strtrim(num_flags,2) + ' intervals match.'  +$
;    string(13B) + 'Expected durations: ' + strjoin(trim(dur_pred),",") +$
;    string(13B) + 'but found durations: ' + strjoin(trim(duration),",")
;
;  assert_true, count - num_flags ge 0, mess
;end

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
pro stx_fsw_fd_short__test::test_flag_positve
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = flare_flag_str.flare_flag
  flare_flag[75:125] = 0

  pos_sim = flare_flag < 1

  pos_pred = bytarr(n_elements(pos_sim))

  st_pred = [31.,44.,130,150]

  dur_pred = [7,14,3,8]

  for i=0, n_elements(st_pred)-1 do pos_pred[st_pred[i]] = replicate(1b, dur_pred[i])

  agree = where(pos_sim eq pos_pred,count)

  frac_match = float(count)/n_elements(pos_sim)

  mess = 'Flag positive test failure: ' +$
    string(13B) + 'Fraction of matching bins is: ' + string(frac_match,format='(F0.2)') +$
    string(13B) + 'Expected flag array:' + strjoin(trim(fix(pos_pred)),",") +$
    string(13B) + 'but found flag array: ' + strjoin(trim(fix(pos_sim)),",")

  assert_true,  frac_match ge  0.95, mess
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
pro stx_fsw_fd_short__test::test_flag_positve_tm
  self.tmtc_reader->getdata, asw_ql_flare_flag_location=ffl_tm, solo_packet=solo_packets
  flare_flag = ffl_tm[0].flare_flag

  flare_flag[75+self.t_shift:125+self.t_shift] = 0

  pos_sim = flare_flag < 1

  pos_pred = bytarr(n_elements(pos_sim))

  st_pred = [31.,44.,130,150]+self.t_shift

  dur_pred = [7,14,3,8]

  for i=0, n_elements(st_pred)-1 do pos_pred[st_pred[i]] = replicate(1b, dur_pred[i])

  agree = where(pos_sim eq pos_pred,count)

  frac_match = float(count)/n_elements(pos_sim)

  mess = 'Flag positive test failure: ' +$
    string(13B) + 'Fraction of matching bins is: ' + string(frac_match,format='(F0.2)') +$
    string(13B) + 'Expected flag array:' + strjoin(trim(fix(pos_pred)),",") +$
    string(13B) + 'but found flag array: ' + strjoin(trim(fix(pos_sim)),",")

  assert_true,  frac_match ge  0.95, mess
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
pro stx_fsw_fd_short__test::test_thermal_long
  tolerance = 1
  mins = 20
  maxs = 50

  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)[mins:maxs]
  therm_lon_base_sim = (flare_flag and 3B)

  expect = 31 - mins

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
;   for the thermal energy band using the long baseline changes from 0 to 1
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_fsw_fd_short__test::test_thermal_long_tm
  tolerance = 1
  mins = 20 + self.t_shift
  maxs = 50 + self.t_shift

  self.tmtc_reader->getdata, asw_ql_flare_flag_location=ffl_tm, solo_packet=solo_packets
  flare_flag = (ffl_tm[0].flare_flag)[mins:maxs]
  
  therm_lon_base_sim = (flare_flag and 3B)
  
  ;TODO n.h. add self.t_shift ?
  expect = 31 - mins

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
;   for the thermal energy band using the short baseline changes from 0 to 1
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_fsw_fd_short__test::test_thermal_short
  mins = 125
  maxs = 150
  tolerance = 1

  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)[mins:maxs]
  therm_short_base =(ishft(flare_flag,-2)and 3B)

  expect = 130 - mins

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
;   for the thermal energy band using the short baseline changes from 0 to 1
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_fsw_fd_short__test::test_thermal_short_tm
  mins = 125 + self.t_shift
  maxs = 150 + self.t_shift
  tolerance = 1

  self.tmtc_reader->getdata, asw_ql_flare_flag_location=ffl_tm, solo_packet=solo_packets
  flare_flag = (ffl_tm[0].flare_flag)[mins:maxs]

  
  therm_short_base =(ishft(flare_flag,-2)and 3B)
  
  ;TODO n.h. add self.t_shift ?
  expect = 130 - mins

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
;   for the nonthermal energy band using the long baseline changes from 0 to 1
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_fsw_fd_short__test::test_nonthermal_long
  mins = 30
  maxs = 70
  tolerance = 1

  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)[mins:maxs]
  
  nontherm_long_base_sim =(ishft(flare_flag,-4)and 3B)

  expect = 44 - mins

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
;   for the nonthermal energy band using the long baseline changes from 0 to 1
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_fsw_fd_short__test::test_nonthermal_long_tm
  mins = 30 + self.t_shift
  maxs = 70 + self.t_shift
  tolerance = 1

  self.tmtc_reader->getdata, asw_ql_flare_flag_location=ffl_tm, solo_packet=solo_packets
  flare_flag = (ffl_tm[0].flare_flag)[mins:maxs]  
  
  nontherm_long_base_sim =(ishft(flare_flag,-4)and 3B)

  ;TODO n.h. add self.t_shift ?
  expect = 44 - mins

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
;   for the nonthermal energy band using the short baseline changes from 0 to 1
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_fsw_fd_short__test::test_nonthermal_short
  mins = 145
  maxs = 155
  tolerance = 1

  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)[mins:maxs]
  nontherm_short_base_sim =(ishft(flare_flag,-6)and 3B)

  expect = 150 - mins

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
;   for the nonthermal energy band using the short baseline changes from 0 to 1
;   The test is passed if this change is within 2 bins of the expected value for
;   both sources tested.
;
;-
pro stx_fsw_fd_short__test::test_nonthermal_short_tm
  mins = 145+ self.t_shift
  maxs = 155+ self.t_shift
  tolerance = 1

  self.tmtc_reader->getdata, asw_ql_flare_flag_location=ffl_tm, solo_packet=solo_packets
  flare_flag = (ffl_tm[0].flare_flag)[mins:maxs]
  
  nontherm_short_base_sim =(ishft(flare_flag,-6)and 3B)

  ;TODO n.h. add self.t_shift ?
  expect = 150 - mins

  found = min(where(nontherm_short_base_sim gt 0))

  agree = where(found le expect + tolerance and found ge expect - tolerance , count )

  mess = 'Flare magnitude index nonthermal short baseline - ' +$
    string(13B) + ' minimum start test failure: ' +$
    string(13B) + 'Expected start indices:' + strjoin(trim(fix(expect)),",") +$
    string(13B) + 'but found start indices: ' + strjoin(trim(fix(found)),",")

  assert_true, count, mess
end


pro stx_fsw_fd_short__test::beforeclass

  self->stx_fsw__test::beforeclass

  self.exepted_range = 0.05
  self.plots = list()


  self.fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine

  lc =  total(lightcurve.accumulated_counts,1)
  start = min(where(lc gt 100))
  self.t_shift_sim = start
  
  
  if self.show_plot then begin
    lc_plot = obj_new('stx_plot')
   
    a = lc_plot.create_stx_plot(stx_construct_lightcurve(from=lightcurve), /lightcurve, /add_legend, title="Sim Lightcurve Plot", ylog=1)
   
    self.plots->add, lc_plot
  endif

  if ~file_exist('ax_tmtc.bin') then begin
    tmtc_data = {$
      QL_LIGHT_CURVES : 1, $
      QL_FLARE_FLAG_LOCATION : 1 $
    }

    print, self.fsw->getdata(output_target="stx_fsw_tmtc", filename='ax_tmtc.bin', _extra=tmtc_data)
  end


  self.tmtc_reader = stx_telemetry_reader(filename = "ax_tmtc.bin", /scan_mode, /merge_mode)
  self.tmtc_reader->getdata, statistics = statistics
  self.statistics = statistics

  self.tmtc_reader->getdata, asw_ql_lightcurve=ql_lightcurves,  solo_packet=solo_packets
  ql_lightcurve = stx_construct_lightcurve(from=ql_lightcurves[0])
  
  if self.show_plot then begin
    lc_plot2 = obj_new('stx_plot')
    
   
    
    a = lc_plot2.create_stx_plot(ql_lightcurve, /lightcurve, /add_legend, title="AX Lightcurve Plot", ylog=1)
   
    self.plots->add, lc_plot2
    
    
    self.tmtc_reader->getdata, fsw_m_coarse_flare_locator=flare_locator_blocks, fsw_m_flare_flag=flare_flag_blocks, solo_packets=sp

    coarse_flare_location = flare_locator_blocks[0]
    flare_flag = flare_flag_blocks[0]
    
    rate_control = { $
      type      : "rcr" , $
      rcr       : ql_lightcurves[0].RATE_CONTROL_REGIME, $
      time_axis : ql_lightcurve.time_axis $
    }
    
    state_plot_object = obj_new('stx_state_plot')


    current_time = isa(flare_flag) ? flare_flag.time_axis.time_start[-1] : rate_control.time_axis.time_start[-1]
    state_plot_start_time = isa(flare_flag) ? flare_flag.time_axis.time_start[0] : rate_control.time_axis.time_start[0]

    state_plot_object.plot, flare_flag=flare_flag, rate_control=rate_control, current_time=current_time, $
      start_time=state_plot_start_time, coarse_flare_location=coarse_flare_location, dimensions=[1260,350], /add_legend, current_window = window()

    self.plots->add, state_plot_object
    
  endif


  stx_sim_create_rcr_tc, self.conf

  default, directory , getenv('STX_DET')
  default, og_filename, 'offset_gain_table.csv'
  default, eb_filename, 'EnergyBinning20150615.csv'

  stx_sim_create_elut, og_filename=og_filename, eb_filename=eb_filename, directory = directory

  stx_sim_create_ql_tc, self.conf

  get_lun,lun
  openw, lun, "test_custom.tcl"
  printf, lun, 'syslog "running custom script for CFL test"'
  printf, lun, 'source [file join [file dirname [info script]] "TC_237_10_RCR.tcl"]'
  free_lun, lun


  lc =  total(ql_lightcurve.DATA,1)
  start = min(where(lc gt 100))
  self.t_shift = start


;  path = "D:\Temp\v20170123\AX_QL_TEST_FD\"
;
;  restore, filename=concat_dir(path, "fsw_conf.sav"), /verb
;
;  self.conf = confManager
;  
;  
;  restore, filename=concat_dir(path, "fsw.sav"), /verb
;  self.fsw    = fsw
;  
;  ;fsw-simulator: ql_tmtc.bin
;  ;AX: D1-2_AX_20180321_1400.bin
;  self.tmtc_reader = stx_telemetry_reader(filename = concat_dir(path, "ql_tmtc.bin"), /scan_mode, /merge_mode)
;  self.tmtc_reader->getdata, statistics = statistics
;  self.statistics = statistics
;
;
;  self.exepted_range = 0.05
;  self.plots = list()
;  self.show_plot = 0
;  
;  self.tmtc_reader->getdata, asw_ql_lightcurve=ql_lightcurves,  solo_packet=solo_packets
;  ql_lightcurve = ql_lightcurves[0]
; 
;    
;  self.t_shift = min(where(total(ql_lightcurve.counts,1) gt 0))
;  
;  v = stx_offset_gain_reader("offset_gain_table.csv", directory = concat_dir(path, "stix_conf\") , /reset)

end


;+
; cleanup at object destroy
;-
pro stx_fsw_fd_short__test::afterclass
  v = stx_offset_gain_reader(/reset)
  destroy, self.tmtc_reader
end


pro stx_fsw_fd_short__test__define
  compile_opt idl2, hidden

  void = { $
    stx_fsw_fd_short__test, $
   inherits stx_fsw__test }
end
