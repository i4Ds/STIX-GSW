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

;-
function stx_visibility_old
  ; temporary names stx_visibility
  struct = { $
    type: 'stx_visibility', $
    isc : 0, $
    label: '', $
    live_time: 0, $
    energy_range: fltarr(2), $ ; erange
    time_range : replicate(stx_time(),2), $ ; trange
    obsvis : complex(0), $
    totflux : 0.0, $
    sigamp : 0.0, $
    chi2: 0.0, $
    u : 0.0, $
    v : 0.0, $
    phase_sense : 0, $
    xyoffset : [0.0,0.0], $
    calibrated : 0b $
    }
return, struct
; Version 0-1 definition    
;     void = { stx_visibility, $
;    isc : 0, $
;    erange : fltarr(2), $
;    trange : dblarr(2), $
;    obsvis : dcomplex(0), $
;    totflux : 0.0d0, $
;    sigamp : 0.0d0, $
;    u : 0.0d0d0, $
;    v : 0.0d0, $
;    phase : 0, $
;    xyoffset : [0.0d0,0.0d0] $
;    }

end