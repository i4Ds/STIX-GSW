pro gen_script
  openw, lun, "d:\script.txt", /get_lun
  for pi = 0L, 1-1 do begin
    print, "pi" + trim(string(pi))
    for di = 1L, 2-1 do begin
      print, "di" + trim(string(di))
      for ei = 0L, 4096-1 do begin
        printf, lun, "det(" + trim(string(di)) + ", " + trim(string(pi)) + ", " + trim(string(ei)) + ");"
        
        
        if(ei mod 30 eq 0) then begin
          printf, lun, "wait 1000000 us;"
        endif else begin
          printf, lun, "wait 23 us;"
        endelse
      endfor

    endfor

  endfor
  free_lun, lun

end