;+
; :file_comments:
;   Test routine for the FSW stx_fsw_ivs_column_img funtion to split a given spectrogram into many time energy intervals for imaging
;
; :categories:
;   Flight Software Simulator, Interval Selection, Imaging, testing
;
; :examples:
;   res = iut_test_runner('stx_fsw_ivs_column_img__test')
;
; :history:
;   203-Oct-2015 - Nicky Hochmuth FHNW, initial release
;
;-

;+
; :description:
;
;
;
;-
pro stx_fsw_ivs_column_img__test::test_split_all

  n_e = 32L
  n_t = 50L
  count = 10L
  THERMALBOUNDARY = 10

  counts = ULONARR(n_e,n_t)+count

  time_axis = stx_construct_time_axis(indgen(n_t+1))

  spec = stx_fsw_ivs_spectrogram(counts, time_axis)

  spec_p = ptr_new(spec)

  ivs_c = stx_fsw_ivs_column_img(0, n_t-1, indgen(n_e),  spec_p, THERMALBOUNDARY=THERMALBOUNDARY, MIN_COUNT=[[1,1],[1,1]] ,MIN_TIME=[1.0,1]  )


  split_times = list()

  ;energy_axis = stx_construct_energy_axis()
  ;stx_interval_plot, spec, THERMALBOUNDARY=energy_axis.low[THERMALBOUNDARY]

  intervals = ivs_c->get_intervals(split_times=split_times)


  ;all counts should be in the result set
  assert_equals, total(intervals.counts), n_e * n_t * count,  "Some counts get lost"

  ;each energy band is split up into intervals
  ;therefore the number of total intervals should be a multible of energy bands
  assert_equals, N_ELEMENTS(intervals.counts), n_e * n_t,  "odd number of total intervals"


end

pro stx_fsw_ivs_column_img__test::test_get_merged_top_energy_channels

  n_e = 8L
  n_t = 50L
  count = 10L
  THERMALBOUNDARY = 10

  counts = ulonarr(n_e,n_t) + count
  counts[[6,7],*] = 1
  
  time_axis = stx_construct_time_axis(indgen(n_t+1))

  spec = stx_fsw_ivs_spectrogram(counts, time_axis, energy_edges = [0,4,8,12,16,20,24,28,32] )

  spec_p = ptr_new(spec)
  ivs_c = stx_fsw_ivs_column_img(0, n_t-1, indgen(n_e),  spec_p, THERMALBOUNDARY=THERMALBOUNDARY, MIN_COUNT=[[100,100],[200,200]] ,MIN_TIME=[1.0,1]  )
  
  ivs_cm = ivs_c->get_merged_top_energy_channels()
  
  spec_m = ivs_cm->get_spectrogram() 
  
  assert_equals, total(spec.counts, /preserve_type), total(spec_m.counts, /preserve_type), 'some counts get lost'
  assert_array_equals, spec_m.energy_edges, [0,4,8,12,16,20,24,32], 'energy axis is not correct'
end

pro stx_fsw_ivs_column_img__test::test_split_resampled_energy

  n_e = 8L
  n_t = 50L
  count = 10L
  THERMALBOUNDARY = 10

  counts = ulonarr(n_e,n_t)+count

  time_axis = stx_construct_time_axis(indgen(n_t+1))

  spec = stx_fsw_ivs_spectrogram(counts, time_axis, energy_edges = [0,4,8,12,16,20,24,28,32] )
  
  spec_p = ptr_new(spec)

  ivs_c = stx_fsw_ivs_column_img(0, n_t-1, indgen(n_e),  spec_p, THERMALBOUNDARY=THERMALBOUNDARY, MIN_COUNT=[[1,1],[1,1]] ,MIN_TIME=[1.0,1]  )


  split_times = list()

  ;energy_axis = stx_construct_energy_axis()
  ;stx_interval_plot, spec, THERMALBOUNDARY=energy_axis.low[THERMALBOUNDARY]

  intervals = ivs_c->get_intervals(split_times=split_times)


  ;all counts should be in the result set
  assert_equals, total(intervals.counts), n_e * n_t * count,  "Some counts get lost"

  ;each energy band is split up into intervals
  ;therefore the number of total intervals should be a multible of energy bands
  assert_equals, n_elements(intervals.counts), n_e * n_t,  "odd number of total intervals"


end


;+
; :description:
;
;
;
;-
pro stx_fsw_ivs_column_img__test::test_dist
  
  n_e = 32L
  n_t = 50L
  count = 3L
  THERMALBOUNDARY = 10
  
  counts = ULONG(dist(n_e,n_t)*count)
  time_axis = stx_construct_time_axis(indgen(n_t+1))
   
  spec = stx_fsw_ivs_spectrogram(counts, time_axis)
  
  spec_p = ptr_new(spec)
  
  ivs_c = stx_fsw_ivs_column_img(0, n_t-1, indgen(n_e),  spec_p, THERMALBOUNDARY=THERMALBOUNDARY, MIN_COUNT=[[400,100],[800,200]] ,MIN_TIME=[2.0,1]  )
  
  
  split_times = list()
  
  ;energy_axis = stx_construct_energy_axis() 
  ;stx_interval_plot, spec, THERMALBOUNDARY=energy_axis.low[THERMALBOUNDARY]
  
  intervals = ivs_c->get_intervals(split_times=split_times)
  
  
  ;all counts should be in the result set
  assert_equals, total(intervals.counts,/pres), total(counts,/pres) ,  "Some counts get lost"
  
  ;each energy band is split up into intervals
  ;therefore the number of total intervals should be a multible of energy bands 
  assert_equals, N_ELEMENTS(intervals), 362,  "odd number of total intervals"
  
  
end



;+
; Define instance variables.
;-
pro stx_fsw_ivs_column_img__test__define
  compile_opt idl2, hidden

  define = { stx_fsw_ivs_column_img__test, $
    inherits iut_test }

end

