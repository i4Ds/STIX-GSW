pro stx_sim_create_cfl_lut, cfl_lut_filename=cfl_lut_filename, directory = directory, cfl_lut_filenamepath=cfl_lut_filenamepath

  default, directory , getenv('STX_CFL')
  default, cfl_lut_filename, 'stx_fsw_cfl_skyvec_table.txt'
  default, cfl_lut_filenamepath, loc_file( cfl_lut_filename, path = directory )
  
  
  tab_data = stx_cfl_read_skyvec(cfl_lut_filenamepath, sky_x = sky_x, sky_y = sky_y)
  
  get_lun,lun
  openw, lun, "TC_237_7_16_SkyTab.tcl"
  printf,lun, ""
 
  
  sky_table_line = 0
  foreach y, sky_y, y_idx do begin
    
    foreach x, sky_x, x_idx do begin
 

      x = x - 64
      y = y - 64
      
      cmd = 'execTC "ZIX37716 {PIX00301 1} {PIX00302 '+trim(x_idx)+'} {PIX00303 '+trim(y_idx)+'} {PIX00304 0} {PIX00305 12}'
      
      foreach p, tab_data[sky_table_line,*], p_idx do begin
        cmd +=  ' {PIX00306 '+trim(p)+'}'
      endforeach
      
     
      ;the maximum of the quadrants as total flux estimate
      ;cmd += ' {PIX00306 '+trim(max(tab_data[sky_table_line,8:11]))+'} "'
      cmd += ' "'
      sky_table_line++
      printf,lun, cmd

  
    endforeach
  endforeach
  
  
  printf,lun, 'syslog "Applying SKY-LUT" '
  printf,lun, 'execTC "ZIX37008 {PIX00261 16} {PIX00262 0}" '
  
  free_lun, lun
  
end


pro stx_sim_create_cfl_lut_c, tab_data

  
  get_lun,lun
  openw, lun, "TC_237_7_16_SkyTab.c"
  printf,lun, ""


  sky_table_line = 0
  foreach y, sky_y, y_idx do begin

    foreach x, sky_x, x_idx do begin


      x = x - 64
      y = y - 64

      cmd = 'execTC "ZIX37716 {PIX00301 1} {PIX00302 '+trim(x_idx)+'} {PIX00303 '+trim(y_idx)+'} {PIX00304 0} {PIX00305 12}'

      foreach p, tab_data[sky_table_line,*], p_idx do begin
        cmd +=  ' {PIX00306 '+trim(p)+'}'
      endforeach


      ;the maximum of the quadrants as total flux estimate
      ;cmd += ' {PIX00306 '+trim(max(tab_data[sky_table_line,8:11]))+'} "'
      cmd += ' "'
      sky_table_line++
      printf,lun, cmd


    endforeach
  endforeach


  printf,lun, 'syslog "Applying SKY-LUT" '
  printf,lun, 'execTC "ZIX37008 {PIX00261 16} {PIX00262 0}" '

  free_lun, lun

end



;not working right now: to long commands?
pro stx_sim_create_cfl_lut_compact, cfl_lut_filename=cfl_lut_filename, directory = directory, cfl_lut_filenamepath=cfl_lut_filenamepath

  default, directory , getenv('STX_CFL')
  default, cfl_lut_filename, 'stx_fsw_cfl_skyvec_table.txt'
  default, cfl_lut_filenamepath, loc_file( cfl_lut_filename, path = directory )


  tab_data = stx_cfl_read_skyvec(cfl_lut_filenamepath, sky_x = sky_x, sky_y = sky_y)

  get_lun,lun
  openw, lun, "TC_237_7_16_SkyTab.tcl"
  printf,lun, ""

  for p=0, 11 do begin
    foreach x, sky_x, x_idx do begin
      cmd = 'execTC "ZIX37716 {PIX00301 ' + trim(N_ELEMENTS(sky_y)) + '} '
      foreach y, sky_y, y_idx do begin

        x = x - 64
        y = y - 64
        cmd +=  '{PIX00302 '+trim(x_idx)+'} {PIX00303 '+trim(y_idx)+'} {PIX00304 '+trim(p)+'} {PIX00305 1} {PIX00306 '+trim(tab_data[x_idx*y_idx,p])+'}'


      endforeach ;y
      cmd += '"'

      printf,lun, cmd
    endforeach ; x

  endfor ;pixel

  free_lun, lun
end