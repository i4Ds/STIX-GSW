function stx_configuration_manager, initialize=initialize, configfile=configfile, application_name=application_name
  default, initialize, 1
  confm = obj_new('ppl_configuration_manager', configfile, application_name, initialize)
  if(initialize) then confm->load_configuration
  return, confm
end