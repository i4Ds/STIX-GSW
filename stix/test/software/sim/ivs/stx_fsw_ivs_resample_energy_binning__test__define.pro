;+
; :FILE_COMMENTS:
;   Test routine for the stx_fsw_ivs_resample_energy_binning funtion to resample a given spectrogram into a coarser energy binning 
;
; :CATEGORIES:
;   Flight Software Simulator, Interval Selection, Spectrogram
;
; :EXAMPLES:
;   res = iut_test_runner('stx_fsw_ivs_resample_energy_binning__test',report=report)
;
; :HISTORY:
;   31-Oct-2015 - Nicky Hochmuth FHNW, initial release
;
;-

;+
; :DESCRIPTION:
;
;
;-
pro stx_fsw_ivs_resample_energy_binning__test::test_no_resampling

  n_e = 32l
  n_t = 5l
  count = 10l
  thermalboundary = 10

  same_bins = [transpose(indgen(n_e)),transpose(indgen(n_e))+1]

  counts = ulonarr(n_e,n_t)+count

  time_axis = stx_construct_time_axis(indgen(n_t+1))

  spec = stx_fsw_ivs_spectrogram(counts, time_axis)

  new_spec = stx_fsw_ivs_resample_energy_binning(spec,nontermal_binning=same_bins, termal_binning=same_bins,  thermalboundary=thermalboundary)

  assert_array_equals,  spec.counts, new_spec.counts, "resample to the same dimensions does not produce a clone"

end

;+
; :DESCRIPTION:
;
;
;
;-
pro stx_fsw_ivs_resample_energy_binning__test::test_resample

  n_e = 32l
  n_t = 5l
  count = 10l
  thermalboundary = 8

  termal_binning = [transpose(indgen(4)*8),transpose(indgen(4)*8)+8]
  nontermal_binning = [transpose(indgen(8)*4),transpose(indgen(8)*4)+4]

  counts = ulonarr(n_e,n_t)+count

  time_axis = stx_construct_time_axis(indgen(n_t+1))

  spec = stx_fsw_ivs_spectrogram(counts, time_axis)

  new_spec = stx_fsw_ivs_resample_energy_binning(spec, nontermal_binning=nontermal_binning, termal_binning=termal_binning,  thermalboundary=thermalboundary)

  assert_equals,  total(spec.counts, /PRESERVE_TYPE), total(new_spec.counts, /PRESERVE_TYPE), "some counts get lost"

  assert_equals,  n_elements(new_spec.energy_edges), 8, "wrong number of new energy bins"

end

pro stx_fsw_ivs_resample_energy_binning__test::test_resample_no_termalboundary_match

  n_e = 32l
  n_t = 5l
  count = 10l
  thermalboundary = 17

  termal_binning = [transpose(indgen(4)*8),transpose(indgen(4)*8)+8]
  nontermal_binning = [transpose(indgen(8)*4),transpose(indgen(8)*4)+4]

  counts = ulonarr(n_e,n_t)+count

  time_axis = stx_construct_time_axis(indgen(n_t+1))

  spec = stx_fsw_ivs_spectrogram(counts, time_axis)

  new_spec = stx_fsw_ivs_resample_energy_binning(spec, nontermal_binning=nontermal_binning, termal_binning=termal_binning,  thermalboundary=thermalboundary)

  assert_equals,  total(spec.counts, /PRESERVE_TYPE), total(new_spec.counts, /PRESERVE_TYPE), "some counts get lost"

  assert_equals,  n_elements(new_spec.energy_edges), 7, "wrong number of new energy bins"

end

;+
; Define instance variables.
;-
pro stx_fsw_ivs_resample_energy_binning__test__define
  compile_opt idl2, hidden

  define = { stx_fsw_ivs_resample_energy_binning__test, $
    inherits iut_test }

end

