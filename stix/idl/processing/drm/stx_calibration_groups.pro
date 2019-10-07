
;+
; :Description:
;    This procedure identifies and documents the 3 detector groups and the full resolution
;    channel sets (1 for 31 keV  and 1 for 81 keV for each) to be used in the calibration
;    telemetry. These are the adc1024 channel numbers.
;
; :Examples:
;   stx_calibration_groups, /doplot, gr=group, /PS
; :Keywords:
;    doplot - produce the associated figures
;    groups - data structure with results
;    IDL> help, groups
;    ** Structure <10fda040>, 3 tags, length=88, data length=88, refs=2:
;    G31             INT       Array[2, 3]
;    G81             INT       Array[2, 3]
;    ID_GROUP        INT       Array[32]
;    IDL> print, groups.g31
;    305     358
;    331     388
;    359     403
;    IDL>
;    IDL> print, groups.g81
;    420     478
;    445     508
;    475     521
;    IDL> print, groups.id_group
;    1       1       1       1       2       1       1       1       1       1       1       1       1
;    1       1       1       2       1       2       1       0       0       1       1       1       1
;    1       2       1       1       1       0
;    
;    ps
;
; :Author: richard
;-
pro stx_calibration_groups, doplot = doplot, groups = groups, ps=ps
  default, doplot, 0
  default, ps, 0
  stx_read_elut, gain, ofst, adc_str

  adc_str = add_tag( adc_str, gain,'gain')
  adc_str = add_tag( adc_str, ofst,'ofst')

  plot, histogram( ofst, min = 200, max=360)
  plot, histogram( ofst, min = 200, max=360), psym=10
  adc1024grp = reform( stx_energy2calchan( [29, 33, 79, 83.] ), 2, 2, 12, 32)

  ;Get the minmax range for each set for each detector
  mm    = fltarr( 2, 2, 32)
  for i = 0, 31 do for j = 0, 1 do mm[0,j,i] = minmax( adc1024grp[*,j,*,i] )
  ;divide minmax range for 30.85 keV line into 3 groups
  ;overall minmax
  tmm = minmax( mm[*,0,*] )
  ;Divide into 3 groups to minimize overall bandwidth
  ;Start with simplest model
  ;What is the average and maximum minmax diff
  ;Average minmax sep for every detector
  avg_sep = avg( mm[1,0,*] - mm[0,0,*] )
  max_sep = max( mm[1,0,*] - mm[0,0,*] )
  bounds = minmax( mm[*,0,*]) + [-3,+3]
  wtest = 50 ;test width, see if we can place all dets in 1 of 3 groups
  bounds_low = [ bounds[0], bounds[0]+ wtest/2, bounds[1]-wtest/2]
  bounds_hi  = bounds_low + wtest
  abounds = transpose( [[bounds_low],[bounds_hi]])
  mm_test = reform( value_closest( avg(abounds,0), avg( mm[*,0,*],0)))
  h = histogram( mm_test, rev=rev)
  linecolors
  if doplot then begin
    
    plot, xrang=[300, 420],/xsty, mm[*,0,0], fltarr(2)+1,yran=[0,35],psy=-1
    for i=0,31 do oplot, mm[*,0,i],fltarr(2)+i+1,psy=-1, color=(i+2) mod 12, thick=3

    for i=0,12 do oplot, 310+i*10+fltarr(2), [0,40],col=i+1
  endif
  ;By inspection use these three bin sets. Find the detectors that match
  gbins = ([ [305,365],[330,390], [360,410]])


  match = bytarr(32) -1
  for jj=0,2 do begin &$
    test  = where( mm[0,0,*] ge gbins[0,jj] and mm[1,0,*] le gbins[1,jj], ntest) &$
    match[test] = jj &$
  endfor

  for jj=0,2 do gbins[0,jj] = round(minmax( mm[*,0,where(match eq jj)] )) + [-1, 1]
  g31 = gbins
  for jj=0,2 do gbins[0,jj] = minmax( mm[*,1,where(match eq jj)] ) + [-3,3]
  g81 = gbins
  groups = { g31: g31, g81: g81, id_group: match }
  if doplot then begin
    if ps then sps,/land,/color
    plot, xrang=[300, 420],/xsty, mm[*,0,0], fltarr(2)+1,$
      yran=[0,40],psy=-1, xtitle='adc1024', ytitle='detector id +1', title='Calibration Groups'
    for i=0,31 do oplot, mm[*,0,i],fltarr(2)+i+1,psy=-1, color=(i+2) mod 12, thick=3
  
    for i=0,2 do for j=0,1 do oplot, g31[j,i]+fltarr(2), [0,40],col=([5,7,9])[i], thick=6, linestyle=i
  
    plot, xrang=[400,530],/xsty, mm[*,1,0], fltarr(2)+1,yran=[0,40],psy=-1,$
      xtitle='adc1024', ytitle='detector id +1', title='Calibration Groups'
    for i=0,31 do oplot, mm[*,1,i],fltarr(2)+i+1,psy=-1, color=(i+2) mod 12, thick=3
  
    for i=0,2 do for j=0,1 do oplot, g81[j,i]+fltarr(2), [0,40],col=([5,7,9])[i], thick=6, linestyle=i
    if !d.name eq 'PS' then begin
      device,/close 
      x 
      file_move,'idl.ps', 'stix_calibration_groups.ps'
    endif
    
  endif
end