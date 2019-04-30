;+
; :project:
;       STIX
;
; :name:
;       stx_l1_ql_flare_flag_location
;
; :purpose:
;       Makes structures to store quick look l1 flare flag and location TM and serialise to fits
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
;    structures = stx_l1_ql_flare_flag_location(10)
;    control_struc = structures.control
;    data_struc = structures.data
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-


function stx_l1_ql_flare_flag_location, n_flares

  control_struc = { $
    integration_time : 0, $
    n_samples : 0 $
  }

  data_struc = { $
    flare_flag : 0, $
    loc_z : 0, $
    loc_y : 0 $
  }

  return, DICTIONARY('control', control_struc, 'data',  replicate(data_struc, n_flares))
end