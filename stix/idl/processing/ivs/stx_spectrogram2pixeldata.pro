function stx_spectrogram2pixeldata
  spg = stx_datafetch_rhessi2stix('2002/02/12 ' + ['21:30:00', '21:42:00'],600000,6000,[4,10],histerese=0.6,/plot, local_path=local_path)
  
  taxis = spg.t_axis.time;
  eaxis = spg.e_axis.mean;
  
  n_t = N_ELEMENTS(taxis);
  n_e = N_ELEMENTS(eaxis);
  
  data = MAKE_ARRAY(n_t,n_e,32,12,/DOUBLE)
  
  for t = 0L, n_t-1 do begin
    for e = 0L, n_e-1 do begin
      pixel = RANDOMU(200,32,12,/DOUBLE)
      pixel = pixel / total(pixel) * spg.data[t,e]
      data[t,e,*,*] = pixel 
    endfor
  endfor
    
  return, stx_pixel_data(DATA=data,TAXIS=taxis,EAXIS=eaxis)
end