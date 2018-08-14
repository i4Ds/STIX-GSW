;+
; :project:
;       STIX
;
; :name:
;       stx_l1_ql_spectrum_structures
;
; :purpose:
;       Makes structures to store quick look l1 spectra TM and serialise to fits
;
; :categories:
;       structures, telemetry
;
; :params:
;    n_samples : in, type="int"
;             Number of spectra
;
; :returns:
;    A dictionary containing the control and data structures
;
; :examples:
;    structures = stx_l1_ql_spectrum_structures(10)
;    control_struc = structures.control
;    data_struc = structures.data
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-

function stx_l1_ql_spectrum_structures, n_samples

  control_struc = { $
    pixel_mask : bytarr(16), $
    integration_time : 0, $
    compression_scheme_spec : intarr(3), $
    compression_scheme_trigger : intarr(3) $
  }

  data_struc = { $
    detector_mask : bytarr(32), $
    triggers : lonarr(32), $
    spectrum : lonarr(32, 32) $
  }

  return, DICTIONARY('control', control_struc, 'data', replicate(data_struc, n_samples))

end