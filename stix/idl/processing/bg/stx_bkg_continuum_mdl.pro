
;+
; :Description:
;    stx_bkg_continuum_mdl returns a background spectrum on 0.1 keV, Oliver Grimm's
;    parameterization of the Howard on-station continuum mostly from diffuse sky cosmic
;    propagating through the spacecraft. Needs validation once we are in space.
;    bins from 0 - 150 keV, also builds this model on a nominal energy binning
;    in
;
; :Params:
;    chanum2 - output, channel centers, uniform bins, 0.1 keV wide
;
; :Keywords:
;    grimm_howard_par - low count rate continuum plus Oliver Grimm bkg from diffuse sky
;     default - [9460., -3.5e-3, -3.8e6, -1.067e-2, -1.3, 4e5, -4e4, -1.8, 201, 700.]
;     see code for meaning, not meant to be changed dynamicallly
;    offset - default of channel 700.0 of 4096 for Howard model
;    spectrogram - output as a stx_spectrogram structure
;     with the data tag as a double
;
; :Author: richard.schwartz@nasa.gov
; 20-jul-2016, name change
; 28-jun-2017, added stx_spectrogram output keyword
; 29-nov-2017, RAS, added erange with default [4,160.] keV
; 03-may-2018, RAS, ensure the channels selected start and end on 4 channel sum boundaries
;-
pro stx_bkg_continuum_mdl, edg2, out, grimm_howard_par = grimm_howard_par, $
  offset = offset, $
  time_interval = time_interval, $
  spectrogram = spectrogram, $
    erange = erange

  default, time_interval, ['1-jan-2019','2-jan-2019']
  default, grimm_howard_par, [9460., -3.5e-3, -3.8e6, -1.067e-2, -1.3, 4e5, -4e4, -1.8, 201, 700.]
  offset = grimm_howard_par[-1] ;offset is tied to grimm_howard_par
  default, per_kev, 0
  default, erange, [4.0, 160.0] ;in keV
  default, def_gain, 0.10  ;default gain or 0.10 keV per bin
  chanum = 1 + findgen(4096)
  edge_products, chanum, edges_2 = chanum2, mean = mean_chanum ;the Howard model is in channel number
  abcd = grimm_howard_par[0:3] ; [9460., -3.5e-3, -3.8e6, -1.067e-2]
  out = abcd[0] * exp( abcd[1] * mean_chanum ) + abcd[2] * exp( abcd[3] * mean_chanum ) > 0.0
  pm  = grimm_howard_par[ 4:8 ]
  out += mean_chanum^(pm[0])* pm[1] * exp(pm[2]*mean_chanum^pm[3])
  mean_chanum = mean_chanum - offset
  chanum2 -= offset
  out = smooth( out, pm[4] )
  z  = where_within( reform( chanum2[0,*] ), erange / def_gain) ;nominally 4-160 keV
  z4_0 = ((z[0]-1) / 4) * 4 
  z  = z4_0 + lindgen( n_elements(z)/4 * 4 ) ;build a range on 4 channel groups
  ;as we only read out the sum of 4 bins for a max 1024 channel readout

  edg2= chanum2[*,z] / 10.0
  edg1_nom = get_edges( /edges_1, edg2 )

  out = out[z] ;counts/day for large pixel
;  This simulation has to be on the specified channels because the
;  readout configuration depends on this binning. The simulation can be offset
;  as needed later
  edg1 = get_edges( /edges_1, edg2 )
  if keyword_set( per_kev ) then out /= (edg2[1,3]-edg2[0,3])
  if keyword_set( per_sec ) then out /= 86400.0
  time_axis = stx_construct_time_axis( time_interval)
  energy_axis = stx_construct_energy_axis( energy = edg1, $
    sele = lindgen( n_elements( edg1 ) ) )
  data = reform( out, n_elements(out), 1 )  
  livetime = reform( data*0.0+1., n_elements(out), 1 )  
  sp = stx_spectrogram( data, time_axis, energy_axis, livetime )  
  spectrogram = rep_tag_value( sp, double(sp.data),'data')
  
end
