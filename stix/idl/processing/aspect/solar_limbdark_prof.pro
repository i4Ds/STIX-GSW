;+
; Description	:
; 	Calculate solar limb darkening function for specified wavelength range.
; 	The limb darkening function uses a 5th order polynomial fitting to the limb darkening constants obtained from Astrophysical Quantities.
;	!! THIS ONLY WORKS IN THE WAVELENGTH RANGE 4000<LAMBDA<15000 ANGSTROMS. !!!
;
;
; Category		: simulation
;
; Syntax		: profile=solar_limbdark_prof(x, sol_rad, lambda, bandpass)
;
; Inputs      	:
; 	x - vector of radial distances in arbitrary units
;	sol_rad - solar radius (in units of x)
;	lambda - center wavelength [Angstroms]
;  	bandpass - wavelength range of bandpass [Angstroms].  The program takes averages the limb darkening coefficients over a wavelength range: lambda +/- bandpass/2
;
; Output:
;	limbprof - normalized limb darkening profile
;
; Keywords    	:	none
;
; Routines called:
;		DARKLIMB_U, DARKLIMB_V
;
; History		:
; 	14-oct-96 - D. Alexander, originally written as DARKLIMB_CORRECT program
; 	13-Oct-2017 - Alexander Warmuth (AIP), converted to function returning limb profile
; 	2021-07-30 - F. Schuller (AIP): added a sanity test on the number of input positions (x)
;-

function solar_limbdark_prof, x, sol_rad, lambda, bandpass

  if n_elements(x) gt 2e5 then begin
    print," *** solar_limbdark_prof *** WARNING! asking for too much data..."
    print," *** solar_limbdark_prof ***  -> truncating x to 2e5 values"
    x = x[0:2e5]
  endif

  ll=1.*lambda         ; make sure lambda is floating point

  ; get constants for limb darkening function
  ; set up limits for integral
  llmax = ll + bandpass/2.
  llmin = ll - bandpass/2.

  ; do spectral averaging over bandpass

  ul = qsimp('darklimb_u',llmin,llmax)/bandpass
  vl = qsimp('darklimb_v',llmin,llmax)/bandpass

dist_grid=x/sol_rad
outside1=where(dist_grid gt 1.,ct1)
outside2=where(dist_grid lt -1.,ct2)
if (ct1 gt 0.) then dist_grid(outside1)=0.                    ; zero all distances outside solar disk
if (ct2 gt 0.) then dist_grid(outside2)=0.                    ; zero all distances outside solar disk

; calculate limb darkening function

limbprof = 1 - ul - vl + ul*cos(asin(dist_grid)) + vl*cos(asin(dist_grid))^2
if (ct1 gt 0.) then limbprof(outside1)=0.
if (ct2 gt 0.) then limbprof(outside2)=0.

return, limbprof
end
