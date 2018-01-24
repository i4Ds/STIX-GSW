;+
; :file_comments:
;   Test routine for the FSW stx_fsw_ivs_column_spc funtion to split a given spectrogram into many spectroscopy time energy intervals
;
; :categories:
;   Flight Software Simulator, Interval Selection, Spectroscopy, testing
;
; :examples:
;   res = iut_test_runner('stx_fsw_ivs_column_spc__test')
;
; :history:
;   24-Sep-2015 - Nicky Hochmuth FHNW, initial release
;
;-



;+
; :description:
;
;
;
;-
pro stx_fsw_ivs_column_spc__test::test_total_count
  
  n_e = 32L
  n_t = 50L
  count = 50L
  
  counts = ULONARR(n_e,n_t)
  counts[*] = count
  time_axis = stx_construct_time_axis(indgen(n_t+1))
   
  spec = stx_fsw_ivs_spectrogram(counts, time_axis)
  
  spec_p = ptr_new(spec)
  
  ivs_c = stx_fsw_ivs_column_spc(0, n_t-1, spec_p, MIN_COUNT=[400,400] )
  
  intervals = ivs_c->get_intervals()
  
  ;all counts should be in the result set
  assert_equals, total(intervals.counts), n_e * n_t * count,  "Some counts get lost"
  
  ;each energy band is split up into intervals
  ;therefore the number of total intervals should be a multible of energy bands 
  assert_equals, N_ELEMENTS(intervals.counts) mod n_e, 0,  "odd number of total intervals"
  
  
end


;+
; :description:
;
;
;
;-
pro stx_fsw_ivs_column_spc__test::test_time_split

  n_e = 32L
  n_t = 8L
  count = 1L

  counts = ULONARR(n_e,n_t)
  counts[*] = count
  time_axis = stx_construct_time_axis(indgen(n_t+1))

  spec = stx_fsw_ivs_spectrogram(counts, time_axis)

  spec_p = ptr_new(spec)

  ivs_c = stx_fsw_ivs_column_spc(0, n_t-1, spec_p, MIN_COUNT=[1,1], MIN_TIME=2.0  )

  intervals = ivs_c->get_intervals()
  
  ivs_c2 = stx_fsw_ivs_column_spc(0, n_t-1, spec_p, MIN_COUNT=[1,1], MIN_TIME=0.9  )

  intervals2 = ivs_c2->get_intervals()
  
  assert_equals, n_e * (n_t/2.0), N_ELEMENTS(intervals),  "a split every 2 seconds should generate n_t/4 * n_e intervals"

  assert_equals,  n_e * n_t, N_ELEMENTS(intervals2),  "a split every second should generate n_t * n_e intervals"



end

;+
; Define instance variables.
;-
pro stx_fsw_ivs_column_spc__test__define
  compile_opt idl2, hidden

  define = { stx_fsw_ivs_column_spc__test, $
    inherits iut_test }

end

