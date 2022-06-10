
; NAME:
;   vis_fwdfit_pso_func_makealoop
;
; PURPOSE:
;   Internal routine used by vis_fwdfit_pso that calculates expected visibilities at specified u,v points for a single curved elliptical gaussian.
;   Single curved elliptical gaussian (loop) is obtained  by a set of equispaced circular gaussians.
;
; INPUTS:
;   flux: loop total flux
;   fwhm1: sqrt(fwhmmajor * fwhmminor)
;   eccen: the eccentricity of the loop
;   x_loc: source x location
;   y_loc: source y location
;   pa: the orientation angle
;   loop_angle: angle centered in the center of the circumference representing the curvature and subtended by the loop
;   u: u coordinates of the sampling frequencies
;   v: v coordinates of the sampling frequencies
;
; OUTPUT: 
;   OBS: expected loop visibilities

FUNCTION vis_fwdfit_pso_func_makealoop, flux, fwhm1, eccen, x_loc, y_loc, pa, loop_angle, u, v

  n_part      = n_elements(fwhm1)  ; number of birds 
  n_vis       = n_elements(u)      ; number of visibilities
  
  ncirc0      = 21     ; Upper limit to number of ~equispaced circles that will be used to approximate loop.
  PLUSMINUS   = [-1,1]
  SIG2FWHM    = SQRT(8 * ALOG(2.))
  
  ; Calculate the relative strengths of the sources to reproduce a gaussian and their collective stddev.
  iseq0       = INDGEN(ncirc0)
  relflux0    = FLTARR(ncirc0)
  relflux0    = FACTORIAL(ncirc0-1) / (FLOAT(FACTORIAL(iseq0)*FACTORIAL(ncirc0-1-iseq0))) / 2.^(ncirc0-1) ; TOTAL(relflux)=1
  ok          = WHERE(relflux0 GT 0.01, ncirc)      ; Just keep circles that contain at least 1% of flux
  relflux     = relflux0[ok] / TOTAL(relflux0[ok])
  iseq        = INDGEN(ncirc)
  reltheta    = (iseq/(ncirc-1.) - 0.5)             ; locations of circles for arclength=1
  factor      = SQRT(TOTAL(reltheta^2 *relflux)) * SIG2FWHM   ; FWHM of binomial distribution for arclength=1
  
  loopangle  = loop_angle* !DTOR / factor
  IF total(ABS(loopangle) GT 1.99*!PI) THEN MESSAGE, 'Internal parameterization error - Loop arc exceeds 2pi.'
  
  ind=WHERE(loopangle EQ 0, iind)
  if iind gt 0 then loopangle[ind] = 0.01                     ; radians. Avoids problems if loopangle = 0
  
  theta       = ABS(loopangle) # (iseq/(ncirc-1.) - 0.5)      ; equispaced between +- loopangle/2
  xloop       = SIN(theta)                                    ; for unit radius of curvature, R
  yloop       = COS(theta)                                    ; relaive to center of curvature
  ind=WHERE(loopangle LT 0, iind)
  if iind gt 0 then yloop[ind,*] = -yloop[ind,*]              ; Sign of loopangle determines sense of loop curvature
  
  ; Determine the size and location of the equivalent separated components in a coord system where...
  ; x is an axis parallel to the line joining the footpoints
  ; Note that there are combinations of loop angle, sigminor and sigmajor that cannot occur with radius>1arcsec.
  ; In such a case circle radius is set to 1.  Such cases will lead to bad solutions and be flagged as such at the end.
  
  sigminor    = fwhm1* (1-eccen^2)^0.25 / SIG2FWHM
  sigmajor    = fwhm1/ (1-eccen^2)^0.25 / SIG2FWHM
  fsumx2      = xloop^2 # relflux            ; scale-free factors describing loop moments for endpoint separation=1
  fsumy       = yloop # relflux
  fsumy2      = yloop^2 # relflux
  loopradius  = SQRT((sigmajor^2 - sigminor ^2) / (fsumx2  - fsumy2  + fsumy^2))
  term        = (sigmajor^2 - loopradius^2 *fsumx2) > 0    ; >0 condition avoids problems in next step.
  circfwhm    = SIG2FWHM * SQRT(term) > 1                  ; Set minimum to avoid display problems
  sep         = 2.*loopradius * ABS(SIN(theta[*,0]))
  cgshift     = loopradius * fsumy
  
  ; Calculate source structures for each circle.
  pasep     = pa*!DTOR                        ; position angle of line joining arc endpoints
  
  relx      = fltarr(n_part, ncirc)           ; x is axis joining 'footpoints'
  rely      = fltarr(n_part, ncirc)           ; will enable emission centroid location to be unchanged
  x_loc_new = fltarr(n_part, ncirc)
  y_loc_new = fltarr(n_part, ncirc)
  
  for j=0,n_part-1 do begin
    relx[j,*]        = xloop[j,*] * loopradius[j]
    rely[j,*]        = yloop[j,*] * loopradius[j]  - cgshift[j]
    x_loc_new[j,*]   = x_loc[j] - relx[j,*] * SIN(pasep[j]) + rely[j,*] * COS(pasep[j])
    y_loc_new[j,*]   = y_loc[j] + relx[j,*] * COS(pasep[j]) + rely[j,*] * SIN(pasep[j])
  endfor
  
  obs      = fltarr(2*n_vis, n_part)
  flux_new = flux # relflux               ; Split the flux between components.
  
  arg      = -!pi^2 *  circfwhm^2. / (4. * alog(2.)) # (u^2 + v^2)
  relvis   = EXP(arg)
  
  re_obs = fltarr(n_part, n_vis)
  im_obs = fltarr(n_part, n_vis)
  ones   = fltarr(1, n_vis) + 1.
  
  for j=0, ncirc-1 do begin
    phase           = 2.*!pi * (x_loc_new[*,j] # u  + y_loc_new[*,j] # v)
    fflux           = flux_new[*,j] #ones
    re_obs          += fflux * relvis * COS(phase)    ; Each component is added to previous sum
    im_obs          += fflux * relvis * SIN(phase)
  endfor
  
  obs = [[re_obs], [im_obs]]
  
  RETURN, obs

END 
