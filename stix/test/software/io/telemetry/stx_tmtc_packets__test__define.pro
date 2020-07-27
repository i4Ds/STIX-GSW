;+
; :file_comments:
;   Test routine for the TMTC reader/writer packets
;
; :categories:
;   Flight Software Simulator, TMTC, testing
;
; :examples:
;   res = iut_test_runner('stx_tmtc_packets__test')
;
; :history:
;   20-Jun-2018 - Nicky Hochmuth (FHNW), initial release
;  
;+
; :description:
;   Setup of this test.
;-
pro stx_tmtc_packets__test::beforeclass
  

end


;+
; cleanup at object destroy
;-
pro stx_tmtc_packets__test::afterclass


end

;+
; cleanup after each test case
;-
pro stx_tmtc_packets__test::after


end

;+
; init before each test case
;-
pro stx_tmtc_packets__test::before


end



pro stx_tmtc_packets__test::test_flare_list_0_entries
  
  fl_in = stx_asw_ql_flare_list(NUMBER_FLARES=0, /RANDOM )
  
  tmtc_writer = stx_telemetry_writer()
  tmtc_writer->setdata, ql_flare_list=fl_in
  stream = tmtc_writer->getBuffer(/trim)
  
  tmtc_reader = stx_telemetry_reader(STREAM=stream, /scan_mode)
  tmtc_reader->getdata, asw_ql_flare_list=asw_ql_flare_list_blocks, SOLO_PACKETS=sp
  fl_out = asw_ql_flare_list_blocks[0]
  
  destroy, tmtc_reader
  destroy, tmtc_writer
  
  assert_equals, fl_in.pointer_start, fl_out.pointer_start, "pointer start does not match"
  assert_equals, fl_in.pointer_end, fl_out.pointer_end, "pointer end does not match"
  assert_equals, fl_in.NUMBER_FLARES, fl_out.NUMBER_FLARES, "number flares does not match"
  


end

pro stx_tmtc_packets__test::test_flare_one_packet
  
 
  fl_in = stx_asw_ql_flare_list(NUMBER_FLARES=2,/RANDOM)
  
  tmtc_writer = stx_telemetry_writer()

  tmtc_writer->setdata, ql_flare_list=fl_in
  stream = tmtc_writer->getBuffer(/trim)

  tmtc_reader = stx_telemetry_reader(STREAM=stream, /scan_mode)
  tmtc_reader->getdata, asw_ql_flare_list=asw_ql_flare_list_blocks, SOLO_PACKETS=sp
  fl_out = asw_ql_flare_list_blocks[0]
  destroy, tmtc_reader
  destroy, tmtc_writer
  
  assert_equals, fl_in.NUMBER_FLARES, fl_out.NUMBER_FLARES, "number flares does not match"
  ;assert_array_equals, stx_time2any(fl_in.START_COARSE), stx_time2any(fl_out.START_COARSE), "START_COARSE does not match"
  ;assert_array_equals, stx_time2any(fl_in.END_COARSE), stx_time2any(fl_out.END_COARSE), "END_COARSE does not match"  
  assert_array_equals, fl_in.TM_VOLUME, fl_out.TM_VOLUME, "TM_VOLUME does not match"
  assert_array_equals, fl_in.HIGH_FLAG, fl_out.HIGH_FLAG, "HIGH_FLAG does not match"
  assert_array_equals, fl_in.AVG_CFL_Z, fl_out.AVG_CFL_Z, "AVG_CFL_Z does not match"
  assert_array_equals, fl_in.AVG_CFL_Y, fl_out.AVG_CFL_Y, "AVG_CFL_Y does not match"
  assert_array_equals, fl_in.PROCESSING_STATUS, fl_out.PROCESSING_STATUS, "PROCESSING_STATUS does not match"
  
end

pro stx_tmtc_packets__test::test_flare_many_packets

  fl_in = stx_asw_ql_flare_list(NUMBER_FLARES=400,/RANDOM)
  tmtc_writer = stx_telemetry_writer()
  tmtc_writer->setdata, ql_flare_list=fl_in
  stream = tmtc_writer->getBuffer(/trim)

  tmtc_reader = stx_telemetry_reader(STREAM=stream, /scan_mode)
  tmtc_reader->getdata, asw_ql_flare_list=asw_ql_flare_list_blocks, SOLO_PACKETS=sp
  fl_out = asw_ql_flare_list_blocks[0]
  
  destroy, tmtc_reader
  destroy, tmtc_writer

  assert_equals, fl_in.NUMBER_FLARES, fl_out.NUMBER_FLARES, "number flares does not match"
  ;assert_array_equals, stx_time2any(fl_in.START_COARSE), stx_time2any(fl_out.START_COARSE), "START_COARSE does not match"
  ;assert_array_equals, stx_time2any(fl_in.END_COARSE), stx_time2any(fl_out.END_COARSE), "END_COARSE does not match"  
  assert_array_equals, fl_in.TM_VOLUME, fl_out.TM_VOLUME, "TM_VOLUME does not match"
  assert_array_equals, fl_in.HIGH_FLAG, fl_out.HIGH_FLAG, "HIGH_FLAG does not match"
  assert_array_equals, fl_in.AVG_CFL_Z, fl_out.AVG_CFL_Z, "AVG_CFL_Z does not match"
  assert_array_equals, fl_in.AVG_CFL_Y, fl_out.AVG_CFL_Y, "AVG_CFL_Y does not match"
  assert_array_equals, fl_in.PROCESSING_STATUS, fl_out.PROCESSING_STATUS, "PROCESSING_STATUS does not match"
end

;+
; Define instance variables.
;-
pro stx_tmtc_packets__test__define
  compile_opt idl2, hidden

  define = { stx_tmtc_packets__test, $
    inherits iut_test }

end

