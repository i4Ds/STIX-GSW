;+
;
; NAME:
;
;   stx_calibrated_pixel_data
;
; PURPOSE:
;
;   Defines a calibrated pixel data structure
;
; CALLING SEQUENCE:
;
;   pixel_data = stx_calibrated_pixel_data()
;
; OUTPUTS:
;
;   'stx_calibrated_pixel_data' structure
;
;
; HISTORY: July 2022, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-


function stx_calibrated_pixel_data

  return, { $
    type                  : 'stx_calibrated_pixel_data', $
    live_time             : fltarr(32), $               ; Live time of the 32 detectors
    time_range            : replicate(stx_time(),2), $  ; Selected time range
    energy_range          : fltarr(2), $                ; Selected energy range
    count_rates           : dblarr(32,4), $             ; Count rates recorded by the sub-collimators (units: counts * s^-1 * cm^-2 * keV^-1)
                                                        ; Corrected for internal shadowing. Pixels are summed
    counts_rates_error    : dblarr(32,4), $             ; Errors associated with the measured counts rates (statistics + compression)
    tot_counts            : double(0), $                ; Total number of counts recorded during the event
    live_time_bkg         : fltarr(32), $               ; Live time of the 32 detectors during the background measurement
    count_rates_bkg       : dblarr(32,4), $             ; Counts rates recored by the the sub-collimators (summed in time and energy) during the
                                                        ; background measurement
    count_rates_error_bkg : dblarr(32,4), $             ; Errors associated with the measured background counts (statistics + compression)
    tot_counts_bkg        : double(1), $                ; Total number of bakground counts
    rcr                   : byte(0), $                  ; Rate Control Regime (RCR) status
    xy_flare              : fltarr(2), $                ; Estimate of the flare location used for grids' internal swadowing correction
    sumcase               : string(""), $               ; Which pixels are summed: 'TOP' (top row), 'BOT' (bottom row), 'SMALL' (small pixels)
                                                        ;                          'TOP+BOT' (top and bottom row), 'ALL', (all pixels)
    detector_masks        : bytarr(32) $                ; array containing information on the detectors used for the measurement
  }
end