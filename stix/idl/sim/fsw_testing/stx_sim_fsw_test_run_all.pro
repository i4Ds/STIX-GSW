pro stx_sim_fsw_test_run_all
  version = 'v20170123' ;time2file(trim(ut_time(/to_local)), /seconds)
  seed = 1337
  test_root = 'D:\Temp'
  t_l = 1.35d-6
  t_r = 9.91d-6
  t_ig = 0.35d-6
  
  setenv, 'WRITE_CALIBRATION_SPECTRUM=false'
  
  goto, resume_here

  ; T1a - BEGIN **********************************************************************************************
  sequence_name = 'D1a-2'
  test_name = 'T1a'
  configuration_file = 'default'

  stx_sim_fsw_prep, test_name, sequence_name, configuration_file=configuration_file, seed=seed, test_root=test_root,$
    version=version, original_dir=original_dir, original_conf=original_conf, dss=dss, fsw=fsw

  stx_sim_fsw_run, dss, fsw, test_name, sequence_name, t_l=t_l, t_r=t_r, t_ig=t_ig

  fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  stx_plot, lightcurve, plot=plot

  save, dss, fsw, filename=test_name + '_dss-fsw.sav'

  ; restore original setting
  setenv, 'STX_CONF=' + original_conf
  cd, original_dir

  ; T1a - END ************************************************************************************************
;resume_here:
  ; T1b - BEGIN **********************************************************************************************
  sequence_name = 'D1b-2'
  test_name = 'T1b'
  configuration_file = 'default'

  stx_sim_fsw_prep, test_name, sequence_name, configuration_file=configuration_file, seed=seed, test_root=test_root, $
    version=version, original_dir=original_dir, original_conf=original_conf, dss=dss, fsw=fsw

  stx_sim_fsw_run, dss, fsw, test_name, sequence_name, t_l=t_l, t_r=t_r, t_ig=t_ig

  fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  stx_plot, lightcurve, plot=plot

  save, dss, fsw, filename=test_name + '_dss-fsw.sav'

  setenv, 'STX_CONF=' + original_conf
  cd, original_dir
