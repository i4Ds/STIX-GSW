;+
; :file_comments:
;   Test routine for the FSW stx_fsw_compact_archive_buffer funtion to compact the archive buffer into a 2d or 4d spectrogram
;
; :categories:
;   Flight Software Simulator, archive buffer, testing
;
; :examples:
;   res = iut_test_runner('stx_fsw_compact_archive_buffer__test')
;
; :history:
;   23-Sep-2015 - Nicky Hochmuth FHNW, initial release
;
;-

;+
; :description:
;   Setup of this test. The testing is done with a predefined archive buffer
;
;
;-
pro stx_fsw_compact_archive_buffer__test::beforeclass

 
  n_p = 12L
  n_d = 32L
  n_e = 32L
  n_t = 50L
   
  n_ab = n_t * n_p * n_d * n_e
  
  ab = REPLICATE({STX_FSW_ARCHIVE_BUFFER},n_ab)
  times = reform(transpose(reproduce(indgen(n_t),n_p * n_d * n_e)),n_ab)
  energies = reform(reproduce(reform(transpose(reproduce(indgen(n_e),n_p * n_d)),n_e * n_p * n_d),n_t),n_ab)
  detectors = reform(reproduce(reform(transpose(reproduce(indgen(n_d),n_p)),n_d * n_p),n_t * n_e), n_ab)
  pixels = reform(reproduce(transpose(indgen(n_p)),n_d * n_t * n_e), n_ab)
  
  ab.relative_time_range[0,*] = transpose(times)
  ab.relative_time_range[1,*] = transpose(times+1)
  ab.detector_index = detectors + 1
  ab.energy_science_channel = energies
  ab.pixel_index = pixels
  ab.counts = LINDGEN(n_ab) + 1
  
  
  self.ab = PTR_NEW(ab)

end


;+
; :description:
;
;
;
;-
pro stx_fsw_compact_archive_buffer__test::test_ab_creation

  assert_true, PTR_VALID(self.ab)

  ab = *self.ab

  n_ab = ulong64(N_ELEMENTS(ab))

  ;the total count should be equal to the number off all events
  
  assert_equals, total(ulong64(ab.counts), /PRESERVE_TYPE), (n_ab / 2) * (n_ab + 1)

end

;+
; :description:
;
; test if no counts get lost
;
;-
pro stx_fsw_compact_archive_buffer__test::test_counts

  ab = *self.ab

  
  counts = stx_fsw_compact_archive_buffer(ab, TOTAL_COUNTS = TOTAL_COUNTS)

  assert_equals, total(ulong64(ab.counts)), total(ulong64(counts), /PRESERVE_TYPE) 
  assert_equals, total(ulong64(ab.counts)), total(ulong64(total_counts), /PRESERVE_TYPE)

end

;+
; :description:
;
; test if a time axis was created for 100seconds
;
;-
pro stx_fsw_compact_archive_buffer__test::test_time

  ab = *self.ab


  counts = stx_fsw_compact_archive_buffer(ab,TIME_AXIS=TIME_AXIS)

  assert_equals, total(TIME_AXIS.duration), 50


end

;+
; :description:
;
; test if a all disabled detectors are excluded
;
;-
pro stx_fsw_compact_archive_buffer__test::test_detector_mask

  ab = *self.ab
  
  det_mask = BYTARR(32)
  det_mask[*] = 1
  disabled_detectors = byte(RANDOMU(seed,5)*32)
  disabled_detectors = disabled_detectors[UNIQ(disabled_detectors, SORT(disabled_detectors))]
  det_mask[disabled_detectors] = 0
  
  active_detectors = where(det_mask eq 1) 
  
  

  counts = stx_fsw_compact_archive_buffer(ab, total_counts=total_counts, DISABLED_DETECTORS_PIXEL_COUNTS=DISABLED_DETECTORS_PIXEL_COUNTS,DISABLED_DETECTORS_TOTAL_COUNTS=DISABLED_DETECTORS_TOTAL_COUNTS,DETECTOR_MASK=det_mask   )

  ;test if all disabled counts are set to 0
  assert_equals, total(DISABLED_DETECTORS_PIXEL_COUNTS[*,*,disabled_detectors,*]), 0

  ;test that no others counts are set to 0
  assert_equals, where(DISABLED_DETECTORS_PIXEL_COUNTS[*,*,active_detectors,*] eq 0), -1
  
  ;test if total counts is consistens
  assert_equals, total(ulong64(DISABLED_DETECTORS_PIXEL_COUNTS), /PRESERVE_TYPE), total(DISABLED_DETECTORS_TOTAL_COUNTS, /PRESERVE_TYPE)
  assert_true, total(DISABLED_DETECTORS_TOTAL_COUNTS, /PRESERVE_TYPE) lt total(ulong64(counts), /PRESERVE_TYPE) 
end

;+
; :description:
;
; test if no counts get lost
;
;-
pro stx_fsw_compact_archive_buffer__test::test_counts

  ab = *self.ab


  counts = stx_fsw_compact_archive_buffer(ab, TOTAL_COUNTS = TOTAL_COUNTS)

  assert_equals, total(ulong64(ab.counts)), total(ulong64(counts), /PRESERVE_TYPE)
  assert_equals, total(ulong64(ab.counts)), total(ulong64(total_counts), /PRESERVE_TYPE)

end

;+
; Define instance variables.
;-
pro stx_fsw_compact_archive_buffer__test__define
  compile_opt idl2, hidden

  define = { stx_fsw_compact_archive_buffer__test, $
    ab : ptr_new(), $
    inherits iut_test }

end

