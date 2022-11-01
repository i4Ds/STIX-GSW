;+
; :name:
;   STX_Visibility
; :description:
;   This is the definition function for the stx_visibility structure. 
;
; :categories:
;    visibility calculation
;
; :params:

; :restrictions:
;     This is the new definition for Version 2
;
; :history:
;     29-apr-2013, Richard Schwartz, extracted from stx_visgen, 
;     23-jul-2013, Richard Schwartz, no versioning, just one stx_visibility that may evolve
;     20-aug-2022, Paolo Massa, modified for including 'tot_counts', 'tot_counts_bkg' and 'xy_flare'. 
;                  'chi2' removed
;
;-
function stx_visibility
  struct = { $
    type: 'stx_visibility', $
    isc : 0, $                              ; Subcollimator index (from 1 to 32)
    label: '', $                            ; Subcollimator label
    live_time: 0., $                        ; Detector live time
    energy_range: fltarr(2), $ ; erange     ; Selected energy range (edges)
    time_range : replicate(stx_time(),2), $ ; Selected time range (edges)
    obsvis : complex(0), $                  ; Complex visibility values. Visibility amplitudes (A) and phases (\phi) can be retrieved as 
                                            ; follows: A = abs(obsvis), \phi = atan(imaginary(obsvis), real_part(obsvis)) * !radeg (to have phase in degrees)
    
    tot_counts: 0.0, $                      ; Total number of counts measured in the selected time and energy intervals
    tot_counts_bkg: 0.0, $                  ; Estimate of the total number of background counts measured in the selected time and energy intervals
    totflux : 0.0, $                        ; Total flux estimate: A+B+C+D
    sigamp : 0.0, $                         ; Error on the visibility amplitudes. Error in the phases (in deg) is sigphase = sigamp/A * !radeg,
                                            ; where A are the visibility amplitude values
    
    u : 0.0, $                              ; U coordinates of the frequencies sampled by the subcollimators
    v : 0.0, $                              ; V coordinates of the frequencies sampled by the subcollimators
    phase_sense : 0, $                      ; Subcollimator phase sense (-1 or 1)
    xyoffset: fltarr(2), $                  ; Coordinates (arcsec, STIX coordinate frame) of the center of the map that is reconstructed 
                                            ; from the visibility values. Used in the phase calibration
    
    xy_flare : fltarr(2), $                 ; Coordinates (arcsec, STIX coordinate frame) of the estimated flare location. 
                                            ; Used for grid transmission correction and projection correction in the visibility phases
    
    calibrated : 0b $                       ; 1 if the visibility amplitude and phases are calibrated, 0 otherwise
    }
return, struct

end