stop
return
  ; D1_2 - END ************************************************************************************************
  ;resume_here:
  ; QL_FD - BEGIN **********************************************************************************************
  sequence_name = 'stx_scenario_flare_detection_short_test'
  test_name = 'AX_QL_TEST_FD'
  configuration_file = 'stx_flight_software_simulator_ql_fd.xml'

  stx_sim_fsw_prep, test_name, sequence_name, configuration_file=configuration_file, seed=seed, test_root=test_root, $
    version=version, original_dir=original_dir, original_conf=original_conf, dss=dss, fsw=fsw


  ;generate the DSS events for hardware testing
  tb = dss->getdata(output_target='scenario_length', scenario=sequence_name) / 4L  + 1
  eventlist = dss->getdata(output_target='stx_sim_detector_eventlist', time_bins=[0L,long(tb)], scenario=sequence_name, rate_control_regime=0, t_l=t_l, t_r=t_r, t_ig=t_ig)
  stx_sim_dss_events_writer, sequence_name + '.dssevs', eventlist.detector_events, constant=1850


  stx_sim_fsw_run, dss, fsw, test_name, sequence_name, t_l=t_l, t_r=t_r, t_ig=t_ig

  fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  stx_plot, lightcurve, plot=plot

  save, dss, fsw, filename=test_name + '_dss-fsw.sav'
  save, fsw, filename="fsw.sav"
  confManager = fsw->getconfigmanager()
  save, confManager, filename="fsw_conf.sav"

  tmtc_data = {$
    QL_LIGHT_CURVES : 1,$
    ql_flare_flag_location: 1 $
  }

  print, fsw->getdata(output_target="stx_fsw_tmtc", filename='ql_tmtc.bin', _extra=tmtc_data)

  setenv, 'STX_CONF=' + original_conf
  cd, original_dir
  stop
  return

  ; D1_2 - END ************************************************************************************************
  resume_here:
  ; QL_FD - BEGIN **********************************************************************************************
  sequence_name = 'AB'
  test_name = 'AX_SD_TEST_AB'
  configuration_file = 'stx_flight_software_simulator_d1_2.xml'

  stx_sim_fsw_prep, test_name, sequence_name, configuration_file=configuration_file, seed=seed, test_root=test_root, $
    version=version, original_dir=original_dir, original_conf=original_conf, dss=dss, fsw=fsw,OFFSET_GAIN_TABLE=OFFSET_GAIN_TABLE

  stx_sim_create_elut, OG_FILENAME=OFFSET_GAIN_TABLE, directory=concat_dir(getenv('STX_FSW'), concat_dir('rnd_seq_testing', 'stix_conf'))


  ;generate the DSS events for hardware testing
  ;tb = dss->getdata(output_target='scenario_length', scenario=sequence_name) / 4L  + 1
  ;eventlist = dss->getdata(output_target='stx_sim_detector_eventlist', time_bins=[0L,long(tb)], scenario=sequence_name, rate_control_regime=0, t_l=t_l, t_r=t_r, t_ig=t_ig)
  ;stx_sim_dss_events_writer, sequence_name + '.dssevs', eventlist.detector_events, constant=1850


  stx_sim_fsw_run, dss, fsw, test_name, sequence_name, t_l=t_l, t_r=t_r, t_ig=t_ig

  fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  stx_plot, lightcurve, plot=plot


  save, dss, fsw, filename=test_name + '_dss-fsw.sav'
  save, fsw, filename="fsw.sav"
  confManager = fsw->getconfigmanager()
  save, confManager, filename="fsw_conf.sav"

  skyFile = fsw->get(/cfl_cfl_lut)
  stx_sim_create_cfl_lut, CFL_LUT_FILENAMEPATH=skyFile

  tmtc_data = {$
    QL_LIGHT_CURVES : 1,$
    sd_xray_0: 1 ,$
    rel_flare_time : [0d,total(lightcurve.TIME_AXIS.duration)]$
  }

  print, fsw->getdata(output_target="stx_fsw_tmtc", filename='ql_tmtc.bin', _extra=tmtc_data)

  setenv, 'STX_CONF=' + original_conf
  cd, original_dir
  stop
  return


  ; QL_FD - END ************************************************************************************************
 
  ;resume_here:
  ; QL_CFL - BEGIN **********************************************************************************************
  sequence_name = 'stx_scenario_cfl_short_test'
  test_name = 'AX_QL_TEST_CFL'
  configuration_file = 'stx_flight_software_simulator_ql_fd.xml'
  OFFSET_GAIN_TABLE=-1
    
  
  
  
  stx_sim_fsw_prep, test_name, sequence_name, configuration_file=configuration_file, seed=seed, test_root=test_root, $
    version=version, original_dir=original_dir, original_conf=original_conf, dss=dss, fsw=fsw,OFFSET_GAIN_TABLE=OFFSET_GAIN_TABLE 

  stx_sim_create_elut, OG_FILENAME=OFFSET_GAIN_TABLE, directory=concat_dir(getenv('STX_FSW'), concat_dir('rnd_seq_testing', 'stix_conf'))
  
  
  ;generate the DSS events for hardware testing
  ;tb = dss->getdata(output_target='scenario_length', scenario=sequence_name) / 4L  + 1
  ;eventlist = dss->getdata(output_target='stx_sim_detector_eventlist', time_bins=[0L,long(tb)], scenario=sequence_name, rate_control_regime=0, t_l=t_l, t_r=t_r, t_ig=t_ig)
  ;stx_sim_dss_events_writer, sequence_name + '.dssevs', eventlist.detector_events, constant=1850


  stx_sim_fsw_run, dss, fsw, test_name, sequence_name, t_l=t_l, t_r=t_r, t_ig=t_ig

  fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  stx_plot, lightcurve, plot=plot
    

  save, dss, fsw, filename=test_name + '_dss-fsw.sav'
  save, fsw, filename="fsw.sav"
  confManager = fsw->getconfigmanager()
  save, confManager, filename="fsw_conf.sav"

  skyFile = fsw->get(/cfl_cfl_lut)
  stx_sim_create_cfl_lut, CFL_LUT_FILENAMEPATH=skyFile

  tmtc_data = {$
    QL_LIGHT_CURVES : 1,$
    ql_flare_flag_location: 1 $
  }

  print, fsw->getdata(output_target="stx_fsw_tmtc", filename='ql_tmtc.bin', _extra=tmtc_data)

  setenv, 'STX_CONF=' + original_conf
  cd, original_dir
  stop
  return

  ; QL_FD - END ************************************************************************************************ 

  
  ;resume_here:
 ; QL_RCR begin ************************************************************************************************
  sequence_name = 'D5a-1'
  test_name = 'AX_QL_TEST_RCR'
  configuration_file = 'stx_flight_software_simulator_ql_rcr.xml'

  stx_sim_fsw_prep, test_name, sequence_name, configuration_file=configuration_file, seed=seed, test_root=test_root,$
    version=version, original_dir=original_dir, original_conf=original_conf, dss=dss, fsw=fsw

  ;generate the DSS events for hardware testing
  tb = dss->getdata(output_target='scenario_length', scenario=sequence_name) / 4L  + 1
  eventlist = dss->getdata(output_target='stx_sim_detector_eventlist', time_bins=[0L,long(tb)], scenario=sequence_name, rate_control_regime=0, t_l=t_l, t_r=t_r, t_ig=t_ig)
  stx_sim_dss_events_writer, test_name + '.dssevs', eventlist.detector_events, constant=1850


  stx_sim_fsw_run, dss, fsw, test_name, sequence_name, t_l=t_l, t_r=t_r, t_ig=t_ig

  fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  stx_plot, lightcurve, plot=plot

   save, dss, fsw, filename=test_name + '_dss-fsw.sav'
  save, fsw, filename="fsw.sav"
  confManager = fsw->getconfigmanager()
  save, confManager, filename="fsw_conf.sav"
  
  tmtc_data = {$
    QL_LIGHT_CURVES : 1 $
  }

  print, fsw->getdata(output_target="stx_fsw_tmtc", filename='ql_tmtc.bin', _extra=tmtc_data)

  ; restore original setting
  setenv, 'STX_CONF=' + original_conf
  cd, original_dir
  stop
  
  ; QL_RCR END ************************************************************************************************

  
