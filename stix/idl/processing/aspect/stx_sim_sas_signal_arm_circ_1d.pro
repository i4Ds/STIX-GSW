;+
; Description	:
; 	This function returns the sensor nominal response of the STIX aspect system (SAS) from
; 	one arm of circular apertures in the 1D approximation for a given 1D solar intensity profile.
;
; Category		: simulation
;
; Syntax		: stx_sim_sas_signal_arm_circ_1d, xoff, yoff, d_ap, dx, apxtab, apytab, x, solprof
;
; Inputs      	:
;   xoff = solar image X offset from the optical axis [m]
;   yoff = solar image Y offset from the optical axis [m]
;   d_ap = diameters of apertures [m]
;   dx = linear step interval [m]
;   apxtab = X distances [m] of the apertures from the optical axis
;   apytab = Y distances [m] of the apertures from the optical axis
;	x = axis along which integration is performed
;	solprof = 1D array of normalized solar intensity profile
;
; Output      	: sig = signal from aperture (number)
;
; Keywords    	: nointerpol - if set, do not interpolate image intensity profiles
;
; History		:
; 	18-Apr-2018 - Alexander Warmuth (AIP), initial release
; 	2020-01-07, F. Schuller (AIP) : call stx_sim_sas_signal_ap_circ_1d for each aperture to avoid
; 	            duplicating the same piece of code 
;-

FUNCTION stx_sim_sas_signal_arm_circ_1d, xoff, yoff, d_ap, dx, apxtab, apytab, x, solprof, nointerpol=nointerpol

  if not keyword_set(nointerpol) then nointerpol=0
  naps=n_elements(apxtab)
  sig=fltarr(naps)

  ; loop over apertures
  for i=0,naps-1 do begin
    sig(i) = stx_sim_sas_signal_ap_circ_1d(xoff, yoff, d_ap(i), dx, apxtab(i), apytab(i), x, $
                                           solprof, nointerpol=nointerpol)
  endfor

  return,total(sig)

END
