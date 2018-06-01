pro stx_sim_create_cfl_lut, cfl_lut_filename=cfl_lut_filename, directory = directory, cfl_lut_filenamepath=cfl_lut_filenamepath

  default, directory , getenv('STX_CFL')
  default, cfl_lut_filename, 'stx_fsw_cfl_skyvec_table.txt'
  default, cfl_lut_filenamepath, loc_file( cfl_lut_filename, path = directory )
  
  
  tab_data = stx_cfl_read_skyvec(cfl_lut_filenamepath, sky_x = sky_x, sky_y = sky_y)
  
  get_lun,lun
  openw, lun, "TC_237_7_16.tc"



  foreach x, sky_x, x_idx do begin
    foreach y, sky_x, y_idx do begin

      x = x - 64
      y = y - 64
      
      cmd = 'execTC "ZIX37703 {PIX00301 1} {PIX00302 '+trim(x_idx)+'} {PIX00303 '+trim(y_idx)+'} {PIX00304 0} {PIX00305 11}'
      
      foreach p, tab_data[x_idx*y_idx,*], p_idx do begin
        cmd +=  ' {PIX00306 '+trim(p)+'}'
      endforeach
      
      
      cmd += '"'

      printf,lun, cmd

  
    endforeach
  endforeach

  free_lun, lun
end