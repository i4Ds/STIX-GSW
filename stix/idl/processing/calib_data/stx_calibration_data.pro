;+
;
; NAME:
;
;   stx_calibration_data
;
; PURPOSE:
;
;   Defines a STIX calibration data structure
;
; CALLING SEQUENCE:
;
;   cal_data = stx_calibration_data()
;
; OUTPUTS:
;
;   'stx_calibration_data' structure containing data from L2 calibration fits file
;
;
; HISTORY: March 2026, Massa P. (FHNW), created
;
; CONTACT:
;   paolo.massa@fhnw.ch
;-

function stx_calibration_data

  struct = { $
    type                       : 'stx_calibration_data', $
    time_start                 : stx_time(), $
    time_end                   : stx_time(), $
    t_mean                     : stx_time(), $
    energy_bin_low             : dblarr(32, 12, 32), $
    energy_bin_high            : dblarr(32, 12, 32), $
    gain                       : fltarr(12, 32), $
    offset                     : fltarr(12, 32), $
    live_time                  : double(0), $
    elut_name                  : '' $
  }
  
  return, struct

end