;
;resume_here:
  ; D1_2 - BEGIN **********************************************************************************************
  sequence_name = 'D1-2'
  test_name = 'AX_QL_TEST_1'
  configuration_file = 'stx_flight_software_simulator_d1_2.xml'

  stx_sim_fsw_prep, test_name, sequence_name, configuration_file=configuration_file, seed=seed, test_root=test_root, $
    version=version, original_dir=original_dir, original_conf=original_conf, dss=dss, fsw=fsw

  
  ;generate the DSS events for hardware testing
  ;tb = dss->getdata(output_target='scenario_length', scenario=sequence_name) / 4L  + 1
  ;eventlist = dss->getdata(output_target='stx_sim_detector_eventlist', time_bins=[0L,long(tb)], scenario=sequence_name, rate_control_regime=0, t_l=t_l, t_r=t_r, t_ig=t_ig)
  ;time_step=0.000000020d  ; 20ns
  ;c = where(eventlist.detector_events.RELATIVE_TIME - shift(eventlist.detector_events.RELATIVE_TIME,1) lt time_step,complement=t)
  stx_sim_dss_events_writer, sequence_name + '.dssevs', eventlist.detector_events, constant=1850

  
  stx_sim_fsw_run, dss, fsw, test_name, sequence_name, t_l=t_l, t_r=t_r, t_ig=t_ig
    
  fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  stx_plot, lightcurve, plot=plot

  save, dss, fsw, filename=test_name + '_dss-fsw.sav'
  save, fsw, filename="fsw.sav"
  confManager = fsw->getconfigmanager()
  save, confManager, filename="fsw_conf.sav"
  
  tmtc_data = {$
    QL_LIGHT_CURVES : 1,$
    QL_BACKGROUND_MONITOR: 1,$
    QL_CALIBRATION_SPECTRUM: 1,$
    QL_SPECTRA: 1,$      
    QL_VARIANCE: 1$
  }
  
  print, fsw->getdata(output_target="stx_fsw_tmtc", filename='ql_tmtc.bin', _extra=tmtc_data)

  setenv, 'STX_CONF=' + original_conf
  cd, original_dir
  stop
  return

  ; D1_2 - END ************************************************************************************************
  ;resume_here:
  ; D1_2 - BEGIN **********************************************************************************************
  sequence_name = 'D1-2_low'
  test_name = 'AX_QL_TEST_1_low'
  configuration_file = 'stx_flight_software_simulator_d1_2.xml'

  stx_sim_fsw_prep, test_name, sequence_name, configuration_file=configuration_file, seed=seed, test_root=test_root, $
    version=version, original_dir=original_dir, original_conf=original_conf, dss=dss, fsw=fsw


  ;generate the DSS events for hardware testing
  tb = dss->getdata(output_target='scenario_length', scenario=sequence_name) / 4L  + 1
  eventlist = dss->getdata(output_target='stx_sim_detector_eventlist', time_bins=[0L,long(tb)], scenario=sequence_name, rate_control_regime=0, t_l=t_l, t_r=t_r, t_ig=t_ig)
  ;time_step=0.000000020d  ; 20ns
  ;c = where(eventlist.detector_events.RELATIVE_TIME - shift(eventlist.detector_events.RELATIVE_TIME,1) lt time_step,complement=t)
  stx_sim_dss_events_writer, sequence_name + '.dssevs', eventlist.detector_events, constant=1850


  stx_sim_fsw_run, dss, fsw, test_name, sequence_name, t_l=t_l, t_r=t_r, t_ig=t_ig

  fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  stx_plot, lightcurve, plot=plot

  save, dss, fsw, filename=test_name + '_dss-fsw.sav'
  save, fsw, filename="fsw.sav"
  confManager = fsw->getconfigmanager()
  save, confManager, filename="fsw_conf.sav"

  tmtc_data = {$
    QL_LIGHT_CURVES : 1,$
    QL_BACKGROUND_MONITOR: 1,$
    QL_CALIBRATION_SPECTRUM: 1,$
    QL_SPECTRA: 1,$
    QL_VARIANCE: 1$
  }

  print, fsw->getdata(output_target="stx_fsw_tmtc", filename='ql_tmtc.bin', _extra=tmtc_data)

  setenv, 'STX_CONF=' + original_conf
  cd, original_dir
  stop
  return

  ; T1c - END ************************************************************************************************

  ; T2a - BEGIN **********************************************************************************************

  copy_from = 'T1a'
  copy_to = 'T2a'

  stx_sim_fsw_copy_test, copy_from, copy_to, concat_dir(test_root, version)

  ; T2a - END ************************************************************************************************

  ; T2b - BEGIN **********************************************************************************************

  sequence_name = 'D2-2'
  test_name = 'T2b'
  configuration_file = 'default'

  stx_sim_fsw_prep, test_name, sequence_name, configuration_file=configuration_file, seed=seed, test_root=test_root, $
    version=version, original_dir=original_dir, original_conf=original_conf, dss=dss, fsw=fsw

  stx_sim_fsw_run, dss, fsw, test_name, sequence_name, t_l=t_l, t_r=t_r, t_ig=t_ig

  fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  stx_plot, lightcurve, plot=plot
