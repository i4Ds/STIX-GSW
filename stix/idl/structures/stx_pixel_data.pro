;+
;
; NAME:
;
;   stx_pixel_data
;
; PURPOSE:
;
;   Defines a pixel data structure
;
; CALLING SEQUENCE:
;
;   pixel_data = stx_pixel_data()
;
; OUTPUTS:
;
;   'stx_pixel_data' structure (see the header of 'stx_construct_pixel_data' for more details)
;
;
; HISTORY: July 2022, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-


function stx_pixel_data
  return, { $
    type                  : 'stx_pixel_data', $
    live_time             : fltarr(32), $               ; Live time of the 32 detectors
    time_range            : replicate(stx_time(),2), $  ; Selected time range (edges) 
    energy_range          : fltarr(2), $                ; Selected energy range (edges)
    counts                : dblarr(32,12), $            ; Counts recorded by the detector pixels (summed in time and energy)
    counts_error          : dblarr(32,12), $            ; Errors associated with the measured counts (statistics + compression) 
    live_time_bkg         : fltarr(32), $               ; Live time of the 32 detectors during the background measurement
    counts_bkg            : dblarr(32,12), $            ; Counts recorded by the detector pixels during the background measurement (summed in time and energy)
    counts_error_bkg      : dblarr(32,12), $            ; Errors associated with the measured background counts (statistics + compression) 
    xy_flare              : fltarr(2),  $               ; Estimate of the flare location used for grids' transmission correction
    rcr                   : byte(0), $                  ; Rate Control Regime (RCR) status
    pixel_masks           : bytarr(12), $               ; Matrix containing information on the pixels used for the measurement
    detector_masks        : bytarr(32) $                ; Matrix containing information on the detectors used for the measurement
  }
end