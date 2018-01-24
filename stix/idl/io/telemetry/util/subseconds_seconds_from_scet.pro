pro subseconds_seconds_from_scet, timestamp, seconds, subseconds
  seconds_bits = 32
  subseconds_bits = 16

  ; extract seconds first
  t_seconds = ulong64(timestamp)
  seconds = t_seconds and 2L^(seconds_bits)-1

  ; extract subseconds
  t_subseconds = timestamp - ulong64(timestamp)
  subseconds = 0UL

  ; loop over all the fraction bits
  ; and add them up
  for i = 1L, subseconds_bits do begin
    binary_val = 2d^(-i)

    div = t_subseconds / binary_val

    if(div ge 1.0) then begin
      subseconds += 2UL^(subseconds_bits - i)
      t_subseconds -= binary_val
    endif
  endfor
end