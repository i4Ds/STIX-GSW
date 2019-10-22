;+
; :project:
;       STIX
;
; :name:
;       stx_l05_ql_calibration_spectra_structures
;
; :purpose:
;       Makes structures to store quick look l1 calbibration spectra TM and serialise to fits
;
; :categories:
;       structures, telemetry
;
; :params:
;    n_spec : in, type="int"
;             Number of calibration spectra
;
; :returns:
;    A dictionary containing the control and data structures
;
; :examples:
;    structures = stx_l05_ql_calibration_spectra_structures(32)
;    control_struc = structures.control
;    data_struc = structures.data
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-

function stx_l1_ql_calibration_spectra_structures, n_spec

  control = { $
    detector_mask : bytarr(32), $
    pixel_mask : bytarr(16), $
    duration : 0L, $
    quiet_time : 0L, $
    live_time : 0L, $
    average_temperature : 0L, $
    compression_scheme_calib : intarr(3) $
  }

  data = { $
    detecotr_mask : bytarr(32), $
    pixel_mask : bytarr(12), $
    lower_energy_bound_channel : 0, $
    number_of_summed_channels : 0, $
    number_of_spectral_points: 0, $
    spectrum : lonarr(32, 12, 32) $
  }

  return, DICTIONARY('control', control, 'data', replicate(data, n_spec))

end