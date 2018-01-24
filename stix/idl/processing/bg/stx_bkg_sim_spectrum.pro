;+
; :Description:
;    Wrapper routine for building simulated background spectra for STIX pixels including continuum and 
;    source calibration lines. Returns a simulated background count spectrum
;    WP2100 – Simulation model of calibration line spectrum:  Develop a simulation model of the background and 
;    calibration line spectrum at full 4096 channel resolution with parameters
;    flexible enough to accommodate the expected ranges.
;
; :Params:
;    edg2 - output, energy edges in keV, 2xn
;
; :Keywords:
;    per_kev - if set, units are per keV
;    per_sec - if set, units are per sec
;    poisson - if set, return a Poisson deviate using the spectrum's expectation value in counts
;    ichan   - if set, edg2 is in channel number
;    x4      -  if set sum the 4096 bin spectrum into 1024 bins
;    line_factor - scaling factor for radioactive line component, default 1.0
;    bkg_factor  - scaling factor for background component, default 1.0
;    hecht_par  - parameters for hecht tailing parameters, not used yet, 28-jun-2017

;    seed - seed for poisson deviates through poidev
;    _extra
;
; :Author: richard.schwartz@nasa.gov, 21-jul-2016
; 28-jun-2017, 
; :History:
;   29-nov-2017, RAS
;-
function stx_bkg_sim_spectrum, edg2, $
  per_kev = per_kev, $
  per_sec = per_sec, $
  poisson = poisson, $
  ichan   = ichan, $
  x4      = x4, $
  seed    = seed, $
  line_factor = line_factor, $
  continuum_factor = continuum_factor, $
  hecht_par = hecht_par, $
  time_interval = time_interval, $
  spectrogram = spectrogram, $
  _extra = _extra
  
;    stx_bkg_continuum_mdl builds the Grimm parameterization of the Howard model and
;    allows for the introduction of an arbitrary channel energy conversion 
  stx_bkg_continuum_mdl, edg2, continuum, time_interval = time_interval, spectrogram = cont_spectrogram, _extra = _extra
  lines = stx_bkg_lines_mdl( edg2, time_interval = time_interval, $
    hecht_par = hecht_par, spectrogram = line_spectrogram, _extra = _extra) ;counts per bin
  out  = cont_spectrogram.data * continuum_factor + line_spectrogram.data * line_factor
  
  
  edge_products, edg2, width = width
  if keyword_set( poisson ) then out = poidev( out, seed = seed )
  if keyword_set( x4 ) then begin
     nchan = n_elements( out )
     nchan4= nchan / 4
     out = rebin( out[0:nchan4*4-1], nchan4 ) * 4
     edg = get_edges( edg2, /edges_1 )
     edg = [ edg[0:nchan4*4-1:4], edg[nchan4*4] ]
     edge_products, edg, width = width, edges_2 = edg2
      
  endif
  if keyword_set( per_kev) then out /= width
  if keyword_set( per_sec) then out /= 86400.
  if keyword_set( ichan  ) then edg2 = get_edges( findgen( n_elements( width ) + 1 ), /edges_2)
  edg1 = get_edges( edg2, /edges_1 )
  t_axis   = line_spectrogram.t_axis
  e_axis = stx_construct_energy_axis( energy = edg1, $
    select = lindgen( n_elements( edg1 ) ) )
  data = reform( out, n_elements(out), 1 )
  livetime = reform( data*0.0+1., n_elements(out), 1 )
  sp = stx_spectrogram( data, t_axis, e_axis, livetime )
  spectrogram = rep_tag_value( sp, double(sp.data),'data')
  return, out
end