;+
; :project:
;       STIX
;
; :name:
;       stx_l05_ql_background_structures
;
; :purpose:
;       Makes structures to store quick look l05 backgound TM and serialise to fits
;
; :categories:
;       structures, telemetry
;
; :params:
;    n_energies : in, type="int"
;             Number of energies channels
;
;    n_samples : in, type="int"
;             Number of variance measurements
;
; :returns:
;    A dictionary containing the control and data structures
;
; :examples:
;    structures = stx_l05_ql_background_structures(5, 10)
;    control_struc = structures.control
;    data_struc = structures.data
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-

function stx_l05_ql_background_structures, n_energies, n_samples

  control_struc = { $
    integration_time : 0, $
    energy_bin_mask : bytarr(32), $
    compression_schema_background : intarr(3), $
    compression_schema_trigger : intarr(3) $
  }

  data_struc = { $
    triggers : 0L, $
    background : lonarr(n_energies) $
  }

  return, DICTIONARY('control', control_struc, 'data', replicate(data_struc, n_samples))

end