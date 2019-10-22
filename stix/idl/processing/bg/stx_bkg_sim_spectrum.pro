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
;    doffset_gain - structure where doffset_gain.gain and doffset_gain.offset_kev
;    are added to the gain and offset used to define the return edges, edg2
;    seed - seed for poisson deviates through poidev
;    _extra
;
; :Author: richard.schwartz@nasa.gov, 21-jul-2016
; 28-jun-2017, 
; :History:
;   29-nov-2017, RAS
;   03-may-2018, RAS, rschwartz70@gmail.com  Minor refactoring
;   04-may-2018, RAS, specify doffset_gain.offset_kev not .offset to emphasize how
;    offset is being used here. This is the RHESSI software meaning of offset
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
  ch_axis = ch_axis, $
  doffset_gain = doffset_gain, $ 
  dout = dout, $
  _extra = _extra
  
;    stx_bkg_continuum_mdl builds the Grimm parameterization of the Howard model and
;    allows for the introduction of an arbitrary channel energy conversion 
  default, continuum_factor, 1.0
  default, line_factor, 1.0
  stx_bkg_continuum_mdl, edg2, continuum, time_interval = time_interval, spectrogram = cont_spectrogram,$
     _extra = _extra
  lines = stx_bkg_lines_mdl( edg2, time_interval = time_interval, $
    hecht_par = hecht_par, spectrogram = line_spectrogram, _extra = _extra) ;counts per bin
  out  = float( cont_spectrogram.data * continuum_factor + line_spectrogram.data * line_factor)
  
  
  edge_products, edg2, width = width, edges_1 = edg1
  ; doffset_gain if set, shift spectrum. Channels have keV edge defined by 
  ; doffset_gain.gain * chan_num + doffset_gain.offset
  if is_struct( doffset_gain ) then begin
    ;doffset_gain is delta gain and delta offset from the values of edg2
    edg_gain = avg( width)
    
    dedg1 = findgen( n_elements( edg1 ) ) * (edg_gain + doffset_gain.gain) + $
      edg1[0] + doffset_gain.offset_kev ;true edges of simulated spectrum
    ssw_rebinner, out, edg1, dout, dedg1
    out = dout
  endif
  
  
  
  if keyword_set( poisson ) then begin
    out = poidev( out, seed = seed )
    
  endif
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
  ch_axis = stx_construct_energy_axis( energy = lindgen( n_elements( edg1 )-1), $
    select = lindgen( n_elements( edg1 )-1 ) )
  data = reform( out, n_elements(out), 1 )
  ;stx_spectrogram is to be modified to allow normal direct input, tbd simplify later
  livetime = reform( data*0.0+ t_axis.duration[0], n_elements(out), 1 )
  sp = stx_spectrogram( data, t_axis, e_axis, livetime )
  spectrogram = rep_tag_value( sp, double(sp.data),'data')
  return, out
end