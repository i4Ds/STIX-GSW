pro stx_sim_fsw_prep, test_name, sequence_name, configuration_file=configuration_file, seed=seed, test_root=test_root, version=version, original_dir=original_dir, original_conf=original_conf, dss=dss, fsw=fsw, offset_gain_table=offset_gain_table
  default, offset_gain_table, "offset_gain_table.csv"
  
  ; create test root
  mk_dir, test_root

  ; save current dir
  original_dir = curdir()

  ; go into test root
  cd, test_root
  
  ; make specific time-stamped test director and enter it
  mk_dir, version
  cd, version

  ; save old STX_CONF
  original_conf = getenv('STX_CONF')
  
  ; make sure we use the correct offset-gain table
  if offset_gain_table ne "" then offset_table = stx_offset_gain_reader(offset_gain_table, directory=concat_dir(getenv('STX_FSW'), concat_dir('rnd_seq_testing', 'stix_conf')), /RESET)

  ; change default STIX configuration folder
  setenv, 'STX_CONF=' + concat_dir(getenv('STX_FSW'), concat_dir('rnd_seq_testing', 'stix_conf'))
  setenv, 'stx_conf=' + getenv('STX_CONF')

  ; create test directory and enter it
  mk_dir, test_name
  cd, test_name
  
  ; Make sure to copy all configuration
  file_copy, getenv('STX_CONF'), '.', /recursive, /overwrite

  dss = obj_new('stx_data_simulation')
  dss->set, /stop_on_error
  dss->set, math_error_level=0
  dss->set, ds_seed=seed
  result = dss->getdata(scenario_file=concat_dir(getenv('STX_FSW'), concat_dir('rnd_seq_testing', sequence_name + '.csv')), seed=seed)

  ; copy sequence definition over
  file_copy, concat_dir(getenv('STX_FSW'), concat_dir('rnd_seq_testing', sequence_name + '.csv')), sequence_name, /overwrite

  ; copy sequence to stix config
  file_copy, concat_dir(getenv('STX_FSW'), concat_dir('rnd_seq_testing', sequence_name + '.csv')), concat_dir(test_root, concat_dir(version, concat_dir(test_name, concat_dir('stix_conf', sequence_name + '.csv')))), /overwrite

  ; select configuration, only if not default
  if(configuration_file ne 'default') then begin
    config_manager = stx_configuration_manager(configfile=concat_dir(getenv('STX_CONF'), configuration_file))
  endif

  fsw = obj_new('stx_flight_software_simulator', config_manager, start_time=stx_construct_time())
  fsw->set, /stop_on_error
  fsw->set, math_error_level=0
end