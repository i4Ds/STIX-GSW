;+
; :project:
;       STIX
;
; :name:
;       stx_l2_ql_calibration_spectra_structures
;      
; :categories:
;       fits, io, quicklook, calibration
;
; :purpose:
;       Makes structures to store quick look l2 stx_l2_ql_calibration_spectra_structures
;
; :categories:
;       structures, telemetry
;
; :params:
;    n_flares : in, type="int"
;             Number of flares
;
; :returns:
;    A dictionary containing the control and data structures
;
; :examples:
;    structures = stx_l2_ql_calibration_spectra_structures(10)
;    control_struc = structures.control
;    data_struc = structures.data
;
; :history:
;       02-May-2018 – SAM (TCD) init
;       09-Apr-2020 – ECMD (Graz), initial release of stx_l2_ql_calibration_spectra_structures,
;                                  based on stx_l1_ql_flare_flag_location
;
;-
function stx_l2_ql_calibration_spectra_structures, nsubspec

  control = { $
    detector_mask : bytarr(32), $
    pixel_mask : bytarr(16), $
    subspectrum_mask: bytarr(8) ,$
    duration : 0., $
    quiet_time : 0., $
    live_time : 0., $
    average_temp : 0., $
    compression_scheme_accum_skm : intarr(3), $
    subspectra_definition: intarr(3,nsubspec) $
  }

  data = { $
    time: 0.0d, $
    timedel: 0.0, $
    spectrum : lonarr(1024, 12, 32) $
  }

  return, dictionary('control', control, 'data', data)

end