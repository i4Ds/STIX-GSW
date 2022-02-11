;+
; Description	:
; 	This function returns the sensor nominal response of the STIX aspect system (SAS) from one circular aperture in the 1D approximation for a given 1D solar intensity profile.
;
; Category		: simulation
;
; Syntax		: stx_sim_sas_signal_ap_circ_1d, xoff, yoff, d_ap, dx, apxtab, apytab, x, solprof
;
; Inputs      	:
;   xoff = solar image X offset from the optical axis [m]
;   yoff = solar image Y offset from the optical axis [m]
;   d_ap = diameter of aperture [m]
;   dx = linear step interval [m]
;   apxtab = X distance [m] of the aperture from the optical axis
;   apytab = Y distance [m] of the aperture from the optical axis
;	x = axis along which integration is performed
;	solprof = 1D array of normalized solar intensity profile
;
; Output      	: sig = signal from aperture (number)
;
; Keywords    	: nointerpol - if set, do not interpolate image intensity profiles
;
; History		:
; 	18-Apr-2018 - Alexander Warmuth (AIP), initial release
; 	2020-01-10, F. Schuller (AIP) : replaced "round" with "fix" to compute nb. of points
; 	
;-

FUNCTION stx_sim_sas_signal_ap_circ_1d, xoff, yoff, d_ap, dx, apxtab, apytab, x, solprof, nointerpol=nointerpol

sig=0.
nap=fix(d_ap/dx)+1
xx=findgen(nap)*dx-d_ap/2.+sqrt((apxtab-xoff)^2.+(apytab-yoff)^2.)
yy=sqrt((d_ap/2.)^2.-(findgen(nap)*dx-d_ap/2.)^2.)
prof=dblarr(nap)
roff_tmp=xx(0)-round(xx(0)/dx)*dx
if keyword_set(nointerpol) then $
  solprof_tmp=solprof else $
  solprof_tmp=interpol(solprof,x-roff_tmp,x)
xx_tmp=round((xx-roff_tmp)/dx)*dx
posind=where(xx_tmp ge 0.,ct)

if (ct gt 0) then begin
	xx_tmp_pos=(xx_tmp(posind))
	mnind=where((min(xx_tmp_pos) le x+dx/2.) and (min(xx_tmp_pos) ge x-dx/2.),ct1)
	mxind=where((max(xx_tmp_pos) le x+dx/2.) and (max(xx_tmp_pos) ge x-dx/2.),ct2)
	if ((ct1 ge 1) and (ct2 ge 1)) then $
     sig=sig+total(yy(posind)*2.*dx*solprof_tmp(mnind:mxind))
endif

negind=where(xx_tmp lt 0.,ct)
if (ct gt 0) then begin
	xx_tmp_neg=abs(xx_tmp(negind))
	mnind=where((min(xx_tmp_neg) le x+dx/2.) and (min(xx_tmp_neg) ge x-dx/2.),ct1)
	mxind=where((max(xx_tmp_neg) le x+dx/2.) and (max(xx_tmp_neg) ge x-dx/2.),ct2)
	if ((ct1 ge 1) and (ct2 ge 1)) then $
	  sig=sig+total(yy(reverse(negind))*2.*dx*solprof_tmp(mnind:mxind))
endif

return,sig

END
