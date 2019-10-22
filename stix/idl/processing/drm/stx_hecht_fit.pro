;+
; :description:
;    This function returns a calibration line spectrum including the effects of incomplete charge
;    collection due to radiation damage
;
; :categories:
;    calibration, fitting
;
; :params:
;    e : in, required, type="float array"
;             Input Energy bins in keV
;
;    p : in, required, type="float array"
;             A set of parameters describing the spectrum
;             p[0] : mean free path for holes in cm
;             p[1] : mean free path for electrons in cm
;             p[2] : scaling factor
;  :Keywords:
;     e0 : default is 81 keV, peform for e0 if set
;     sigma: Gaussian line sigma, default is stx_fwhm() for e0
;     mfp_divisor: default is 1, increase for more trapping by reducing e and h mean free paths
;
; :returns:
;    returns the calibration line spectrum for the input energy vector.
;
; :examples:
;     spectrum = stx_hecht_fit( findgen(100)*0.5+60., [0.36,24.,10000.])
;
; :history:
;    14-Jun-2017 - ECMD (Graz), initial release
;
;-
function stx_hecht_fit, e, p, e0 = e0, sigma = sigma, mfp_divisor = mfp_divisor, etest = etest

  default, depth, 0.1 ; detector depth in cm
  default, n_layers, 500l ;  number of layers to use in calculation
  default, include_damage, 0 ;  if true include a damage layer of reduced charge collecting efficiency, by default the damage layer is not included
  default, depth_damage_layer, 15 ; depth of damage layer in micrometres
  default, e0, 81.;energy of the calibration line
  default, mfp_divisor, 1.0 ;no decrease in mean free paths, increase for more trapping
  x = 1e4*depth*findgen(n_layers)/n_layers
  
  trap_length_h = p[0]*1e4 >0. ; mean free path for holes in micrometres, should always be greater than 0
  trap_length_e = p[1]*1e4 >0. ; mean free path for electrons in micrometres, should always be greater than 0
  if mfp_divisor ne 1.0 then begin ;increase tailing by increasing trapping by decreasing mfps
    trap_length_h /= mfp_divisor
    trap_length_e /= mfp_divisor 
  endif
  d = depth*1e4
  
  ;use the hecht equation to estimate the charge collecting efficiency
  h = (trap_length_h*(1.-exp(-x/trap_length_h)) + trap_length_e*(1.- exp(-(d-x)/trap_length_e)))/d
  
  if include_damage then begin
    ;as efficiency changed rapidly in the damage layer a large number of finer
    ;layers are used
    n_damage = 100l
    
    depth_damage_layer = 15.
    tm = depth_damage_layer/2.; the mean depth of the damage layer
    
    a = 1; parameter representing the speed of the drop off
    
    idx_damage_layer = where(x lt depth_damage_layer,  complement = comp)
    t = depth_damage_layer*findgen(n_damage)/n_damage
    
    ;the sharp drop off in efficiency in the damage layer is modelled
    ;using a complementary error function
    damage_layer_efficiency = 0.5 * erfc((t - tm)*a/depth_damage_layer)
    
    x = [t, x[comp]]
    h[0:n_damage-1] = h[0:n_damage-1]*reverse(damage_layer_efficiency)
    
  endif
  
  energy = e
  
  ;sigma for energy resolution is determined using standard stx_fwhm function at the energy of the calibration line
  sigma = keyword_set( sigma ) ? sigma : stx_fwhm(e0)/(2.*sqrt(2.*alog(2.)))
  
  s_pe  = det_xsec( e0, det = 'cdte', TYP='PE', error = error )  ;photoelectric xsec in 1/cm
  
  s_pe /= 1d4  ; convert to 1/micrometres
  
  ;probability of interaction in a given slice is calculated as
  ;P(interaction hasn’t occurred by depth x)*P(interaction will occur in slice of with dx)
  pi = exp(-s_pe*x)*(1.- exp(-s_pe*d/n_elements(x)))
  
  fe = fltarr(n_elements(energy))
  
  ;for each energy convolve probability of interaction for each slice with
  ;gaussian representing noise
  ;etest is line energy in the current calibration being fitted.
  ;it may be slightly different from E0 which may be the actual calibration
  ;line energy. E0 and Etest should only be different in the calibration scenario
  default, etest, e0
  
  for j=0,n_elements(energy)-1 do begin
    fe[j] = total(pi*exp(-(energy[j] - h*etest)^2./sigma^2.))
  endfor
  
  ;return the scaled spectrum
  return, p[2]*fe 
end
