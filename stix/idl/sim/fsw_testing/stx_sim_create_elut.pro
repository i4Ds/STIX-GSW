pro stx_sim_create_elut, og_filename=og_filename, eb_filename=eb_filename, directory = directory

  ;default, directory , getenv('STX_DET')
  ;default, og_filename, 'offset_gain_table.csv'
  ;default, eb_filename, 'EnergyBinning20150615.csv'
  ;og = stx_offset_gain_reader(og_filename, directory=directory, /reset)
  ;eb = stx_science_energy_channels(basefile=eb_filename,/reset)
  
  get_lun,lun
  openw, lun, "TC_237_7.tc"
  energy_axis = stx_construct_energy_axis();
    
  n_p = 12L
  n_d = 32L
  n_e = 32L
  
  
  elut_entry = { $
    detector          : 0b, $
    pixel             : 0b, $
    ad_edges          : intarr(n_e+1) $
  }
  
  E_lut = replicate(elut_entry, n_p * n_d)
    
  e_lut_idx = 0L
  
  
  
  for d=0, n_d-1 do begin
    
    printf,lun, 'syslog "Setting ELUT Detector: '+trim(d)+'"'
    
    for p=0, n_p-1 do begin
      E_lut[e_lut_idx].detector = d + 1
      E_lut[e_lut_idx].pixel = p
      E_lut[e_lut_idx].ad_edges = stx_sim_energy_2_pixel_ad(energy_axis.edges_1, d+1, p)        
      
      
      
      cmd = 'execTC "ZIX37703 {PIX00479 1} {PIX00480 '+trim(d+1)+'} {PIX00481 '+trim(p)+'}';
      
      for e=0, n_e do begin
        cmd += ' {PIX00'+trim(482+e)+' '+trim(E_lut[e_lut_idx].ad_edges[e])+'}'
      endfor
      
      cmd += '"'
      
      printf,lun, cmd
      
      e_lut_idx++
      
    endfor
  endfor
  
  
  write_csv, "elut.csv", [ transpose([E_lut.detector]), transpose([e_lut.pixel]), [[e_lut.ad_edges]]]
  

  free_lun, lun
 
  
  
  ;og = stx_offset_gain_reader(/reset)
  ;eb = stx_science_energy_channels(/reset)



 

end