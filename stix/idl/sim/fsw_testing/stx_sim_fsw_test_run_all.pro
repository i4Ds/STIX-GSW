pro stx_sim_fsw_test_run_all
  version = 'v20170328' ;time2file(trim(ut_time(/to_local)), /seconds)
  seed = 1337
  test_root = 'C:\Temp'
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
;stop
;return
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
  ; T1b - END ************************************************************************************************

  ; T1c - BEGIN **********************************************************************************************
  sequence_name = 'D1-2'
  test_name = 'T1c'
  configuration_file = 'default'

  stx_sim_fsw_prep, test_name, sequence_name, configuration_file=configuration_file, seed=seed, test_root=test_root, $
    version=version, original_dir=original_dir, original_conf=original_conf, dss=dss, fsw=fsw

  stx_sim_fsw_run, dss, fsw, test_name, sequence_name, t_l=t_l, t_r=t_r, t_ig=t_ig

  fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  stx_plot, lightcurve, plot=plot

  save, dss, fsw, filename=test_name + '_dss-fsw.sav'

  setenv, 'STX_CONF=' + original_conf
  cd, original_dir

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
  ;resume_here:
  ; T5a - BEGIN **********************************************************************************************
  sequence_name = 'D3-2'
  test_name = 'T5a'
  configuration_file = 'default'
  
  setenv, 'WRITE_CALIBRATION_SPECTRUM=true'

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
return

  ; T5a - END ************************************************************************************************
  ;resume_here:
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
  return
  ; T6c - BEGIN **********************************************************************************************

  copy_from = 'T1c'
  copy_to = 'T6c'

  stx_sim_fsw_copy_test, copy_from, copy_to, concat_dir(test_root, version)

  ; T6c - END ************************************************************************************************
 resume_here:
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