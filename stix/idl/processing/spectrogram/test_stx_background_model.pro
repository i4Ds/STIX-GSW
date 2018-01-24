;+
; :Author: richard.schwartz@nasa.gov, 21 apr 2015
;-

;provide an example for the stx_background_model function
;Create a typical background spectrum with random fluctuations on long time intervals
;create the model with poisson variations in the counts
; prepare the stix energy channels, arbitrary in this range

  elim = [4, 150.]
  e = exp( interpol( alog(elim), 33))

  e2 = get_edges(e, /edges_2)
  em = avg( e2, 0)
  c = exp(-xsec( em,  4, 'pe') *.4) ;make a window attenuation profile
  duration =  6 *poidev(fltarr(30) + 10) ;standard background intervals, in seconds
  de = get_edges(/width, e2 )
  ;simulate a background spectrum, non-specific for the purpose here
  brate = rebin( c * (f_pow( e2, [1., 2]) + f_pow( e2, [5., 1.1])) * de, 32, 20 )
  data = poidev( brate * ( fltarr( 32,1)+1 ) # duration )
  sigma = 1. / sqrt( data )
  ;prep flare time intervals
  fduration =  6 *(poidev(fltarr(600) + 0.2 )+.1)
  utf = 200.0d0 + [0.0, total( /cum, fduration ) ]
  utb = [0.0d0, total( /cum, duration ) ]
  stx_energy = stx_construct_energy_axis( energy_edges = get_edges(/edges_1, e2 ))
  fstx_time   = stx_construct_time_axis( utf )
  bstx_time   = stx_construct_time_axis( utb )
  bspectrogram = stx_spectrogram( data,  bstx_time,  stx_energy, data * 0.0+1.0)

  bspectrogram = add_tag( bspectrogram, 22.0, 'area_mm2' )
  ;inputs prepped for conversion to flare intervals
  fbspectrogram = stx_background_model( bspectrogram, flare_time = fstx_time, ndegree = 2 )

end