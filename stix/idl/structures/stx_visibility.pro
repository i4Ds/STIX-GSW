;+
; :name:
;   STX_Visibility
; :description:
;   This is the definition function for the stx_visibility structure
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
    isc : 0, $
    label: '', $
    live_time: 0., $
    energy_range: fltarr(2), $ ; erange
    time_range : replicate(stx_time(),2), $ ; trange
    obsvis : complex(0), $
    tot_counts: 0.0, $
    tot_counts_bkg: 0.0, $
    totflux : 0.0, $
    sigamp : 0.0, $
    u : 0.0, $
    v : 0.0, $
    phase_sense : 0, $
    xyoffset: fltarr(2), $
    xy_flare : fltarr(2), $
    calibrated : 0b $
    }
return, struct

end