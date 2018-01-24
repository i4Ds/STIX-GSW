pro calibration_spectrum_inspect
  restore, 'c:\temp\raw.sav'
  acc = raw_calib_spectrum.accumulated_counts

  for d=0, 31 do begin
    for p=0, 11 do begin
      for e=0, 1023 do begin
        if(acc[e, p, d] eq 0) then continue
        print, e
        print, acc[e, p, d]
        print, stx_km_compress(acc[e, p, d], 4, 4)
        print, stx_km_decompress(stx_km_compress(acc[e, p, d], 4, 4), 4, 4)
      endfor
    endfor
  endfor
end