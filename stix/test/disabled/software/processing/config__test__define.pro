

;+
; init at object instanciation
;-
pro config__test::beforeclass


end


;+
; cleanup at object destroy
;-
pro config__test::afterclass


end

;+
; cleanup after each test case
;-
pro config__test::after


end

;+
; init before each test case
;-
pro config__test::before


end


;pro config__test::test_locate
;  config = ptr_new(stx_configuration_manager())
;  *config->load_configuration
;  history = ppl_history()
;
;  lf = stx_module_locate_data_file()
;  rd = stx_module_read_data()
;
;  in = { start_time:'01-Jan-2012 00:00:00', end_time:'01-Jan-2012 01:00:00', compression_level:1 }
;  assert_true = lf->execute(in, files, history, config)
;
;  in = { data_files:files }
;
;  assert_true, rd->execute(in, data, history, config)
;  
;end


;+
; Define instance variables.
;-
pro config__test__define
  compile_opt idl2, hidden
  
  define = { config__test, $
    ;your class variables here
    inherits iut_test }
end

