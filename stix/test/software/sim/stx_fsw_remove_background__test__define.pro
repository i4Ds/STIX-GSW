;+
; :FILE_COMMENTS:
;   Test routine for the stx_fsw_remove_background funtion to supstract a raw FSW background from a given spectrogram
;
; :CATEGORIES:
;   Flight Software Simulator, Background, Spectrogram
;
; :EXAMPLES:
;   res = iut_test_runner('stx_fsw_remove_background__test',report=report)
;
; :HISTORY:
;   02-Noc-2015 - Nicky Hochmuth FHNW, initial release
;
;-

;+
; :DESCRIPTION:
;
;
;-
pro stx_fsw_remove_background__test::test_no_background

  n_e = 32L
  n_t = 5L
  count = 10L
  
  counts = ulonarr(n_e,n_t)+count
  background = [0,0,0,0,0]
  
  bg_energy_axis = stx_construct_energy_axis(select=[0,6,10,16,20,32])
  
  detector_mask = bytarr(32)+1b
  time_axis = stx_construct_time_axis(indgen(n_t+1))
    
  bg_counts = stx_fsw_remove_background(counts, background, bg_energy_axis, time_axis, detector_mask)
  
  assert_array_equals,  counts, bg_counts, "removing a 0 background changed the number of counts"

end


;+
; :DESCRIPTION:
;
;
;-
pro stx_fsw_remove_background__test::test_more_background_than_counts
  n_e = 32L
  n_t = 5L
  count = 10L

  counts = ulonarr(n_e,n_t)+count
  background = intarr(5)+count*10

  bg_energy_axis = stx_construct_energy_axis(select=[0,6,10,16,20,32])

  detector_mask = bytarr(32)+1b
  time_axis = stx_construct_time_axis(indgen(n_t+1))

  bg_counts = stx_fsw_remove_background(counts, background, bg_energy_axis, time_axis, detector_mask)

  assert_equals,  max(bg_counts), 0, "still counts left"
  
  assert_equals,  min(bg_counts), 0, "negativ counts detected"

end


;+
; :DESCRIPTION:
;
;
;-
pro stx_fsw_remove_background__test::test_remove_background
  n_e = 32L
  n_t = 5L
  count = 10L

  counts = ulonarr(n_e,n_t)+count
  
  ;as many background bands as the spectrogram
  ;constant background of 1
  background = ulonarr(n_e)+1
  bg_energy_axis = stx_construct_energy_axis()

  ;only one active detector
  detector_mask = bytarr(32)
  detector_mask[0] = 1
  
  time_axis = stx_construct_time_axis(indgen(n_t+1))

  bg_counts = stx_fsw_remove_background(counts, background, bg_energy_axis, time_axis, detector_mask)
  
  assert_array_equals, bg_counts + 1, counts, 'wrong number of counts'  

end

;+
; Define instance variables.
;-
pro stx_fsw_remove_background__test__define
  compile_opt idl2, hidden

  define = { stx_fsw_remove_background__test, $
    inherits iut_test }

end

