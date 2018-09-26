pro read_calib_spec_esc_ascii, file_name=file_name
  restore, 'D:\Dropbox (STIX)\FSW_Test_Data\Data\Raw\v20170308\T5a\T5a_00404_calibration_spectrum.sav', /ver
  
  
  tmtc_writer = stx_telemetry_writer(filename='d:\temp\tm_cs.bin', size=2L^24)
  tmtc_writer->setdata,ql_calibration_spectrum = CALIB_SPECTRUM, subspectra_definition = [[0, 1, 1024],[0, 8, 128],[13, 23, 5]]
  tmtc_writer->flushtofile
  destroy, tmtc_writer
  
  r = stx_telemetry_reader(filename='d:\temp\tm_cs.bin', /scan_mode)
  r->getdata, asw_ql_calibration_spectrum=readtm_calib_spectrum, solo_packets=sp
  destroy, r
  
 default, file_name, 'D:\Dropbox (STIX)\FSW_Test_Data\Data\Published\20170308_234711\ESC\T5a-20170324\T5a_data_ver4.txt' 
  
  bin_data = list()
  
  openw, alllun, "D:\temp\cs_all.bin", /get_lun
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
  lineNb=0L
  
  while(~eof(lun)) do begin
    readf, lun, line
    lineNb++
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
      
      print, 'Starting [s, p, d]: ' + trim(string(curr_s)) + ', ' + trim(string(curr_p)) + ', ' + trim(string(curr_d))
      
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
    endif else if strmid(line,0,2) eq '0x' then begin
      
      all_hex = STRSPLIT(STRMID(line, 2), "-", /EXTRACT)
      all_bytes = bytarr(n_elements(all_hex))
      foreach hex, all_hex, idx do begin
        hex2dec, hex, bv, /quiet
        all_bytes[idx] = byte(bv)
      endforeach
      
      openw, hlun, "D:\temp\cs_"+trim(lineNb)+".bin", /get_lun
      writeu, hlun, all_bytes
      writeu, alllun, all_bytes
      close, hlun
      free_lun, hlun
      
    endif
    
     
  endwhile
  
  free_lun, lun
  close, alllun
  free_lun, alllun
  
  
  print, 'Total s0: ' + trim(string(ulong(total((*calib_specs[0]))))) + ' (FSW), ' + trim(string(total(calib_spectrum.accumulated_counts))) + ' (FSW SIM)'
  print, 'Total s1: ' + trim(string(ulong(total((*calib_specs[1]))))) + ' (FSW), ' + trim(string(total(calib_spectrum.accumulated_counts))) + ' (FSW SIM)'
  ;print, 'Total s2: ' + total((*calib_specs[2])) + ' (FSW), ' + total(calib_spectrum.accumulated_counts) + ' (FSW SIM)'
  
  assert_equals, total(*calib_specs[0], /preserve_type), total(calib_spectrum.accumulated_counts, /preserve_type)
  assert_equals, total(*calib_specs[1], /preserve_type), total(calib_spectrum.accumulated_counts, /preserve_type)


  ra = stx_telemetry_reader(filename='d:\temp\cs_all.bin', /scan_mode)
  ra->getdata, asw_ql_calibration_spectrum=esc_calib_spectrum, solo_packets=sp
  destroy, ra
  
   print, total(esc_calib_spectrum[0].subspectra[0].spectrum, /pre), total(esc_calib_spectrum[0].subspectra[1].spectrum, /pre)
   print, total(readtm_calib_spectrum[0].subspectra[0].spectrum, /pre), total(readtm_calib_spectrum[0].subspectra[1].spectrum, /pre)

  ecs_plot = stx_energy_calibration_spectrum_plot()
  ecs_plot->plot, esc_calib_spectrum[0], /add_legend
  
  sim_plot = stx_energy_calibration_spectrum_plot()
  sim_plot->plot, readtm_calib_spectrum[0], /add_legend

  stop
end