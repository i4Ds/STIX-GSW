;+
; :project:
;       STIX
;
; :name:
;       stx_l2_ql_flare_flag_location
;
; :categories:
;       fits, io, quicklook, lightcurve
;
; :purpose:
;       Makes structures to store quick look l2 flare flag and location TM and serialise to fits
;
;
; :params:
;    n_flares : in, type="int"
;             Number of flares
;
; :returns:
;    A dictionary containing the control and data structures
;
; :examples:
;    structures = stx_l2_ql_flare_flag_location(10)
;    control_struc = structures.control
;    data_struc = structures.data
;
; :history:
;       02-May-2018 – SAM (TCD) init
;       08-Apr-2020 – ECMD (Graz), initial release of stx_l2_ql_flare_flag_location
;                                  based on stx_l1_ql_flare_flag_location
;
;-
function stx_l2_ql_flare_flag_location, n_flares

  control_struc = { $
    integration_time : 0, $
    n_samples : 0 $
  }

  data_struc = { $
    flare_flag : 0, $
    thermal_index:0, $
    nonthermal_index:0, $
    location_status:0, $
    loc_x : 0., $
    loc_y : 0. $
  }

  return, DICTIONARY('control', control_struc, 'data',  replicate(data_struc, n_flares))
end