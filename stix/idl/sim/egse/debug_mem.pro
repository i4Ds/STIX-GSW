pro debug_mem, rb_cbk, rb_fhnw

  for di = 0L, 32-1 do begin
    for pi = 0L, 12-1 do begin
      counts_cbk = rb_cbk.counts[*,pi,di]
      counts_fhnw = rb_fhnw.counts[*,pi,di]
      
      cdiff = counts_cbk - counts_fhnw
      match = array_equal(counts_cbk, counts_fhnw)
      
      print, (match ? 'E' : 'D') + ', ' + trim(string(di)) + ', ' + trim(string(pi)) + ', ' + arr2str(trim(string(long(cdiff))), dim=',')
      ;if(pi eq 11) then print, arr2str(trim(string(long(counts_fhnw))), dim=',')
    endfor

  endfor


end