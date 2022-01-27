pro stx_start_software_manager
  ssm_name = 'stix_software_manager.jar'
  ssm = ppl_search_file(ssm_name)
  
  if(ssm eq '') then begin
    ssm_loc = ppl_search_file('..')
    
    oUrl = obj_new('IDLnetUrl')
    oUrl->setproperty, ssl_verify_host=0
    oUrl->setproperty, ssl_verify_peer=0
    ssm = oUrl->get(url='http://stix.cs.technik.fhnw.ch/' + ssm_name, filename=ssm_loc[0] + get_delim() + ssm_name)
  endif
  spawn, 'java -jar ' + ssm, result, err
  
  if(err[0] ne '') then print, arr2str(err, delimiter=string(10b))
end