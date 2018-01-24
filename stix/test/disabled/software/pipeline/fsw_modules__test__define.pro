

;+
; init at object instanciation
;-
pro fsw_modules__test::beforeclass
;    cfm = obj_new("ppl_configuration_manager","stix/dbase/conf/stx_flight_software_simulator_default.config")
;    cfm->load_configuration
;    self.cfm = ptr_new(cfm)
end


;+
; cleanup at object destroy
;-
pro fsw_modules__test::afterclass


end

;+
; cleanup after each test case
;-
pro fsw_modules__test::after


end

;+
; init before each test case
;-
pro fsw_modules__test::before


end


;pro fsw_modules__test::test_ivs
;  restore, filename = concat_dir(getenv("STX_IUT_DATA"),"archive_buffer.sav"), /verbose
;  
;  ;ab.counts*=1000L
;  
;  ivs = obj_new('stx_fsw_module_intervalselection','stx_fsw_module_intervalselection',ppl_typeof(ab,/raw))
;  
;  
;  
;  succes = ivs->execute(ab, out ,ppl_history(),self.cfm)
;  
;  assert_equals, succes, 1 
;end

;pro fsw_modules__test::test_flaredetection_selection
;  
;;  restore, filename = concat_dir(getenv("STX_IUT_DATA"),"ql_acc.sav"), /verbose
;;  
;;  
;;  ql_flare_detection = *ql_acc[4]
;;  background =  make_array(12,2,value=3,/integer)
;;  
;; assert_true, ppl_typeof(ql_flare_detection, compareto="stx_fsw_ql_flare_detection") 
;;  
;;  (*self.cfm)->set, module="stx_ds_module_flare_detection", nbl=[8,4]
;    
;  default, n_t,                         500
;  default, quicklook_accumulated_data,  [[(sin(findgen(n_t)/40.0)+1)*120],[(sin((findgen(n_t)+3)/20.0)+2)*60]]
;  default, background,                  [[indgen(n_t)/20],[indgen(n_t)/40]]  
;  
;  ql_flare_detection = { $
;    type : "stx_fsw_ql_flare_detection", $
;    time_axis : stx_construct_time_axis(findgen(n_t+1)*4), $
;    accumulated_counts : ulong(transpose(quicklook_accumulated_data)) $ 
;  }
;    
;  fd = stx_fsw_module_flare_detection()
;  fs = stx_fsw_module_flare_selection()
;  
;  
;  succes = fd->execute({ql_counts:ql_flare_detection,background:background}, flare_flag ,ppl_history(),self.cfm)
;  
;  assert_equals, succes, 1
;  
;  succes = fs->execute({time:ql_flare_detection.time_axis,flare_flag:flare_flag}, flare_times ,ppl_history(),self.cfm)
;  assert_equals, succes, 1
;  assert_true, ppl_typeof(flare_times, compareto="stx_fsw_flare_selection_result", /raw)
;   
;end


;pro fsw_modules__test::test_flaredetection_detection
;  
;  restore, filename = concat_dir(getenv("STX_IUT_DATA"),"ql_acc.sav"), /verbose
;  
;  ql_flare_detection = ql_acc.STX_FSW_QL_FLARE_DETECTION
;  
;  ql_flare_detection = ppl_replace_tag(ql_flare_detection, "ACCUMULATED_COUNTS", reform(ql_flare_detection.ACCUMULATED_COUNTS))
;  
;  
;  assert_true, ppl_typeof(ql_flare_detection, compareto="stx_fsw_ql_flare_detection") 
;  
;  ;(*self.cfm)->set, module="stx_fsw_module_flare_detection", nbl=[8,4]
;    
;  bd = stx_fsw_module_background_determination()  
;  fd = stx_fsw_module_flare_detection()
;  
;  in_bd = { ql_bkgd_acc     : ql_acc.STX_FSW_QL_BKGD_MONITOR $
;          , lt_bkgd_acc     : ql_acc.STX_FSW_QL_BKGD_MONITOR_LT $
;          , previous_bkgd   : 0. $
;          , det_bkgd_ena    : 1b $
;          , flare_flag      : 0b $
;  }
;  
;  succes = bd->execute(in_bd, background ,ppl_history(),self.cfm)
;  assert_equals, succes, 1
;  
;  background = fix(background)
;  
;  succes = fd->execute({ql_counts:ql_flare_detection,background:background}, flare_flag ,ppl_history(),self.cfm)
;  assert_equals, succes, 1
;   
;end
;+
; Define instance variables.
;-
pro fsw_modules__test__define
  compile_opt idl2, hidden
  
  define = { fsw_modules__test, $
    ;your class variables here
    cfm : ptr_new(), $
    inherits iut_test }
end

