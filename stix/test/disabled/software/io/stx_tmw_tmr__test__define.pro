
pro stx_tmw_tmr__test::beforeclass
;   pixel_data = stx_pixel_data()
;   pixel_data.counts = fix(randomu(systime(/seconds),32,12)*1000) 
;   self.pxl_data = ptr_new(pixel_data)
;   destroy, img
end

pro stx_tmw_tmr__test::afterclass
        
     ptr_free, self.pxl_data
end

;+
; :description:
;    This function tests the writing and reading from pixel data to telemetry format and vice versa
;-
;pro stx_tmw_tmr__test::test_science_header_science_data_archive_buffer_ssid_10
;  
;  ssid = 10
;  
;  tmw = stx_telemetry_writer()
;  
;  archive = replicate({stx_fsw_archive_buffer}, 4)
;  
;  archive.energy_science_channel = [ 1, 5, 30, 32] - 1
;  archive.detector_index = [1, 6, 23, 32]
;  archive.pixel_index = [1, 7, 12, 12] - 1
;  archive.counts = [100, 1, 256, 290]
;  
;  delta_time = 3.75d
;  rc_regime = 2
;  pixel_mask = byte([1,1,1,0,0,0,0,1,1,1,1,1])
;  cfl = [100,200]
;  detector_mask = bytarr(32)+1
;  detector_mask[3:5] = 0
;  livetime = uindgen(16)*100
;  
;  debug=1
;  
;  tmw->science_header_science_data, archive, ssid, $
;                                     delta_time = delta_time, $
;                                     rc_regime = rc_regime, $
;                                     pixel_mask = pixel_mask, $
;                                     cfl = cfl, $
;                                     detector_mask = detector_mask, $
;                                     livetime = livetime, $
;                                     debug=debug
;   
;  tmw->debug_message, "done"
;  stream = tmw->getbuffer(/trim)
;  tmr = stx_telemetry_reader(stream=stream)
;  tmr->debuginfo
;  
;  shsd = tmr->science_header_science_data(ssid)
;  r_pos = tmr->getPosition()
;  w_pos = tmw->getPosition()
;  
;  ;nothing left to read?
;  assert_equals, r_pos[0], w_pos[0]
;  
;  ;right dataformat? 
;  assert_true, ppl_typeof(shsd.data,compareto="stx_fsw_archive_buffer",/raw)
;  
;  ;same number of data entries?
;  assert_equals, n_elements(shsd.data), n_elements(archive)
;  
;  archive_out = shsd.data
;  
;  ;same data?
;  for i=0l, n_elements(archive)-1 do begin
;    entry_in = archive[i]
;    
;    entry_out_idx = where( $
;       archive_out.energy_science_channel eq entry_in.energy_science_channel AND $
;       archive_out.detector_index eq entry_in.detector_index AND $
;       archive_out.pixel_index eq entry_in.pixel_index AND $
;       archive_out.counts eq entry_in.counts, $
;       count)
;    
;    assert_equals, count, 1
;  endfor 
;       
;    
;  destroy, tmr
;  destroy, tmw
;    
;end

;pro stx_tmw_tmr__test::test_stx_archive_struct_to_telemetry_buffer
;    
;  archive = replicate({stx_fsw_archive_buffer}, 4)
;  
;  archive.energy_science_channel = [ 1, 5, 30, 32] - 1
;  archive.detector_index = [1, 6, 23, 32]
;  archive.pixel_index = [1, 7, 12, 12] - 1
;  archive.counts = [100, 1, 256, 290]
;  
;  out = stx_archive_struct_to_telemetry_buffer(archive)
;  
;  assert_true, ppl_typeof(out, compareto="byte_array")
;  assert_equals, 16, n_elements(out)
;  assert_array_equals, byte([0,         2,            100, $
;                             32+8+1,    16+8,                   $
;                             255-64-8,  255-128-16-1, 255,      $
;                             255-64-8,  64+32+8+4,              $
;                             255,       255-16-1,     255,      $
;                             255,       255-16-1,     32+2+1 ]), out
;  
;    
;end


;+
; :description:
;    This function tests if the writing and reading into a memory byte stream is working correct
;
; :categories:
;    simulation, converter, telemetry
;
; :history:
;    16-Apr-2013 - Nicky Hochmuth (FHNW), initial release
;-
;pro stx_tmw_tmr__test::test_memory_stream_io
;  
;  seed = systime(1)
;  no_random = fix(randomu(seed)*30000l)
;  
;  testinput = make_array(no_random,3,/UINT, VALUE=2)
;  testinput[*,2] = ceil(randomu(seed,no_random)*16)
;  testinput[*,0] = floor(randomu(seed,no_random) * (2l^testinput[*,2]))
;  
;  
;  dims = size(testinput)
;  cases = dims[1]
;  
;  startTime = systime(1)
;  tmw = stx_telemetry_writer(size=cases*2)
;  for i=0, cases-1 do tmw->write, fix(testinput[i,0],TYPE=testinput[i,1]), bits=testinput[i,2] 
;  
;  writetime = systime(1) - startTime
;  
;  startTime = systime(1)
;  
;  tmr = stx_telemetry_reader(stream=tmw->getBuffer(/trim))
;  
;  for i=0, cases-1 do begin
;    data = tmr->read(testinput[i,1],BITS=testinput[i,2])
;    
;    assert_equals, testinput[i,0], data
;    
;  endfor
;  
;  readtime = systime(1) - startTime
;  
;  print, "[INFO] write ", trim(cases), " data entries in ", trim(writetime) , " sec"
;  print, "[INFO] read and test ", trim(cases), " data entries in ", trim(readtime) , " sec"
;  
;  destroy, tmr
;  destroy, tmw
;end

;+
; :description:
;    This function tests if the writing and reading into a file byte stream is working correct
;
; :categories:
;    simulation, converter, telemetry
;
; :history:
;    16-Apr-2013 - Nicky Hochmuth (FHNW), initial release
;-
;pro stx_tmw_tmr__test::test_file_stream_io
;  
;  filename="test_case_datafile.bin"
;  
;  seed = systime(1)
;  no_random = fix(randomu(seed)*30000l)
;  
;  testinput = make_array(no_random,3,/UINT, VALUE=2)
;  testinput[*,2] = ceil(randomu(seed,no_random)*16)
;  testinput[*,0] = floor(randomu(seed,no_random) * (2l^testinput[*,2]))
;  
;  dims = size(testinput)
;  cases = dims[1]
;  
;  startTime = systime(1)
;  tmw = stx_telemetry_writer(filename=filename,size=cases*2)
;  for i=0, cases-1 do tmw->write, fix(testinput[i,0],TYPE=testinput[i,1]), bits=testinput[i,2] 
;  
;  writetime = systime(1) - startTime
;  
;  startTime = systime(1)
;  
;  tmw->flushtofile
;  destroy, tmw
;  tmr = stx_telemetry_reader(filename=filename,buffersize=2048L*2048)
;  
;  for i=0, cases-1 do begin
;    data = tmr->read(testinput[i,1],BITS=testinput[i,2])
;    assert_equals, testinput[i,0], data
;  endfor
;  
;  readtime = systime(1) - startTime
;  
;  print, "[INFO] write ", trim(cases), " data entries in ", trim(writetime) , " sec"
;  print, "[INFO] read and test ", trim(cases), " data entries in ", trim(readtime) , " sec"
;  
;  destroy, tmr
;end



pro stx_tmw_tmr__test__define
  compile_opt idl2, hidden
  
  void = { stx_tmw_tmr__test, $
    pxl_data : ptr_new(), $
    inherits iut_test }
end