stop
  save, dss, fsw, filename=test_name + '_dss-fsw.sav'

  setenv, 'STX_CONF=' + original_conf
  cd, original_dir

  ; T2b - END ************************************************************************************************
  return
  ; T2a - BEGIN **********************************************************************************************

  copy_from = 'T2b'
  copy_to = 'T2'

  stx_sim_fsw_copy_test, copy_from, copy_to, concat_dir(test_root, version)

  ; T2a - END ************************************************************************************************  
  
  ; T3a - BEGIN **********************************************************************************************

  copy_from = 'T1a'
  copy_to = 'T3a'

  stx_sim_fsw_copy_test, copy_from, copy_to, concat_dir(test_root, version)

  ; T3a - END ************************************************************************************************
  
  ; T3b - BEGIN **********************************************************************************************

  copy_from = 'T1c'
  copy_to = 'T3b'

  stx_sim_fsw_copy_test, copy_from, copy_to, concat_dir(test_root, version)

  ; T3b - END ************************************************************************************************
  
  ; T3 - BEGIN **********************************************************************************************

  copy_from = 'T1c'
  copy_to = 'T3'

  stx_sim_fsw_copy_test, copy_from, copy_to, concat_dir(test_root, version)

  ; T3 - END ************************************************************************************************
  
  ; T4a - BEGIN **********************************************************************************************

  copy_from = 'T1a'
  copy_to = 'T4a'

  stx_sim_fsw_copy_test, copy_from, copy_to, concat_dir(test_root, version)

  ; T4a - END ************************************************************************************************
  
  ; T4b - BEGIN **********************************************************************************************

  copy_from = 'T1c'
  copy_to = 'T4b'

  stx_sim_fsw_copy_test, copy_from, copy_to, concat_dir(test_root, version)

  ; T4b - END ************************************************************************************************
  
  ; T4 - BEGIN **********************************************************************************************

  copy_from = 'T1c'
  copy_to = 'T4'

  stx_sim_fsw_copy_test, copy_from, copy_to, concat_dir(test_root, version)

  ; T4 - END ************************************************************************************************

  ; T5a - BEGIN **********************************************************************************************
  sequence_name = 'D3-2'
  test_name = 'T5a'
  configuration_file = 'default'
  
  setenv, 'WRITE_CALIBRATION_SPECTRUM=false'

  stx_sim_fsw_prep, test_name, sequence_name, configuration_file=configuration_file, seed=seed, test_root=test_root,$
    version=version, original_dir=original_dir, original_conf=original_conf, dss=dss, fsw=fsw

  stx_sim_fsw_run, dss, fsw, test_name, sequence_name, t_l=t_l, t_r=t_r, t_ig=t_ig

  fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  stx_plot, lightcurve, plot=plot

  save, dss, fsw, filename=sequence_name + '_dss-fsw.sav'

  ; restore original setting
  setenv, 'STX_CONF=' + original_conf
  cd, original_dir
  setenv, 'WRITE_CALIBRATION_SPECTRUM=false'

  ; T5a - END ************************************************************************************************

  ; T6a - BEGIN **********************************************************************************************

  copy_from = 'T1a'
  copy_to = 'T6a'

  stx_sim_fsw_copy_test, copy_from, copy_to, concat_dir(test_root, version)

  ; T6a - END ************************************************************************************************
  
  ; T6b - BEGIN **********************************************************************************************

  copy_from = 'T1b'
  copy_to = 'T6b'

  stx_sim_fsw_copy_test, copy_from, copy_to, concat_dir(test_root, version)

  ; T6b - END ************************************************************************************************

  ; T6c - BEGIN **********************************************************************************************

  copy_from = 'T1c'
  copy_to = 'T6c'

  stx_sim_fsw_copy_test, copy_from, copy_to, concat_dir(test_root, version)

  ; T6c - END ************************************************************************************************
