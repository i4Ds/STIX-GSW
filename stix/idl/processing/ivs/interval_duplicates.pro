function interval_duplicates, list
 
 n_e = n_elements(list) - 1
 
 found = 0
 
 for i=0l, n_e-1 do begin
  j = i+1
  while j lt n_e do begin
    l = list[i]
    r = list[j]
    if  l.spectroscopy eq r.spectroscopy && $
        l.start_energy eq r.start_energy && $
        l.end_energy eq r.end_energy  && $
        l.start_time ge r.start_time && $
        l.end_time le r.end_time then begin
;          print, "duplicated found: ",i, j
;          print, l
;          print, r
          ;return, 1
          found++
        end
    j++
  endwhile
 endfor
 
 print, "total duplicates: ",trim(found)
 
 return, found
end