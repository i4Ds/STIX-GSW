pro generate_stats, dir=dir
  t0s = 13L * 24 * 60 * 60 + 09L * 60 * 60 + 43L * 60 + 00L
  files = file_search(dir + '\*\*.dat')
  
  openw, lun, 'c:\temp\analysis.csv', /get_lun
  printf, lun, 'File_Name, Absolute_Time_Seconds, Day, Month, Year, Hour, Minute, Second, Relative_Time_Seconds, Number_Lines'
  free_lun, lun
  
  for index = 0L, n_elements(files)-1 do begin
    openr, lun, files[index], /get_lun
    
    t_year = fix(strmid(file_basename(files[index]),0, 2), type=3)
    t_month = fix(strmid(file_basename(files[index]),2, 2), type=3)
    t_day = fix(strmid(file_basename(files[index]),4, 2), type=3) 
    t_string = strmid(file_basename(files[index]), 7, 6)
    t_h = fix(strmid(t_string, 0, 2), type=3)
    t_m = fix(strmid(t_string, 2, 2), type=3)
    t_s = fix(strmid(t_string, 4, 2), type=3)
    t_absolute = t_day * 24 * 60 * 60 + t_h * 60 * 60L +  t_m * 60L + t_s
    
    lines = 0
    var = ''
    while(~eof(lun)) do begin
      lines++
      readf, lun, var
    endwhile
    
    free_lun, lun
    
    openw, lun, 'c:\temp\analysis.csv', /get_lun, /append
    printf, lun, file_basename(files[index]) + ', ' + trim(string(t_absolute)) + ', ' + trim(string(t_day)) + ', ' + trim(string(t_month)) + ', ' + trim(string(t_year)) + ', ' + trim(string(t_h)) + ', ' + trim(string(t_m)) + ', ' + trim(string(t_s)) + ', ' + trim(string(fix((t_absolute-t0s), type=3))) + ', ' + trim(string(lines))
    free_lun, lun
  endfor

end

; 170314-194821_3