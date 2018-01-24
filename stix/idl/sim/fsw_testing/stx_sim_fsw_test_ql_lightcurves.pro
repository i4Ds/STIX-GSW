pro stx_sim_fsw_test_ql_lightcurves
  ; T1a - BEGIN **********************************************************************************************
  sequence_name = 'D1a-1'
  test_name = 'T1a'
  configuration_file = 'default'
  seed = 1337
  test_root = 'C:\Temp'
  timestamp = trim(ut_time(/to_local))
  
  stx_sim_fsw_prep, test_name, sequence_name, configuration_file=configuration_file, seed=seed, test_root=test_root,$
    timestamp=timestamp, original_dir=original_dir, dss=dss, fsw=fsw

  stx_sim_fsw_run, dss, fsw, test_name, sequence_name, t_l=t_l, t_r=t_r, t_b=t_b
    
  cd, original_dir
  
  ; T1a - END ************************************************************************************************
  
  ; T1b - BEGIN **********************************************************************************************
  sequence_name = 'D1b-1'
  test_name = 'T1b'
  configuration_file = 'default'
  seed = 1337
  test_root = 'C:\Temp'
  timestamp = trim(ut_time(/to_local))

  stx_sim_fsw_prep, test_name, sequence_name, configuration_file=configuration_file, seed=seed, test_root=test_root,$
    timestamp=timestamp, original_dir=original_dir, dss=dss, fsw=fsw

  stx_sim_fsw_run, dss, fsw, test_name, sequence_name, t_l=t_l, t_r=t_r, t_b=t_b

  cd, original_dir

  ; T1b - END ************************************************************************************************
stop
end