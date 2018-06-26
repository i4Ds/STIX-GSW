;+
; :project:
;       STIX
;
; :name:
;       stx_l1_ql_lightcurve_structures
;
; :purpose:
;       Makes structures to store quick look l1 lightcurve TM and serialise to fits
;
; :categories:
;       structures, telemetry
;
; :params:
;    n_times : in, type="int"
;             Number of time recorded
;
; :returns:
;    A dictionary containing the control and data structures
;
; :examples:
;    structures = stx_l1_ql_lightcurve_structures(10)
;    control_struc = structures.control
;    data_struc = structures.data
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-

function stx_l1_ql_lightcurve_structures, n_times

  control = { $
    integration_time : 0, $
    detector_mask : bytarr(33), $
    pixel_mask : bytarr(16), $
    energy_bin_mask : bytarr(33), $
    compression_scheme_counts : intarr(3),$
    compression_scheme_triggers : intarr(3)}

  data = { $
    counts: lonarr(5), $
    triggers : 0L, $
    rate_control_regeime: 1B}

  return, DICTIONARY('control', control, 'data', replicate(data, n_times))

end
