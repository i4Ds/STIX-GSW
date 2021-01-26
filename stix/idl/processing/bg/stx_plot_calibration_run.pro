;+
; :description:
;
;  This procedure produces a postscript plot of all individual calibration spectra. The plots are made over a set ACD range.
;
; :categories:
;
;  calibration, plotting
;
; :params:
;
;  spec_array: in, required the array containing all calibration spectra to be plotted
;
;  calibration_info: in, required the structure containing the metadata corresponding to each calibration run
;
; :keywords:
;
;  range :        in, optional, type="int array"
;                 two element array specifying the maximum and minimum ADC values to be plotted
;                 for all spectra
;
;  run_linestyle: in, optional, type="int array"
;                 an array with nrun elements giving the line style for the multiple run comparison plots 
;
;  run_col:       in, optional, type="int arry"
;                 an array with nrun elements giving the line colour for the multiple run comparison plots 
;
;  rate:          in, optional, type="boolean"
;                 if set scale each spectrum in the multiple run comparison plots by total livetime 
;
;  scaled:        in, optional, type="boolean"
;                 if set scale each spectrum in the multiple run comparison plots by such the the maximum value is 1.0 
;
; :examples:
;
;    stx_plot_calibration_run, calibration_spectrum_array, asw_ql_calibration_spectra
;
; :history:
;    21-Jul-2020 - ECMD (Graz), initial release
;    19-Nov-2020 - ECMD (Graz), added keywords for selecting line style and colour for multiple runs
;                               added _extra for additional plotting pass through
;                               added rate and scaled keywords for plotting multiple calibration spectra on the same plot
;
;-
pro stx_plot_calibration_run, spec_array, calibration_info, range = range,$
  run_linestyle = run_linestyle, run_col = run_col, rate =rate, scaled = scaled, _extra = _extra

  nrun = n_elements(calibration_info)

  ; the default range in ADC to show calibration peaks for all spectra accumulated
  default, range, [250, 750]
  default, run_linestyle, indgen(nrun)
  default, run_col, indgen(nrun)

  ix = indgen( range[1]- range[0] ) + range[0]

  loadct, 0

  ;If the array only contains spectra corresponding to a single run the trailing dimension is
  ;likely to be truncated
  if n_elements(size(spec_array,/dim)) ne 4 then spec_array = reform(spec_array, 1024, 12, 32 , 1 )

  ; reduce the array to contain only ADC channels in the specified range
  spectra = spec_array[ix, *, *, *]

  ;reform the array again to handle single run truncation
  if n_elements(size(spectra,/dim)) ne 4 then spectra = reform(spectra, n_elements(ix), 12, 32 , 1 )

  sps, /land, /color
  !p.multi = [0, 4, 4]

  linecolors

  ; the main plot - for each detector, pixel and run the expanded calibration spectrum is plotted over the given range in ADC channels
  for irun = 0, nrun-1 do begin
    device, filename = 'all_spectra_' +time2fid(atime(stx_time2any(calibration_info[irun].start_time)), /full, /time)+ '.ps'
    for idet = 0, 31 do for ipix = 0,11 do  begin
      sp = spectra[*,ipix, idet, irun]
      plot, ix, float(sp), xtickint = 100, xcharsize=1., psym=10, title= ' Det:'+strtrim(idet+1,2) + ' Pix:'+strtrim(ipix,2) ;following numbering convention that detectors are numbered 1-32 and pixels 0-11
    endfor
    device,/cl

  endfor

  ; if multiple runs are present in the array two more files are generated comparing and summing the spectra for each detector pixel
  if nrun gt 1 then begin

    device, filename= 'all_spectra_compared.ps'
    for idet = 0, 31 do for ipix = 0, 11 do  begin
      plot, ix, float( spectra[*,ipix, idet, 0]), xtickint=100, xcharsize=1., psym=10, title= ' Det:'+strtrim(idet+1,2) + ' Pix:'+strtrim(ipix,2), yrange = [0,1.1*max(spectra[*,ipix, idet, *])] , /yst
      for irun = 1, nrun-1 do oplot, ix,  float( spectra[*,ipix, idet, irun]), psym=10, color = run_col[irun], line = run_linestyle[irun]
    endfor
    device,/cl

    if keyword_set(rate) then begin
      device, filename= 'all_spectra_compared_rate.ps'
      for idet = 0, 31 do for ipix = 0, 11 do  begin
        sp = spectra[*,ipix, idet,*]
        for irun = 0, nrun-1 do sp[*,*,*, irun] = float( sp[*,*,*, irun])/(calibration_info[irun].live_time)
        plot, ix,sp[*,*,*, 0], xtickint=100, xcharsize=1., psym=10, title= ' Det:'+strtrim(idet+1,2) + ' Pix:'+strtrim(ipix,2), yrange = [0,1.1*max(sp)] , /yst
        for irun = 1, nrun-1 do oplot, ix,  sp[*,*,*, irun], psym=10, color = run_col[irun], line = run_linestyle[irun]
      endfor
      device,/cl
    endif


    if keyword_set(scaled) then begin

      device, filename= 'all_spectra_compared_scaled.ps'
      for idet = 0, 31 do for ipix = 0, 11 do  begin
        plot, ix, float( spectra[*,ipix, idet, 0])/max( spectra[*,ipix, idet, 0]), xtickint=100, xcharsize=1., psym=10, title= ' Det:'+strtrim(idet+1,2) + ' Pix:'+strtrim(ipix,2), yrange = [0,1.1] , /yst
        for irun = 1, nrun-1 do oplot, ix,  float( spectra[*,ipix, idet, irun])/max( spectra[*,ipix, idet, irun]), psym=10, color = run_col[irun], line = run_linestyle[irun]
      endfor
      device,/cl
    endif

    device, filename= 'all_spectra_summed.ps'
    for idet = 0, 31 do for ipix = 0, 11 do  begin
      sp = total(spectra[*,ipix, idet, *], 2)
      plot, ix, float(sp), xtickint=100, xcharsize=1., psym=10, title= ' Det:'+strtrim(idet+1,2) + ' Pix:'+strtrim(ipix,2)
    endfor
    device,/cl

  endif
  ;change p.multi back to standard value
  !p.multi = 0
  x

