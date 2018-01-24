pro stx_lldp_test_pipeline

  ; Linux Paths
  env_in = 'instr_input_requests='
  env_out= 'instr_output='
  env_in += FILE_DIRNAME(ROUTINE_FILEPATH())
  env_out += FILE_DIRNAME(ROUTINE_FILEPATH())
  env_in += '/TEST_INPUT'
  env_out += '/TEST_OUTPUT'
  
  setenv, env_in
  setenv, env_out  
  setenv, 'INST=STIX'
  
  pipeline
end