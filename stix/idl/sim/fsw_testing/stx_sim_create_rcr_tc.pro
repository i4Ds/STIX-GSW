pro stx_sim_create_rcr_tc, conf, enabled=enabled
   
  default, enabled, "Enabled"
  
  get_lun,lun
  openw, lun, "TC_237_10_RCR.tcl"

  
  rcr_conf = conf->get(module="stx_fsw_module_rate_control_regime")
 

  rcr_struct = stx_fsw_rcr_table2struct(rcr_conf.RCR_TBL_FILENAME, rcr_max = rcr_max_tbl, min_attenuator_level = min_attenuator_level_tbl )

  printf, lun, 'syslog "set rcr params: tc(237,10)"'
  
  bit13 = rcr_struct.attenuator * 2L^12

  cmd = 'execTC "ZIX37010 '
  
  ;RCR enabled
  cmd += " {PIX00401 "+ enabled +"} "
  
  ;Pixel mask RCR state = 0
  cmd += ' {PIX00402 ' + trim(bit13[0] + stx_mask2bits(reverse((*(rcr_struct[0].north))))) + '}'
  
  ;Pixel mask RCR state = 1
  cmd += ' {PIX00403 ' + trim(bit13[1] + stx_mask2bits(reverse((*(rcr_struct[1].north))))) + '}'
  
  ;Pixel mask RCR state = 2, North flare
  cmd += ' {PIX00404 ' + trim(bit13[2] + stx_mask2bits(reverse((*(rcr_struct[2].north))))) + '}'
  
  ;Pixel mask RCR state = 2, South flare
  cmd += ' {PIX00405 ' + trim(bit13[2] + stx_mask2bits(reverse((*(rcr_struct[2].south))))) + '}'
  
  ;Pixel mask RCR state = 3, North flare, variation 1
  cmd += ' {PIX00406 ' + trim(bit13[3] + stx_mask2bits(reverse((*(rcr_struct[3].north))[*,0]))) + '}'
    
  ;Pixel mask RCR state = 3, North flare, variation 2
  cmd += ' {PIX00407 ' + trim(bit13[3] + stx_mask2bits(reverse((*(rcr_struct[3].north))[*,1]))) + '}'
  
  ;Pixel mask RCR state = 3, South flare, variation 1
  cmd += ' {PIX00408 ' + trim(bit13[3] + stx_mask2bits(reverse((*(rcr_struct[3].south))[*,0]))) + '}'
  
  ;Pixel mask RCR state = 3, South flare, variation 2
  cmd += ' {PIX00409 ' + trim(bit13[3] + stx_mask2bits(reverse((*(rcr_struct[3].south))[*,1]))) + '}'
  
  ;Pixel mask RCR state = 4, North flare, variation 1
  cmd += ' {PIX00410 ' + trim(bit13[4] + stx_mask2bits(reverse((*(rcr_struct[4].north))[*,0]))) + '}'
  
  ;Pixel mask RCR state = 4, North flare, variation 2
  cmd += ' {PIX00411 ' + trim(bit13[4] + stx_mask2bits(reverse((*(rcr_struct[4].north))[*,1]))) + '}'
  
  ;Pixel mask RCR state = 4, North flare, variation 3
  cmd += ' {PIX00412 ' + trim(bit13[4] + stx_mask2bits(reverse((*(rcr_struct[4].north))[*,2]))) + '}'
  
  ;Pixel mask RCR state = 4, North flare, variation 4
  cmd += ' {PIX00413 ' + trim(bit13[4] + stx_mask2bits(reverse((*(rcr_struct[4].north))[*,3]))) + '}'
  
  ;Pixel mask RCR state = 4, South flare, variation 1
  cmd += ' {PIX00414 ' + trim(bit13[4] + stx_mask2bits(reverse((*(rcr_struct[4].south))[*,0]))) + '}'
  
  ;Pixel mask RCR state = 4, South flare, variation 2
  cmd += ' {PIX00415 ' + trim(bit13[4] + stx_mask2bits(reverse((*(rcr_struct[4].south))[*,1]))) + '}'
  
  ;Pixel mask RCR state = 4, South flare, variation 3
  cmd += ' {PIX00416 ' + trim(bit13[4] + stx_mask2bits(reverse((*(rcr_struct[4].south))[*,2]))) + '}'
  
  ;Pixel mask RCR state = 4, South flare, variation 4
  cmd += ' {PIX00417 ' + trim(bit13[4] + stx_mask2bits(reverse((*(rcr_struct[4].south))[*,3]))) + '}'
  
  ;Pixel mask RCR state = 5
  cmd += ' {PIX00418 ' + trim(bit13[5] + stx_mask2bits(reverse((*(rcr_struct[5].north))))) + '}'
  
  ;Pixel Mask RCR state = 6, variation 1
  cmd += ' {PIX00419 ' + trim(bit13[6] + stx_mask2bits(reverse((*(rcr_struct[6].north))[*,0]))) + '}'
  
  ;Pixel Mask RCR state = 6, variation 2
  cmd += ' {PIX00420 ' + trim(bit13[6] + stx_mask2bits(reverse((*(rcr_struct[6].north))[*,1]))) + '}'
  
  ;Pixel Mask RCR state = 7, variation 1
  cmd += ' {PIX00421 ' + trim(bit13[7] + stx_mask2bits(reverse((*(rcr_struct[7].north))[*,0]))) + '}'
  
  ;Pixel Mask RCR state = 7, variation 2
  cmd += ' {PIX00422 ' + trim(bit13[7] + stx_mask2bits(reverse((*(rcr_struct[7].north))[*,1]))) + '}'
  
  ;Pixel Mask RCR state = 7, variation 3
  cmd += ' {PIX00423 ' + trim(bit13[7] + stx_mask2bits(reverse((*(rcr_struct[7].north))[*,2]))) + '}'
  
  ;Pixel Mask RCR state = 7, variation 4
  cmd += ' {PIX00424 ' + trim(bit13[7] + stx_mask2bits(reverse((*(rcr_struct[7].north))[*,3]))) + '}'
  
  ;Pixel Mask RCR state = 0, background detector
  cmd += ' {PIX00425 ' + trim(bit13[7] + stx_mask2bits(reverse(*rcr_struct[0].background))) + '}'
  
  ;Pixel Mask RCR state = 1, background detector
  cmd += ' {PIX00426 ' + trim(stx_mask2bits(reverse(*rcr_struct[1].background))) + '}'
  
  ;Pixel Mask RCR state = 2, background detector
  cmd += ' {PIX00427 ' + trim(stx_mask2bits(reverse(*rcr_struct[2].background))) + '}'
  
  ;Pixel Mask RCR state = 3, background detector
  cmd += ' {PIX00428 ' + trim(stx_mask2bits(reverse(*rcr_struct[3].background))) + '}'
  
  ;Pixel Mask RCR state = 4, background detector
  cmd += ' {PIX00429 ' + trim(stx_mask2bits(reverse(*rcr_struct[4].background))) + '}'
  
  ;Pixel Mask RCR state = 5, background detector
  cmd += ' {PIX00430 ' + trim(stx_mask2bits(reverse(*rcr_struct[5].background))) + '}'
  
  ;Pixel Mask RCR state = 6, background detector
  cmd += ' {PIX00431 ' + trim(stx_mask2bits(reverse(*rcr_struct[6].background))) + '}'
  
  ;Pixel Mask RCR state = 7, background detector
  cmd += ' {PIX00432 ' + trim(stx_mask2bits(reverse(*rcr_struct[7].background))) + '}'
  
  ;RCR – group mask
  ;todo: n.h. hard coded all 16 triggers could be read from the qlook_accumulator definition file
  cmd += ' {PIX00433 ' + trim(2L^16L-1) + '}'

  ;RCR – L0
  cmd += ' {PIX00434 ' + trim(rcr_conf.L0) + '}'
  
  ;RCR – L1
  cmd += ' {PIX00435 ' + trim(rcr_conf.L1) + '}'

  ;RCR – L2
  cmd += ' {PIX00436 ' + trim(rcr_conf.L2) + '}'
  
  ;RCR – L3
  cmd += ' {PIX00437 ' + trim(rcr_conf.L3) + '}'
  
  ;RCR – B0
  cmd += ' {PIX00438 ' + trim(rcr_conf.B0) + '}'
  

  cmd += ' {PIX00439 ' + trim(0) + '}'
  cmd += ' {PIX00440 ' + trim(1) + '}'
  cmd += ' {PIX00441 ' + trim(2) + '}'
  cmd += ' {PIX00442 ' + trim(3) + '}'
  cmd += ' {PIX00443 ' + trim(4) + '}'
  cmd += ' {PIX00444 ' + trim(5) + '}'
  cmd += ' {PIX00445 ' + trim(6) + '}'
  cmd += ' {PIX00446 ' + trim(7) + '}'
      
      
  cmd += '" '

  printf,lun, cmd


  free_lun, lun
end