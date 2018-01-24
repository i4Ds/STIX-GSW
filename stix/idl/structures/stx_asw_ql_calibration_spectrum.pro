function stx_asw_ql_calibration_spectrum, calsubspec=calsubspec, start_time=start_time, end_time=end_time

  if n_elements(calsubspec) eq 0 then calsubspec = list()
  if n_elements(start_time) eq 0 then start_time = stx_time()
  if n_elements(end_time) eq 0 then end_time = stx_time()

;  calsubspec = { $
;    type : 'stx_asw_ql_calibration_subspectrum', $
;    spectrum : lonarr(1024, 12, 32), $
;    lower_energy_bound_channel : 0, $
;    number_of_summed_channels : 0, $
;    number_of_spectral_points : 0, $
;    pixel_mask : bytarr(12), $ [0,1,...,11]
;    detector_mask : bytarr(32) $ [0,1,...,31]
;  }

  return, { $
    type            : 'stx_asw_ql_calibration_spectrum', $
    start_time      : start_time, $
    end_time        : end_time, $
    subspectra      : calsubspec $
  }

end