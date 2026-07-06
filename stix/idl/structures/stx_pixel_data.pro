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
;          April 2025, Massa P., made it compatible with new ELUT correction. Bkg-subtraction is applied to the counts.
;                      Therefore, information on bkg is not stored anymore
;          February 2026, Massa P., Removed 'xy_flare' keyword as grid transmission correction is not applied anymore to raw counts
;          March 2026, Massa P., updated to make it compatible with new ELUT correction.
;
; CONTACT:
;   paolo.massa@fhnw.ch
;-


function stx_pixel_data
  return, { $
    type                  : 'stx_pixel_data', $
    live_time             : fltarr(32), $               ; Live time of the 32 detectors
    live_time_error       : fltarr(32), $               ; Live time error of the 32 detectors
    time_range            : replicate(stx_time(),2), $  ; Selected time range (edges) 
    energy_range          : fltarr(2), $                ; Selected energy range (edges)
    counts                : dblarr(32,12), $            ; Counts recorded by the detector pixels (summed in time and energy)
    counts_error          : dblarr(32,12), $            ; Errors associated with the measured counts (statistics + compression)
    tot_counts            : double(0), $                ; Estimate of the total number of flare counts recorded during the flaring event
    tot_counts_bkg        : double(0), $                ; Estimate of the total number of background counts recorded during the flaring event
    rcr                   : byte(0), $                  ; Rate Control Regime (RCR) status
    pixel_masks           : bytarr(12), $               ; Matrix containing information on the pixels used for the measurement
    detector_masks        : bytarr(32) $                ; Matrix containing information on the detectors used for the measurement
  }
end