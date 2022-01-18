;+
; Description :
;   Computes and returns the normalised solar intensity profile on a given grid of X values
;   for a given solar image radius.
;   
; Category    : simulation
;
; Syntax      : compute_solar_prof, x, solrad, solprof, powcorr, back=back
;
; Inputs      :
;   x         = positive offsets along axis along which profile is computed
;   solrad    = radius [in m] of the solar image
;
; Outputs     :
;   solprof   = 1D array of normalized solar intensity profile (symmetric profile)
;   powcorr   = power density correction factor in image plane due to limb darkening (??)
;
; Keywords    : 
;   back      = percentage of background intensity (default = 0)
;
; History   :
;   2020-01-08 : F. Schuller (AIP) - Created (break out as a separate function)
;-
pro compute_solar_prof, x, solrad, solprof, powcorr, back=back
  ; define some parameters (optical properties of the SAS lens are needed)
  clv_band = 150.0
  clv_wav = 625.0
  
  ; compute normalized solar intensity profile (for positive x-values), with limb darkening
  solprof = solar_limbdark_prof(x,solrad,clv_wav*1e1,clv_band*1e1)

  ; make symmetric profile
  x2 = [-reverse(x[1:*]),x]
  solprof = [reverse(solprof[1:*]),solprof]
  nx = n_elements(x2)
  
  ; include effect of diffraction on solar intensity profile
  dx = x[1]-x[0]
;  diffprof = stx_sas_airy_beam_profile(dr=dx*imscale*1e6/60.,nrb=round(2./(dx*imscale*1e6/60.)),$
;                                       wav=clv_wav/1e3,diam=diam*1e3)
;;;                                     wav=clv_wav/1e3,diam=diam*1e3 / 2.)
;
;  solprof = convol(solprof,reform(diffprof[1,*]),total(diffprof[1,*]),/edge_trunc,/cent)

  ; and blur the image a little bit
;  solprof = gauss_smooth(solprof, 20, /edge_trunc)
  ; let's be more radical...
  ; prof100 = gauss_smooth(solprof, 100, /edge_trunc)
;  prof1 = gauss_smooth(solprof, 20, /edge_trunc)
;  solprof = gauss_smooth(prof1, 100,/edge_trunc)
  ;;solprof = gauss_smooth(prof200, 100, /edge_trunc)
  ;solprof = gauss_smooth(solprof, 50, /edge_trunc)
  
;  ; add gaussian wings: at 1.2 r_sol, there is still some signal at 0.5% of the peak
;  ; FSc - 2020-10-30
;  gauss_w = 1.2*solrad / sqrt(-2.*alog(5.e-3))
;  gauss_prof = gaussian(x2,[1.,0.,gauss_w])
;  prof_2d = [[solprof],[gauss_prof]]
;  solprof = max(prof_2d,dim=2)
  
  ; 2021-10-08
  ; Or, add a constant plateau starting at 1.45 R_sol
;  plateau = where(abs(x2) le 1.45*solrad)
  low_em = 0.05
;;  solprof[plateau] = low_em + (1.-low_em)*solprof[plateau]
  ;
  ; Or, *add* a Gaussian instead of using the max between "raw" profile and Gaussian profile
  ; But use an even larger width:
  gauss_w = 1.4*solrad / sqrt(-2.*alog(5.e-2))   ; 5% of peak at 1.4 solrad
  gauss_prof = gaussian(x2,[1.,0.,gauss_w])
  raw_solprof = solprof
  solprof = low_em*gauss_prof + (1.-low_em)*raw_solprof
  
  ; blur the profile only now
  solprof = gauss_smooth(solprof, 50, /edge_trunc)

  ; simulate background due to scattered light:
  if keyword_set(back) then begin
    solprof = solprof*(1.-back/100.)
    solprof = solprof+back/100.
  endif

  ; Compute power density correction (in image plane) to account for limb darkening
  tot=0.
  for i = (nx-1.)/2.,nx-1. do tot = tot+solprof(i)*x2(i)*2.*!pi*dx
  powcorr = solrad^2.*!pi/tot

;;stop
  
end
 