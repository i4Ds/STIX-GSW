pro stx_sim_create_fpp_tc, conf  
  
  
  get_lun,lun
  openw, lun, "TC_237_13_FPP.tcl"

  global  = conf->get()
  eab    = conf->get(module="stx_fsw_module_eventlist_to_archive_buffer")

  printf, lun, 'syslog "set flare processing params: tc(237,13)"'

  cmd = 'execTC "ZIX37013 '
  
;Minimal duration of EACC & TRIG accumulation
cmd += ' {PIX00447 ' + trim(eab.T_MIN * 10)+ '}' 

;Maximal duration of EACC & TRIG accumulation
cmd += ' {PIX00448 ' + trim(eab.T_MAX)+ '}'

;Maximal counts in EACC & TRIG accumulation
cmd += ' {PIX00449 ' + trim(eab.N_MIN)+ '}'

;SumEmask
cmd += ' {PIX00450 ' + trim(2UL^32 - 1)+ '}'

;SumDmask
cmd += ' {PIX00451 ' + trim(2UL^32 - 1)+ '}'

;Flare selector period (units of 10 min)
cmd += ' {PIX00452 1}'

;Flare selector latency (units of 10 min)
cmd += ' {PIX00453 2}'

;Flare selector enabled flag
cmd += ' {PIX00454 0}'

;Flare selector start time (in SCET seconds)
cmd += ' {PIX00455 0}'

;Flare selector end time (in SCET seconds)
cmd += ' {PIX00456 1}'

;Image interval - detector mask
cmd += ' {PIX00457 ' + trim(2UL^32 - 1)+ '}'

;Imaging interval – trim N-parameter
cmd += ' {PIX00458 1}'

;Imaging interval – Ftrim fraction
cmd += ' {PIX00459 10}'

;Imaging interval – enable BCKG subtraction
cmd += ' {PIX00460 False }'

;Spectrogram – enable BCKG subtraction
cmd += ' {PIX00461 False }'

;Spectrogram – pixel mask
cmd += ' {PIX00462 ' + trim(2UL^12 - 1)+ '}'

;Spectrogram – detector mask
cmd += ' {PIX00463 ' + trim(2UL^32 - 1)+ '}'


  cmd += '" '

  printf,lun, cmd


  free_lun, lun
  
  
   

  
end