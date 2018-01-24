;+
; :DESCRIPTION:
;    stx_attenuator_filter is a Monte-Carlo function that returns a 1 for photons with ENERGY (keV) stopped by
;    the attenuator with thickness D (mm). The outcomes are a
;    random (Randomu) selection from a probability distribution. Aluminum total absorption cross-section
;    obtained from xsec.pro
;
;    IDL> print, stx_attenuator_filter( [5.+fltarr(20),10.+fltarr(20)],.05 )
;    1       1       1       1       1       1       1       1       1       1       1       1       0       1       0       1
;    1       1       1       1       0       0       0       0       0       0       0       0       0       0       0       0
;    0       0       0       0       1       0       0       0
;
; :PARAMS:
;    energy - 1d float array of incident photon energies in units of keV
;    d      - float scalar. attenuator thickness in mm
;
; :KEYWORDS:
;    seed  - optional Seed parameter for Randomu function
;
; :AUTHOR: richard.schwartz@nasa.gov, 5-aug-2016
;-
function stx_attenuator_filter, energy, d, seed=seed

  ;d in mm
  default,d, 1.0
  p = exp( -xsec( energy, 13, 'ab') * d/10.)
  pass = randomu( seed, n_elements(p) ) le p
  return, 1 - pass
end
