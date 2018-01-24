;+
; :file_comments:
;   Test routine for the FSW stx_fsw_crop_archive_buffer funtion to find all  entries for a given time interval
;
; :categories:
;   Flight Software Simulator, archive buffer, testing
;
; :examples:
;   res = iut_test_runner('stx_fsw_crop_archive_buffer__test')
;
; :history:
;   21-may-2015 - Nicky Hochmuth FHNW, initial release
;
;-

;+
; :description:
;   Setup of this test. The testing is done with a predefined archive buffer of 10 entries.
;
;
;-
pro stx_fsw_crop_archive_buffer__test::beforeclass
  
  
  ab = REPLICATE({STX_FSW_ARCHIVE_BUFFER},10)
  ab.relative_time_range[0,*] = transpose(indgen(10))
  ab.relative_time_range[1,*] = transpose(indgen(10)+1)
  self.ab = PTR_NEW(ab)
  
end


;+
; :description:
;
;
;
;-
pro stx_fsw_crop_archive_buffer__test::test_ab_creation
  
  assert_true, PTR_VALID(self.ab)
  
  ab = *self.ab
  
  
  
  ;the total count should be equal to the number off all events
  assert_equals, 10, N_ELEMENTS(ab)
  
end

;+
; :description:
;
; crops at exact boundaries at start and end
;
;-
pro stx_fsw_crop_archive_buffer__test::test_exact

  ab = *self.ab
   
  time = stx_time()  
  ab_croped = stx_fsw_crop_archive_buffer(ab, time, stx_time_add(time, SECONDS=3), stx_time_add(time, SECONDS=8)) 
  
  print, ab_croped.relative_time_range
  
  assert_equals, 5, N_ELEMENTS(ab_croped)
  assert_equals, FINDGEN(5)+3, ab_croped.relative_time_range[0,*]

end


;+
; :description:
;
; crops at exact boundaries at start
;
;-
pro stx_fsw_crop_archive_buffer__test::test_exact_left

  ab = *self.ab

  time = stx_time()
  ab_croped = stx_fsw_crop_archive_buffer(ab, time, stx_time_add(time, SECONDS=3), stx_time_add(time, SECONDS=8.3))

  assert_equals, 6, N_ELEMENTS(ab_croped)
  assert_equals, FINDGEN(6)+3, ab_croped.relative_time_range[0,*]

end

;+
; :description:
;
; crops at exact boundaries at the end
;-
pro stx_fsw_crop_archive_buffer__test::test_exact_right

  ab = *self.ab

  time = stx_time()
  ab_croped = stx_fsw_crop_archive_buffer(ab, time, stx_time_add(time, SECONDS=3.5), stx_time_add(time, SECONDS=8))

  assert_equals, 5, N_ELEMENTS(ab_croped)
  assert_equals, FINDGEN(5)+3, ab_croped.relative_time_range[0,*]

end

;+
; :description:
;
; crops at fuzzy boundaries at start and end
;-
pro stx_fsw_crop_archive_buffer__test::test_fuzzy

  ab = *self.ab

  time = stx_time()
  ab_croped = stx_fsw_crop_archive_buffer(ab, time, stx_time_add(time, SECONDS=2.8), stx_time_add(time, SECONDS=8.3))

  assert_equals, 7, N_ELEMENTS(ab_croped)
  assert_equals, FINDGEN(7)+2, ab_croped.relative_time_range[0,*]

end

;+
; Define instance variables.
;-
pro stx_fsw_crop_archive_buffer__test__define
  compile_opt idl2, hidden
  
  define = { stx_fsw_crop_archive_buffer__test, $
    ab : ptr_new(), $
    inherits iut_test }
    
end

