pro read_calib_spec_esc_ascii, file_name=file_name
  restore, 'C:\Users\LaszloIstvan\Dropbox (STIX)\FSW_Test_Data\Data\Raw\v20170308\T5a\T5a_00404_calibration_spectrum.sav'
  
  openr, lun, file_name, /get_lun
  line = ''
  
  curr_s = -1
  curr_p = -1
  curr_d = -1
  curr_e = -1
  calib_specs = hash()
  calib_spec_defs = hash()
  calib_spec = -1
  
  total_uc = 0L
  total_c = 0L
  total_dc = 0L
  
  while(~eof(lun)) do begin
    readf, lun, line
    
    if(stregex(line, '.*(BGReport).*(id).*',/boolean)) then begin
      ; beginning of new S, P, or D
      curr_s = uint(strmid(line, 49, 2))
      curr_p = uint(strmid(line, 45, 2))
      curr_d = uint(strmid(line, 41, 2))
      curr_e_s = strmid(line, 63, 4)
      if(strmid(curr_e_s, 0, 1) eq 'n') then curr_e = uint(strmid(line, 64, 4)) $
      else curr_e = uint(curr_e_s)
      
      if(~calib_specs->haskey(curr_s)) then calib_specs[curr_s] = ptr_new(ulonarr(curr_e, 12, 32))
      if(~calib_spec_defs->haskey(curr_s)) then calib_spec_defs[curr_s] = line
      
      ;print, 'Starting [s, p, d]: ' + trim(string(curr_s)) + ', ' + trim(string(curr_p)) + ', ' + trim(string(curr_d))
      
    endif else if(stregex(line, 's[0-9] p[0-9]?[0-9]?[0-9]?[0-9]? ', /boolean)) then begin
      ; continue current accumulation
      s = strmid(line, 1, 1)
      pt = uint(strmid(line, 4, 3))
      acc_u = ulong(strmid(line, 10, 5))
      acc_c = ulong(strmid(line, 16, 3))
      (*calib_specs[curr_s])[pt, curr_p, curr_d] = acc_u; stx_km_decompress(acc_c, 5, 3, 0)
      
      if(curr_s eq 0) then begin

        diff = long64(acc_u) - long64(calib_spectrum.accumulated_counts[pt, curr_p, curr_d])
        if(diff ne 0) then begin
          print, 'UCC [s, p, d, pt] diff: ' + trim(string(curr_s)) + ', ' + trim(string(curr_p)) + ', ' + trim(string(curr_d)) + ', ' + trim(string(pt)) + ', ' + trim(string(diff))
          stop
        endif
        
        diff = stx_km_decompress(acc_c, 5, 3, 0) - stx_km_decompress(stx_km_compress(calib_spectrum.accumulated_counts[pt, curr_p, curr_d], 5, 3, 0), 5, 3, 0)
        if(diff ne 0) then begin
          print, 'CC [s, p, d, pt] diff: ' + trim(string(curr_s)) + ', ' + trim(string(curr_p)) + ', ' + trim(string(curr_d)) + ', ' + trim(string(pt)) + ', ' + trim(string(diff))
          stop
        endif       
      endif else if(curr_s eq 1) then begin
        total_uc += acc_u
        total_c += acc_c
        total_dc += stx_km_decompress(acc_c, 5, 3, 0)
        diff = long64(acc_u) - total(calib_spectrum.accumulated_counts[pt * 8:(pt+1)*8-1, curr_p, curr_d])
        if(diff ne 0) then begin
          print, 'UCC [s, p, d, pt] diff: ' + trim(string(curr_s)) + ', ' + trim(string(curr_p)) + ', ' + trim(string(curr_d)) + ', ' + trim(string(pt)) + ', ' + trim(string(diff))
          stop
        endif
        
        diff = stx_km_decompress(acc_c, 5, 3, 0) - stx_km_decompress(stx_km_compress(ulong(total(calib_spectrum.accumulated_counts[pt * 8:(pt+1)*8-1, curr_p, curr_d])), 5, 3, 0), 5, 3, 0)
        if(diff ne 0) then begin
          print, 'CC [s, p, d, pt] diff: ' + trim(string(curr_s)) + ', ' + trim(string(curr_p)) + ', ' + trim(string(curr_d)) + ', ' + trim(string(pt)) + ', ' + trim(string(diff))
          stop
        endif
      endif else if(curr_s eq 2) then begin
        stop
      
      endif
    endif
     
  endwhile
  
  free_lun, lun
  
  print, 'Total s0: ' + trim(string(ulong(total((*calib_specs[0]))))) + ' (FSW), ' + trim(string(total(calib_spectrum.accumulated_counts))) + ' (FSW SIM)'
  print, 'Total s1: ' + trim(string(ulong(total((*calib_specs[1]))))) + ' (FSW), ' + trim(string(total(calib_spectrum.accumulated_counts))) + ' (FSW SIM)'
  ;print, 'Total s2: ' + total((*calib_specs[2])) + ' (FSW), ' + total(calib_spectrum.accumulated_counts) + ' (FSW SIM)'
  stop
end