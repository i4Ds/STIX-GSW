pro stx_sim_create_tlut, tmin, tmax

  get_lun,lun
  openw, lun, "TC_237_7_TLUT.tcl"
  
  printf,lun, 'source D:\\Tools\\scripts\\procedures.tcl'
  printf,lun, ''
  
  default, tmin, 100
  default, tmax, 1000
  
  temp = [tmin, tmax]
  temp_label = ["low", "high"]
  
  n_p = 12L
  n_d = 32L
  
  foreach t, temp, t_idx do begin
 

    for d=0, n_d-1 do begin
  
      printf,lun, 'syslog "Setting TLUT-'+ temp_label[t_idx] +' Detector: '+trim(d)+'"' 
           
        cmd = 'execTC "ZIX3770'+trim(t_idx+1)+' {PIX00154 '+trim(t)+'} {PIX00155 12}'
        
         for p=0, n_p-1 do begin
           cmd += ' {PIX00480 '+trim(d+1)+'} {PIX00481  '+trim(p)+'} {PIX00156 '+trim((d + 1 + p ) * (t_idx ? 1 : -1 ))+'} '
         endfor
  
        cmd += '"'
  
        printf,lun, cmd
 
    endfor
  
  endforeach


  printf,lun, 'syslog "Applying Low-TLUT"'
  printf,lun, 'execTC "ZIX37008 {PIX00261 1} {PIX00262 0}"
  
  printf,lun, 'syslog "Applying High-TLUT"'
  printf,lun, 'execTC "ZIX37008 {PIX00261 2} {PIX00262 0}"


  free_lun, lun



  ;og = stx_offset_gain_reader(/reset)
  ;eb = stx_science_energy_channels(/reset)





end