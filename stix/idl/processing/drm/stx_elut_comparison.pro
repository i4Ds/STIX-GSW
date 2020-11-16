;+
; :description:
; 
;  This procedure produces several plots indicating the differences between two ELUT csv files
;
; :categories:
; 
;  calibration 
;
; :params:
; 
; elut_filename_new                          : in, type="string"
;                                              the path to the first ELUT file which should be compared  
;
; :keywords:
;
; elut_filename_current                      : in, type="string"
;                                              the path to the second ELUT file which should be compared. Genrally assumed to be the current operational ELUT
;                                              if unspecified the default file read by stx_read_elut will be used 
;
;
; :examples:
;
;
;
; :history:
;    15-Apr-2020 - ECMD (Graz), initial release
;
;-
pro stx_elut_comparison, elut_filename_new, elut_filename_current = elut_filename_current

  name_new = file_basename(elut_filename_new)
  name_new = name_new.substring(11,-5)
  
  
  loadct,73
  tvlct,r,g,b, /get
  rgbtabgr=[[reverse(r)],[reverse(g)],[reverse(b)]]

  stx_read_elut, gain_new, offset_new, adc_new, scale = 0, elut_filename = elut_filename_new

  energy =  (adc_new.ekev)[*,0,0]

  ;check ADC integrity
  file_adc = adc_new.ADC4096

  gain_from_ADC =  (energy[-1]- energy[0])/(file_adc[-1, *,* ] - file_adc[0, *  ,*])

  gain_diff = abs(gain_new - gain_from_ADC)

  pgd = gain_diff/gain_new*100

  im = image(transpose(pgd), indgen(32), indgen(12), ytitle ="Pixel Index", xtitle = 'Detector Index', Title ='Table Consistency: Gain from ADC boundaries', $
    rgb_table = rgbtabgr, margin = 0.1, axis = 1, max_value = 1, min_value = 0  )
  c = colorbar(targe = im, major = 2, position = [200, 440, 455,470], /dev, title = 'Percentage difference')
  im.save, 'elut_comparison_consistency_gain_'+name_new+'.png'

  offset_from_ADC = file_adc[0,*,*]- energy[0]/gain_from_ADC


  offset_diff = abs(offset_new - offset_from_ADC)

  pod = offset_diff/offset_new*100

  im = image(transpose(pod), indgen(32), indgen(12), ytitle ="Pixel Index", xtitle = 'Detector Index', Title ='Table Consistency: Offset from ADC boundaries', $
    rgb_table = rgbtabgr, margin = 0.1, axis = 1, max_value = 1, min_value = 0  )
  c = colorbar(targe = im, major = 2, position = [200, 440, 455,470], /dev, title = 'Percentage difference')
  im.save, 'elut_comparison_consistency_offset_'+name_new+'.png'


  ADC_from_og = lonarr(31, 12,32)

  for i = 0, 11 do for j =0,31 do ADC_from_og[*, i,j] = round(energy/(gain_new[i,j])+(offset_new[i,j]))

  diff = total(abs(ADC_from_og - file_adc),1)

  print, ' Total ADC  Deviation' ,total(diff)


  im = image(transpose( diff), indgen(32), indgen(12), ytitle ='Detector Index' , xtitle = "Pixel Index", $
    rgb_table = rgbtabgr, margin = 0.1, axis = 1, max_value = 2, min_value = 0, Title= 'Table Consistency: Total ADC Deviation from file Offset Gain ')
  c = colorbar(targe = im, major = 2, position = [200, 440, 455,470], /dev)
  im.save, 'elut_comparison_consistency_adc_'+name_new+'.png'


  stx_read_elut, gain_current, offset_current, adc_current, scale = 0, elut_filename = elut_filename_current


  gain_diff = gain_new - gain_current

  pgd = gain_diff/gain_current*100

  im = image(transpose(pgd), indgen(32), indgen(12), ytitle ="Pixel Index", xtitle = 'Detector Index', Title ='Comparison of Gain with current ELUT', $
    rgb_table = 70, margin = 0.1, axis = 1, max_value = 1, min_value = -1  )
  c = colorbar(targe = im, major = 2, position = [200, 440, 455,470], /dev, title = 'Percentage difference from current ELUT')
  l = 'New ELUT : '+  file_basename(elut_filename_new)+ string(10B) +' Current ELUT: '+ file_basename(elut_filename_current)
  t = text(0.5, 0.1,l,ALIGNMENT =0.5,FONT_SIZE=11)
  im.save, 'elut_comparison_gain_'+name_new+'.png'


  offset_diff = (offset_new - offset_current)*mean((gain_current+gain_new)/2.)
  pod = offset_diff

  ;offset_diff = (offset_new - offset_current)
  ;pod = offset_diff/offset_new*100

  im = image(transpose(pod), indgen(32), indgen(12), ytitle ="Pixel Index", xtitle = 'Detector Index', Title ='Comparison of Offset with current ELUT', $
    rgb_table = 70, margin = 0.1, axis = 1, max_value = 1., min_value = -1 )
  c = colorbar(targe = im, major = 2, position = [200, 440, 455,470], /dev, title = 'Difference from current ELUT [keV]')
  l = 'New ELUT : '+  file_basename(elut_filename_new)+  string(10B) +' Current ELUT: '+ file_basename(elut_filename_current)
  t = text(0.5, 0.1,l,ALIGNMENT =0.5,FONT_SIZE=11)
  im.save,  'elut_comparison_offset_'+name_new+'.png'



  apgd = abs(pgd)

  im = image(transpose(apgd), indgen(32), indgen(12), ytitle ="Pixel Index", xtitle = 'Detector Index', Title ='Comparison of Gain with current ELUT', $
    rgb_table = rgbtabgr, margin = 0.1, axis = 1, max_value = 1, min_value = 0  )
  c = colorbar(targe = im, major = 2, position = [200, 440, 455,470], /dev, title = 'Percentage Absolute Difference from Current ELUT')
  l = 'New ELUT : '+  file_basename(elut_filename_new)+ string(10B) + ' Current ELUT: '+ file_basename(elut_filename_current)
  t = text(0.5, 0.1,l,ALIGNMENT =0.5,FONT_SIZE=11)
  im.save, 'elut_comparison_abs_gain_'+name_new+'.png'

  apod = abs(pod)

  im = image(transpose(apod), indgen(32), indgen(12), ytitle ="Pixel Index", xtitle = 'Detector Index', Title ='Comparison of Offset with current ELUT', $
    rgb_table = rgbtabgr, margin = 0.1, axis = 1, max_value = 1, min_value = 0  )
  c = colorbar(targe = im, major = 2, position = [200, 440, 455,470], /dev, title = 'Difference from current ELUT [keV]')
  l = 'New ELUT : '+  file_basename(elut_filename_new)+  string(10B) +' Current ELUT: '+ file_basename(elut_filename_current)
  t = text(0.5, 0.1,l,ALIGNMENT =0.5,FONT_SIZE=11)
  im.save, 'elut_comparison_abs_offset_'+name_new+'.png'



  a = gain_current
  ae = gain_new

  b = offset_current
  be = offset_new

  ;p = plot(indgen(n_elements(a)),reform(a,n_elements(a)), /hist, xtitle = 'Pixel', ytitle = 'Offset', DIMENSIONS=[834,889], $
  ;  POSITION=[0.10855775,0.59925338,0.53224640,0.95968919],name ='Fitted')

  ;p = plot(indgen(n_elements(a)),reform(ae,n_elements(a)), /hist , color = reform(rgbtab[5,*]), /over, /current, linestyle = 2, xrange = [0, max(where( ae gt 0))], /xstyle,  name ='Expected')



  ;p.save, 'Offset_Discrepancy_'+namesalllist[k].substring(15,-18)+'.png'
  ;; wait, 2

  ;p.close


  ;a = transpose(a)
  ;be = transpose(be)
  ;plot, b, psym = 10, yrange = [0.38,0.42]
  ;oplot, be,color = 4, psym = 10

  ;p = plot(indgen(n_elements(b)),reform(b,n_elements(b)), /hist,  POSITION=[0.10609144,0.17399378,0.53828033,0.52482883] , xtitle = 'Pixel', ytitle = 'Gain',/current)
  ;p = plot(indgen(n_elements(b)),reform(be,n_elements(b)), /hist , color = reform(rgbtab[5,*]), /over, /current, linestyle = 2, xrange = [0, max(where( ae gt 0))], /xstyle)


  x  = indgen(n_elements(a))
  y = reform(a,n_elements(a))

  plot0 = Plot(x, y, $  ; <- Data required
    XRANGE=[0.0000000,384.00000], $
    YTITLE='Gain', $
    XTITLE='Pixel', $
    NAME=file_basename(elut_filename_current), thick = 2, xthick = 2, ythick = 2, $
    DIMENSIONS=[826,911], Title = 'Absolute Values',$
    POSITION=[0.13855806,0.59925336,0.98481602,0.95968920], $
    HISTOGRAM=1,FONT_SIZE=15)


  x  = indgen(n_elements(ae))
  y = reform(ae,n_elements(ae))

  plot1 = Plot(x, y, $  ; <- Data required
    OVERPLOT=plot0, $
    COLOR=[230,159,0], $
    NAME=file_basename(elut_filename_new), $
    LINESTYLE=2,  thick = 2, $
    HISTOGRAM=1)
  x  = indgen(n_elements(b))
  y = reform(b,n_elements(b))

  plot2 = Plot(x, y, $  ; <- Data required
    XRANGE=[0.0000000,384.00000], $
    XTITLE='Pixel', $
    YTITLE='Offset', $
    HISTOGRAM=1, thick = 2, xthick = 2, ythick = 2, $
    POSITION=[0.13488090,0.17399378,0.98937210,0.52482887], $
    /CURRENT,FONT_SIZE=15)

  x  = indgen(n_elements(b))
  y = reform(be,n_elements(b))

  plot3 = Plot(x, y, $  ; <- Data required
    OVERPLOT=plot2, $
    COLOR=[230,159,0], $
    NAME='Plot 1', $
    LINESTYLE=2, thick = 2, $
    HISTOGRAM=1)

  l = legend(position =[780,100], /dev)

  plot0.save,'elut_comparison_values_'+name_new+'.png'

  pdo = offset_diff
  bin = 0.05
  h = histogram(pdo, bin =bin, loc = x)
  if n_elements(h) eq 1 then begin

    h= [0,h,0]
    x = [x-bin,x,x+bin]
  endif
  plot0 = plot(x, h, /hist, xstyle =1, xrange =[-3, 3],YTITLE='Number of Pixles', $
    XTITLE='[keV]', $
    DIMENSIONS=[600,425], margin = [0.1,0.2,0.05,0.1], $
    ; POSITION=[0.12777946,0.57747199,0.92997396,0.93320146], $
    layout = [1,2,1], $
    TITLE='Change in Offset')

  title = plot0.TITLE
  title.FONT_NAME = 'DejaVuSans'
  title.FONT_SIZE = 11.000000


  ;pdg = (b - be)/be*100
  bin = 0.05

  h = histogram(pgd, bin = bin, loc = x)
  if n_elements(h) eq 1 then begin

    h= [0,h,0]
    x = [x-bin,x,x+bin]
  endif
  plot1 = plot(x, h, /hist, xstyle =1, xrange =[-3, 3], $ ; <- Data required
    YTITLE='Number of Pixles', $
    XTITLE='Percentage', margin = [0.1,0.3,0.05,0.05], $
    ; POSITION=[0.12974137,0.12145282,0.93804784,0.48037966], $
    layout = [1,2,2],$
    TITLE='Change in Gain', $
    /CURRENT)

  title = plot1.TITLE
  title.FONT_NAME = 'DejaVuSans'
  title.FONT_SIZE = 11.000000
  ;l = xnames[0] +' = '+ strtrim(temp[k],2) +', ' + xnames[2] +' = '+ strtrim(Peak_time[k],2) +', '+ xnames[1]  +' = '+ strtrim(volt[k],2)


  ;t = text(0.5, 0.038,l,ALIGNMENT =0.5,FONT_SIZE=11)


  plot0.save, 'elut_comparison_histogram_'+name_new+'.png'


end