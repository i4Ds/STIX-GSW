function stx_random_sample_count_spectrum_get_dist, drm, $
  photon_energy_1d, $
  count_spec = count_spec, $
  atten = atten,  $ ;attenuator state, 0 or 1
  photon_spec, $
  ninterp, $
  seed, $
  nevents, $
 _extra = _extra

default, atten, 0

if ~is_struct( drm ) then drm = stx_build_drm( photon_energy_1d, atten = atten, _extra = _extra )
edge_products,  photon_energy_1d, width = destix, mean = emean

counts_bin = (exist( count_spec ) ? count_spec :  drm.efficiency * photon_spec )  * destix 
cumulative_counts = total( /cum, /double, counts_bin )
integral_counts = cumulative_counts / last_item( cumulative_counts )
x = interpol( emean, integral_counts, dindgen( ninterp + 1 ) / ninterp )
edist = x[ randomu( seed, nevents ) * ninterp ]

return, edist
end

;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       stx_random_sample_count_spectrum
;
; :description:
;    computes the energy loss matrix, pulse height matrix and finally the detector response matrix
;    for a given energy binning; As per definition the counts and photons have the same energy binning,
;    the returned matrices are (n_ebins,n_ebins) arrays
; :params:
;   nevents - number of counts in output distibutions, exact, integer
   
; :keywords:

;    e_atten0 - if present, energy events distribution returned here corresponds to no attenuator 
;    e_atten1 - if present, energy events distribution returned here corresponds to the attenuator
;    energy_range - 2 elements, energy range for counts in keV, default is [4.0, 150.0]
;    nphot_bins - number of energy bins used for photon input to detector response, default is 512
;    seed - used in call to Randomu for Monte Carlo sampling
;    drm0 - detector response matrix structure returned by stx_build_drm for no attenuator, 
;       if passed not recalculated
;    drm1 - detector response matrix structure returned by stx_build_drm with attenuator, 
;       if passed not recalculated
;    ninterp - number of linear intervals used to invert the count rate distribution, more means the
;     the energy sampling of the result is more highly varied, default is 10,000,000L
;    func_name - name of xray spectrum generating function known to SSW, default is 'f_pow'
;    func_param - functional parameters used in call to func_name, default is [1.0, 5.0]
;    photon_spec_str - instead of passing a photon function by name, it could be passed here
;     with two tags { energy1d: fltarr(N+1), spectrum: fltarr(N) }
;     energy1d is the photon energy bins in keV over which spectrum will be interpolated to the bins
;      of the drm 
;    count_spec_str - similar to the photon_spec_str but already integrated over the DRM
;       
;-

pro stx_random_sample_count_spectrum, nevents, $
  e_atten0=e_atten0, e_atten1=e_atten1, $
  energy_range = energy_range, nphot_bins = nphot_bins, $
  seed = seed, $
  drm0 = drm0, $
  drm1 = drm1, $
  ninterp = ninterp, $
  func_name = func_name, $
  func_param = func_param, $
  photon_spec_str = photon_spec_str, $
  count_spec_str= count_spec_str, $
  out_photon_spec = out_photon_spec, $
  _extra = _extra

default, energy_range, [4., 150.]
default, nphot_bins, 512
default, func_name, 'f_pow'
default, func_param, [1., 5.0]
default, ninterp, 10000000L ;10,000,000L
default, no_spec, 1

e1stix = interpol( energy_range >1.001, nphot_bins + 1)
edge_products, e1stix, edges_2 = e2stix, width = destix, mean = emean
have_counts = is_struct( count_spec_str )
if ~is_struct( photon_spec_str ) && ~have_counts then begin
  if func_name eq 'f_vth' then begin
    photon_spec = call_function( func_name, e2stix, func_param, /brem49) 
  endif else begin
    photon_spec = call_function( func_name, e2stix, func_param )
  endelse
  ;photon_spec = f_pow( e2stix, [1.0, pl_index] )
  endif
if have_counts then count_spec = $
  interpol( count_spec_str.spectrum, get_edges( count_spec_str.energy1d, /mean), emean )
if ~have_counts and is_struct( photon_spec_str ) then photon_spec = $
  interpol( photon_spec_str.spectrum, get_edges( photon_spec_str.energy1d, /mean), emean )

with_atten = arg_present( e_atten1 )
no_atten = arg_present( e_atten0 )

if arg_present( e_atten0 ) then e_atten0 = stx_random_sample_count_spectrum_get_dist( drm0, e1stix, $
  atten = 0, $
  count_spec = count_spec, $
  photon_spec, ninterp, seed, nevents, _extra = _extra )

if arg_present( e_atten1 ) then e_atten1 = stx_random_sample_count_spectrum_get_dist( drm1, e1stix, $
  atten = 1, $
  count_spec = count_spec, $
  photon_spec, ninterp, seed, nevents, _extra = _extra )

out_photon_spec = photon_spec

end


;if arg_present( e_atten0 ) then begin
;  if ~is_struct( drm0 ) then drm0 = stx_build_drm( e1stix, atten=0, _extra = _extra )
;  
;  int0 = total(/cum, drm0.efficiency * photon_spec * destix, /double )
;  int0 /= last_item( int0 )
;  x0 = interpol( emean, int0, dindgen( ninterp + 1 ) / ninterp )
;  e_atten0 = x0[  randomu(seed,nevents ) * ninterp ]
;  endif
;
;if arg_present( e_atten1 ) then begin
;  if ~is_struct( drm1 ) then drm1 = stx_build_drm( e1stix, atten=1, _extra = _extra )
;  
;  int1 = total(/cum, drm1.efficiency * photon_spec *destix, /double )
;  int1 /= last_item( int1 )
;  x1 = interpol( emean, int1, dindgen( ninterp + 1 ) / ninterp )
;  e_atten1 = x1[ randomu( seed, nevents ) * ninterp ]
;  endif
;count_energy_samples = ( stx_random_sample_count_spectrum_get_dist, drm, $
;  photon_energy_1d, $
;  atten, $
;  photon_spec, $
;  ninterp, $
;  seed, $
;  nevents, $
; _extra = _extra )

