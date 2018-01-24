function stx_detector_plotter::init, win, _EXTRA=ex
  
  if ~isa(win, 'IDLGRWINDOW') then win = window(window_title="STX Detector Plotter")
  
  n_det = 32
  
  self.detectors = make_array(n_det, /obj)
  
  p = 2
  
  MARGIN=[0.005, 0., 0.0, 0.01]
  
  ;pl = plot([100,200], xrange=[0,11], yrange=[-1,4],/nodata, /xstyle, /ystyle)
    
  self.detectors[10] = stx_graphic_detector(name='1a', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[11] = stx_graphic_detector(name='2a', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[ 6] = stx_graphic_detector(name='3a', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[24] = stx_graphic_detector(name='4a', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[ 5] = stx_graphic_detector(name='5a', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[14] = stx_graphic_detector(name='6a', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[23] = stx_graphic_detector(name='7a', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[20] = stx_graphic_detector(name='8a', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[15] = stx_graphic_detector(name='9a', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[ 2] = stx_graphic_detector(name='10a', current=win, layout =[11,3,p++], margin=MARGIN)
  
  self.detectors[ 9] = stx_graphic_detector(name='bkg', current=win, layout =[11,3,p++], margin=MARGIN)
  
  self.detectors[12] = stx_graphic_detector(name='1b', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[18] = stx_graphic_detector(name='2b', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[28] = stx_graphic_detector(name='3b', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[ 4] = stx_graphic_detector(name='4b', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[29] = stx_graphic_detector(name='5b', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[26] = stx_graphic_detector(name='6b', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[ 7] = stx_graphic_detector(name='7b', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[25] = stx_graphic_detector(name='8b', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[13] = stx_graphic_detector(name='9b', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[19] = stx_graphic_detector(name='10b', current=win, layout =[11,3,p++], margin=MARGIN)
  
  self.detectors[ 8] = stx_graphic_detector(name='cfl', current=win, layout =[11,3,p++], margin=MARGIN)
  
  self.detectors[17] = stx_graphic_detector(name='1c', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[16] = stx_graphic_detector(name='2c', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[ 0] = stx_graphic_detector(name='3c', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[22] = stx_graphic_detector(name='4c', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[ 1] = stx_graphic_detector(name='5c', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[30] = stx_graphic_detector(name='6c', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[27] = stx_graphic_detector(name='7c', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[ 3] = stx_graphic_detector(name='8c', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[31] = stx_graphic_detector(name='9c', current=win, layout = [11,3,p++], margin=MARGIN)
  self.detectors[21] = stx_graphic_detector(name='10c', current=win, layout =[11,3,p++], margin=MARGIN)
  
  return, 1b
end

pro stx_detector_plotter::setData, pixel_data, dscale=dscale, showsin=showsin
  
  default, showsin, 0
   
  if keyword_set(dscale) && n_elements(dscale) eq 2 then begin
    datarange = dscale
  end else begin
    datarange = minmax(pixel_data.counts)
  end
  
  for i=0, 31 do begin
     self.detectors[i]->setProperty, datarange=datarange, uvalue=pixel_data.counts[i,*], showsin=showsin 
  end
end


pro stx_detector_plotter__define
   void = { stx_detector_plotter, $
    detectors       : make_array(32, /obj), $
    inherits        idl_object $
  }
end