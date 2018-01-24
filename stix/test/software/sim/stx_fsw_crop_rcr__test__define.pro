;+
; :file_comments:
;   Test routine for the FSW stx_fsw_crop_rcr funtion to crop a rate control data sequence to a given time interval
;
; :categories:
;   Flight Software Simulator, rate contgrol, testing
; :examples:
;   res = iut_test_runner('stx_fsw_crop_rcr__test')
;
; :history:
;   17-Jul-2015 - Nicky Hochmuth FHNW, initial release
;
;-

;+
; :description:
;   Setup of this test. The testing is done with a predefined rcr sequence of 10 entries.
;
;
;-
pro stx_fsw_crop_rcr__test::beforeclass
  
  
  rcr = {type : "stx_fsw_result_rate_control" ,$
         data : indgen(10, /byte), $
         time_axis : stx_construct_time_axis(indgen(11)) $
        }
  
  self.rcr = PTR_NEW(rcr)
  
end


;+
; :description:
;
;
;
;-
pro stx_fsw_crop_rcr__test::test_rcr_creation
  
  assert_true, PTR_VALID(self.rcr)
  
  rcr = *self.rcr
  
  assert_true, ppl_typeof(rcr, COMPARETO='stx_fsw_result_rate_control')
  
  ;the total count should be equal to the number of all events
  assert_equals, 10, N_ELEMENTS(rcr.data)
  
end

;+
; :description:
;
; crops at exact boundaries at start and end
;
;-
pro stx_fsw_crop_rcr__test::test_parameter_default

  rcr = *self.rcr

  
  ;default start and end 
  rcr_c = stx_fsw_crop_rcr(rcr)
  assert_equals, 10, N_ELEMENTS(rcr_c.data)
  
  ;default end
  rcr_c = stx_fsw_crop_rcr(rcr, stx_construct_time(time=5))
  assert_equals, 5, N_ELEMENTS(rcr_c.data)

end

;+
; :description:
;
; crops at exact boundaries at start and end
;
;-
pro stx_fsw_crop_rcr__test::test_exact

  rcr = *self.rcr
    
  rcr_croped = stx_fsw_crop_rcr(rcr, stx_construct_time(time=3), stx_construct_time(time=8)) 
  
  
  assert_equals, 5, N_ELEMENTS(rcr_croped.data)
  assert_equals, INDGEN(5, /byte)+3, rcr_croped.data

end


;+
; :description:
;
; crops at exact boundaries at start
;
;-
pro stx_fsw_crop_rcr__test::test_exact_left

  rcr = *self.rcr

  rcr_croped = stx_fsw_crop_rcr(rcr, stx_construct_time(time=3), stx_construct_time(time=8.3)) 
  
  
  assert_equals, 5, N_ELEMENTS(rcr_croped.data)
  assert_equals, INDGEN(5, /byte)+3, rcr_croped.data

end

;+
; :description:
;
; crops at exact boundaries at the end
;-
pro stx_fsw_crop_rcr__test::test_exact_right

  rcr = *self.rcr

  rcr_croped = stx_fsw_crop_rcr(rcr, stx_construct_time(time=3.5), stx_construct_time(time=8)) 
  
  
  assert_equals, 4, N_ELEMENTS(rcr_croped.data)
  assert_equals, INDGEN(4, /byte)+4, rcr_croped.data

end

;+
; :description:
;
; crops at fuzzy boundaries at start and end
;-
pro stx_fsw_crop_rcr__test::test_fuzzy

  rcr = *self.rcr

  rcr_croped = stx_fsw_crop_rcr(rcr, stx_construct_time(time=3.5), stx_construct_time(time=8.3)) 
  
  assert_equals, 4, N_ELEMENTS(rcr_croped.data)
  assert_equals, INDGEN(4, /byte)+4, rcr_croped.data

end

;+
; Define instance variables.
;-
pro stx_fsw_crop_rcr__test__define
  compile_opt idl2, hidden
  
  define = { stx_fsw_crop_rcr__test, $
    rcr : ptr_new(), $
    inherits iut_test }
    
end

