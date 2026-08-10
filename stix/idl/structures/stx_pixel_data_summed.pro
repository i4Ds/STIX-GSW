;+
;
; NAME:
;
;   stx_pixel_data_summed
;
; PURPOSE:
;
;   Defines a summed pixel data structure
;
; CALLING SEQUENCE:
;
;   pixel_data_summed = stx_pixel_data_summed()
;
; OUTPUTS:
;
;   'stx_pixel_data_summed' structure
;
;
; HISTORY: July 2022, Massa P., created
;          January 2026, Massa P., removed 'xy_flare' entry as grid transmission correction is not applied anymore to the raw counts
;          March 2026, Massa P., made it compatible with new ELUT correction
;
; CONTACT:
;   paolo.massa@fhnw.ch
;-


function stx_pixel_data_summed

  return, { $
    type                  : 'stx_pixel_data_summed', $
    live_time             : fltarr(32), $               ; Live time of the 32 detectors
    time_range            : replicate(stx_time(),2), $  ; Selected time range
    energy_range          : fltarr(2), $                ; Selected energy range
    count_rates           : dblarr(32,4), $             ; Count rates recorded by the sub-collimators (units: counts * s^-1 * cm^-2 * keV^-1)
                                                        ; Optionally, for internal shadowing. Pixels are summed
    counts_rates_error    : dblarr(32,4), $             ; Errors associated with the measured counts rates (statistics + compression, 
                                                        ; no systematic errors are included)
    tot_counts            : double(0), $                ; Total number of counts recorded during the event
    tot_counts_bkg        : double(0), $                ; Estimate of the total number of background counts recorded during the flaring event
    rcr                   : byte(0), $                  ; Rate Control Regime (RCR) status
    sumcase               : string(""), $               ; Which pixels are summed: 'TOP' (top row), 'BOT' (bottom row), 'SMALL' (small pixels)
                                                        ; 'TOP+BOT' (top and bottom row), 'ALL', (all pixels)
    detector_masks        : bytarr(32) $                ; array containing information on the detectors used for the measurement 
                                                        ; (1 if the detector is used, 0 otherwise)
  }
end