;  resume_here:
  ; T9a - BEGIN **********************************************************************************************
  sequence_name = 'D5a-1'
  test_name = 'T9a'
  configuration_file = 'T9a_stx_flight_software_simulator_user.xml'

  setenv, 'WRITE_CALIBRATION_SPECTRUM=false'

  stx_sim_fsw_prep, test_name, sequence_name, configuration_file=configuration_file, seed=seed, test_root=test_root,$
    version=version, original_dir=original_dir, original_conf=original_conf, dss=dss, fsw=fsw

  stx_sim_fsw_run, dss, fsw, test_name, sequence_name, t_l=t_l, t_r=t_r, t_ig=t_ig

  fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  stx_plot, lightcurve, plot=plot

  save, dss, fsw, filename=sequence_name + '_dss-fsw.sav'

  ; restore original setting
  setenv, 'STX_CONF=' + original_conf
  cd, original_dir
  setenv, 'WRITE_CALIBRATION_SPECTRUM=false'
stop
  ; T9a - END ************************************************************************************************ 
;resume_here:
  ; T7a - BEGIN **********************************************************************************************
  sequence_name = 'D6-1'
  test_name = 'T7a'
  ;configuration_file = 'T9a_stx_flight_software_simulator_user.xml'

  setenv, 'WRITE_CALIBRATION_SPECTRUM=false'

  stx_sim_fsw_prep, test_name, sequence_name, configuration_file=configuration_file, seed=seed, test_root=test_root,$
    version=version, original_dir=original_dir, original_conf=original_conf, dss=dss, fsw=fsw

  stx_sim_fsw_run, dss, fsw, test_name, sequence_name, t_l=t_l, t_r=t_r, t_ig=t_ig

  fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  stx_plot, lightcurve, plot=plot

  save, dss, fsw, filename=sequence_name + '_dss-fsw.sav'

  ; restore original setting
  setenv, 'STX_CONF=' + original_conf
  cd, original_dir

  stop
  ; T7a - END ************************************************************************************************
end