pro stx_sim_load_test, test_type=test_type, test_name=test_name, base_test_input_dir=base_test_input_dir, base_test_output_dir=base_test_output_dir
  default, base_test_input_dir, 'C:\Users\LaszloIstvan\Development\stix\stix\dbase\sim\tests'
  default, base_test_output_dir, 'C:\Users\LaszloIstvan\tests'
  default, test_type, 'basic'
  default, test_name, 'rcr'
  
  test_input_dir = concat_dir(concat_dir(base_test_input_dir, test_type), test_name)

  if(~file_exist(test_input_dir)) then message, "Test input directory '" + test_input_dir + "' does not exist"
  
  _setup_test, test_input_dir=test_input_dir, test_name=test_name, dss_out=dss, fsw_out=fsw, $
    scenario_file_out=scenario_file, output_dir_out=output_dir, dss_script_out=dss_script, $
    fsw_script_out=fsw_script, verification_script_out=verification_script
  
  _setup_test_environment, test_input_dir=test_input_dir, test_output_dir=output_dir
    
  _run_data_simulation, dss_obj=dss, scenario_file=scenario_file, dss_script=dss_script
  
  _run_flight_software_simulator, dss_obj=dss, fsw_obj=fsw, fsw_script=fsw_script
  
  _run_verification, dss_obj=dss, fsw_obj=fsw, verification_script=verification_script
  
end

pro _setup_test_environment, test_input_dir=test_input_dir, test_output_dir=test_output_dir
  ; clean old test data
  if(file_exist(test_output_dir)) then begin
    message, "Test output directory '" + test_output_dir + "' exists. Deleting old data", /informational
    file_delete, test_output_dir, /recursive
  endif
  
  ; creating test output directory
  mk_dir, test_output_dir
end

pro _setup_test, test_input_dir=test_input_dir, test_name=test_name, $
  dss_out=dss_out, fsw_out=fsw_out, scenario_file_out=scenario_file_out, output_dir_out=output_dir_out, $
  dss_script_out=dss_script_out, fsw_script_out=fsw_script_out, verification_script_out=verification_script_out
    
  ; find all user configurations
  user_configurations = find_file(concat_dir(test_input_dir, '*.xml'))

  ; find dss user configuration
  dss_user_config_idx = where(stregex(user_configurations, 'stx_data_simulation_user.xml') ge 0, dss_user_count)

  ; find fsw user configuration
  fsw_user_config_idx = where(stregex(user_configurations, 'stx_flight_software_simulator_user.xml') ge 0, fsw_user_config_count)

  ; create dss user configuration
  if(dss_user_count eq 1) then begin
    dss_user_config_file = user_configurations[dss_user_config_idx]
    dss_user_config = stx_configuration_manager(configfile=dss_user_config_file)
    dss_out = obj_new('stx_data_simulation', dss_user_config)
  endif else dss_out = obj_new('stx_data_simulation')

  ; create fsw user configuration
  if(fsw_user_config_count eq 1) then begin
    fsw_user_config_file = user_configurations[fsw_user_config_idx]
    fsw_user_config = stx_configuration_manager(configfile=fsw_user_config_file)
    fsw_out = obj_new('stx_flight_software_simulator', fsw_user_config, start_time=stx_time())
  endif else fsw_out = obj_new('stx_flight_software_simulator', start_time=stx_time())
  
  data_simulation_script = find_file(concat_dir(test_input_dir, 'stx_run_data_simulation_' + test_name + '_test.pro'), count=no_dss_script)
  if(no_dss_script eq 1) then dss_script_out = (file_basename(data_simulation_script, '.pro'))[0]
  if(no_dss_script gt 1) then message, 'Please provide only one data simulation script'
  
  flight_software_simulation_script = find_file(concat_dir(test_input_dir, 'stx_run_flight_software_simulation_' + test_name + '_test.pro'), count=no_fsw_script)
  if(no_fsw_script eq 1) then fsw_script_out = (file_basename(flight_software_simulation_script, '.pro'))[0]
  if(no_fsw_script gt 1) then message, 'Please provide only one flight software simulation script'
  
  verification_script = find_file(concat_dir(test_input_dir, 'stx_run_verification_' + test_name + '_test.pro'), count=no_verification_script)
  if(no_verification_script eq 1) then verification_script_out = (file_basename(verification_script, '.pro'))[0] $
  else message, 'Please provide one specification script.'

  ; set the scenario file
  scenario_file_out = find_file(concat_dir(test_input_dir, '*.csv'))

  if(n_elements(scenario_file_out) ne 1) then message, 'Please provide only one scenario file per test'
  
  output_dir_out = dss_out->getdata(scenario_file=scenario_file_out, output_target='scenario_output_path')
end

pro _run_data_simulation, dss_obj=dss_obj, scenario_file=scenario_file, dss_script=dss_script
  if(ppl_typeof(dss_script, compareto='string')) then result = call_function(dss_script, dss_obj) $
  else result = dss_obj->getdata(scenario_file=scenario_file)
  print, result
end

pro _run_flight_software_simulator, dss_obj=dss_obj, fsw_obj=fsw_obj, fsw_script=fsw_script
  if(ppl_typeof(fsw_script, compareto='string')) then result = call_function(fsw_script, dss_obj, fsw_obj) $
  else result = dss_obj->getdata(scenario_file=scenario_file)
  print, result
end

pro _run_verification, dss_obj=dss_obj, fsw_obj=fsw_obj, verification_script=verification_script
  if(ppl_typeof(verification_script, compareto='string')) then result = call_function(verification_script, dss_obj, fsw_obj) $
  else message, 'Please specify a verification script'
  print, result
end