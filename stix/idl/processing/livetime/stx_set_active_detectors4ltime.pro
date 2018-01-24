;+
; :name:
;   stx_set_active_detectors4ltime
; :description:
;   This function takes the active detector mask and sets the corresponding one for livetime
;   such that the ad pair for any detector is disabled, ie. both elements corresponding to
;   an ad pair are set to 0
;
; :categories:
;    event accumulation
;
; :params:
;   active_detectors - 32 bit mask of active detectors, 1 means enabled, 0 means disabled

; :restrictions:
;
; :Useage:
;  IDL> active_detectors = bytarr( 32 ) + 1b& active_detectors[22] = 0
;  IDL> print, stx_set_active_detectors4ltime( active_detectors )
;         1       1       1       1       1       1       1       1       1       1       1       1       1       1       1       1       0       1       1       1
;         1       1       0       1       1       1       1       1       1       1       1       1
;  IDL> print, where( ~stx_set_active_detectors4ltime( active_detectors ) )
;            16          22
;  IDL> active_detectors = bytarr( 32 ) + 1b& active_detectors[0:7] = 0
;  IDL> print, stx_set_active_detectors4ltime( active_detectors )
;         0       0       0       0       0       0       0       0       0       1       0       1       1       1       1       1       1       1       1       1
;         1       1       1       1       1       1       1       1       1       1       1       1
;  IDL> print, where( ~stx_set_active_detectors4ltime( active_detectors ) )
;             0           1           2           3           4           5           6           7           8          10
; :history:
;     18-dec-2014, Richard Schwartz
;-
function stx_set_active_detectors4ltime, active_detectors

  active_detectors_ltime = active_detectors > 0 < 1
  z = where( ~active_detectors_ltime, nz )
  if nz ge 1 then active_detectors_ltime[ stx_ltpair_assignment( z + 1 ) - 1] = 0

  return, active_detectors_ltime
end