end
pro stx_elut_comparison, elut_filename_new, elut_filename_current = elut_filename_current, n_tbl_new = n_tbl_new, n_tbl_current = n_tbl_current, $ 
   candidate_new  = candidate_new, candidate_current = candidate_current

  name_new = file_basename(elut_filename_new)
  name_new = name_new.substring(11,-5)
  
  default, n_tbl_current, 3
  default, n_tbl_new, 3
  
  loadct,73
  tvlct,r,g,b, /get
  rgbtabgr=[[reverse(r)],[reverse(g)],[reverse(b)]]

  stx_read_elut, gain_new, offset_new, adc_new, scale = 0, elut_filename = elut_filename_new, n_table_header = n_tbl_new, candidate = candidate_new

  energy =  (adc_new.ekev)[1:-2,0,0]

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
    rgb_table = rgbtabgr, margin = 0.1, axis = 1, max_value = 4, min_value = 0  )
  c = colorbar(targe = im, major = 2, position = [200, 440, 455,470], /dev, title = 'Percentage difference')
  im.save, 'elut_comparison_consistency_offset_'+name_new+'.png'


  ADC_from_og = lonarr(31, 12,32)

  for i = 0, 11 do for j =0,31 do ADC_from_og[*, i,j] = round(energy/(gain_new[i,j])+(offset_new[i,j]))

  diff = total(abs(ADC_from_og - file_adc),1)

  print, ' Total ADC  Deviation' ,total(diff)


  im = image(transpose( diff), indgen(32), indgen(12), ytitle ='Detector Index' , xtitle = "Pixel Index", $
    rgb_table = rgbtabgr, margin = 0.1, axis = 1, max_value = 32, min_value = 0, Title= 'Table Consistency: Total ADC Deviation from file Offset Gain ')
  c = colorbar(targe = im, major = 2, position = [200, 440, 455,470], /dev)
  im.save, 'elut_comparison_consistency_adc_'+name_new+'.png'


  stx_read_elut, gain_current, offset_current, adc_current, scale = 0, elut_filename = elut_filename_current, n_table_header = n_tbl_current, candidate = candidate_current


  gain_diff = gain_new - gain_current

  pgd = gain_diff/gain_current*100

  im = image(transpose(pgd), indgen(32), indgen(12), ytitle ="Pixel Index", xtitle = 'Detector Index', Title ='Comparison of Gain with current ELUT', $
    rgb_table = 70, margin = 0.1, axis = 1, max_value = 1, min_value = -1  )
  c = colorbar(targe = im, major = 2, position = [200, 440, 455,470], /dev, title = 'Percentage difference from current ELUT')
  l = 'New ELUT : '+  file_basename(elut_filename_new)+ string(10B) +' Current ELUT: '+ file_basename(elut_filename_current)
  t = text(0.5, 0.1,l,ALIGNMENT =0.5,FONT_SIZE=11)
  im.save, 'elut_comparison_gain_'+name_new+'.png'


  offset_diff = (offset_new - offset_current)
  offset_diff_kev = offset_diff*mean((gain_current+gain_new)/2.)
  pod = offset_diff

  offset_diff_adc = (offset_new - offset_current)/4.

  im = image(transpose(pod), indgen(32), indgen(12), ytitle ="Pixel Index", xtitle = 'Detector Index', Title ='Comparison of Offset with current ELUT', $
    rgb_table = 70, margin = 0.1, axis = 1, max_value = 1., min_value = -1 )
  c = colorbar(targe = im, major = 2, position = [200, 440, 455,470], /dev, title = 'Difference from current ELUT [%]')
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

  im = image(transpose(pod), indgen(32), indgen(12), ytitle ="Pixel Index", xtitle = 'Detector Index', Title ='Comparison of Offset with current ELUT', $
    rgb_table = 70, margin = 0.1, axis = 1, max_value = 1., min_value = -1 )
  c = colorbar(targe = im, major = 2, position = [200, 440, 455,470], /dev, title = 'Difference from current ELUT [%]')
  l = 'New ELUT : '+  file_basename(elut_filename_new)+  string(10B) +' Current ELUT: '+ file_basename(elut_filename_current)
  t = text(0.5, 0.1,l,ALIGNMENT =0.5,FONT_SIZE=11)
  im.save,  'elut_comparison_offset_'+name_new+'.png'



  im = image(transpose(apod), indgen(32), indgen(12), ytitle ="Pixel Index", xtitle = 'Detector Index', Title ='Comparison of Offset with current ELUT', $
    rgb_table = rgbtabgr, margin = 0.1, axis = 1, max_value = 1, min_value = 0  )
  c = colorbar(targe = im, major = 2, position = [200, 440, 455,470], /dev, title = 'Difference from current ELUT [%]')
  l = 'New ELUT : '+  file_basename(elut_filename_new)+  string(10B) +' Current ELUT: '+ file_basename(elut_filename_current)
  t = text(0.5, 0.1,l,ALIGNMENT =0.5,FONT_SIZE=11)
  im.save, 'elut_comparison_abs_offset_'+name_new+'.png'



  a = gain_current
  ae = gain_new

  b = offset_current
  be = offset_new


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
  plot0 = plot(x, h, /hist, xstyle =1, xrange =[-6, 6],YTITLE='Number of Pixles', $
    XTITLE='[ADC channels]', $
    DIMENSIONS=[600,425], margin = [0.1,0.2,0.05,0.1], $
    ; POSITION=[0.12777946,0.57747199,0.92997396,0.93320146], $
    layout = [1,2,1], $
    TITLE='Change in Offset')

  title = plot0.TITLE
  title.FONT_NAME = 'DejaVuSans'
  title.FONT_SIZE = 11.000000


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



  plot0.save, 'elut_comparison_histogram_'+name_new+'.png'


end
