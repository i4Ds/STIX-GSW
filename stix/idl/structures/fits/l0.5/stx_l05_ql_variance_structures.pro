;+
; :project:
;       STIX
;
; :name:
;       stx_l05_ql_variance_structures
;
; :purpose:
;       Makes structures to store quick look l1 variance TM and serialise to fits
;
; :categories:
;       structures, telemetry
;
; :params:
;    n_variances : in, type="int"
;             Number of variance measurements
;
; :returns:
;    A dictionary containing the control and data structures
;
; :examples:
;    structures = stx_l05_ql_variance_structures(10)
;    control_struc = structures.control
;    data_struc = structures.data
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-

function stx_l05_ql_variance_structures, n_variances

  control_struc = { $
    integration_time : 0.0, $
    detector_mask : bytarr(32), $
    pixel_mask : bytarr(16), $
    energy_bin_mask : bytarr(32), $
    compression_scheme_variance : intarr(3), $
    samples_per_variance: 0 $
  }

  data_struc = { $
    variance : 0 $
  }

  return, DICTIONARY('control', control_struc, 'data', replicate(data_struc, n_variances))

end