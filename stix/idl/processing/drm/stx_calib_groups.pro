
;+
; :Description:
;    This procedure identifies and documents the detector groups to use and the full resolution
;    channel sets (1 for 31 keV  and 1 for 81 keV for each) to be used in the calibration
;    telemetry. These are the adc1024 channel numbers. In the inital version there are 3 groups of
;    detectors, all including their individual pixel units. Also given are the structures to define 3 additional
;    groups to be included with the nominal calibration runs. Sets of data grouped by 4 showing the index
;    of the adc1024 channels
;
; :Examples:
;   stx_calib_groups, /doplot, gr=group, /PS
; :Keywords:
;    doplot - produce the associated figures
;    groups - data structure with results
;    ps - if set, produce postscript plots
;    IDL> help, groups
;    ** Structure <15935680>, 8 tags, length=128, data length=128, refs=1:
;    G31             INT       Array[2, 3]
;    G81             INT       Array[2, 3]
;    G3181           INT       Array[2, 3]
;    GLO             INT       Array[2, 3]
;    GHI             INT       Array[2, 3]
;    LOSTEP          INT              4
;    HISTEP          INT              4
;    ID_GROUP        INT       Array[32]
;    IDL> groups
;    {
;    "G31": [305, 360, 331, 389, 359, 403],
;    "G81": [420, 478, 445, 508, 475, 521],
;    "G3181": [361, 419, 390, 444, 404, 474],
;    "GLO": [273, 304, 299, 330, 327, 358],
;    "GHI": [479, 510, 509, 540, 522, 553],
;    "LOSTEP": 4,
;    "HISTEP": 4,
;    "ID_GROUP": [1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 2, 1, 0, 0, 1, 1, 1, 1, 1, 2, 1, 1, 1, 0]
;    }
;
; :Author: rschwartz70@gmail.com
; :History: 8-Oct-2019, Initial version
;-
pro stx_calib_groups, doplot = doplot, groups = groups, ps=ps
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
  if doplot and ps then sps, /land, /color
  if doplot then begin
;Initial plot used to evaluate detector groupings
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
  ;adjust g31 so the middle can be spanned by channels grouped in fours
  dg31 = (g81[0,*] - g31[1,*]) mod 4
  ;add the excess to g31
  g31[1,*] += dg31
  g4chan = rebin( [0,31], 2, 3) 
  glochan = g31 - 32 & glochan[1,*] = glochan[ 0,* ] + 31
  
  ghichan = g81 
  ghichan[0,*] = g81[1,*]+1
  ghichan[1,*] = ghichan[0,*]+ 31
  g3181 = reform( [g31[1,*]+1,g81[0,*]-1], size(/dim, g31))
  groups = { g31: g31, g81: g81,g3181: g3181, glo:glochan, ghi:ghichan, lostep: 4, histep: 4, id_group: match }
  ;add two more 4 channel groups just beyond g31 and g81
  if doplot then begin
  
    plot, xrang=[300, 420],/xsty, mm[*,0,0], fltarr(2)+1,$
      yran=[0,40],psy=-1, xtitle='adc1024', ytitle='detector id +1', title='Calibration Groups'
    for i=0,31 do oplot, mm[*,0,i],fltarr(2)+i+1,psy=-1, color=(i+2) mod 12, thick=3
  
    for i=0,2 do for j=0,1 do oplot, g31[j,i]+fltarr(2), [0,40],col=([5,7,9])[i], thick=6, linestyle=i
  
    plot, xrang=[400,530],/xsty, mm[*,1,0], fltarr(2)+1,yran=[0,40],psy=-1,$
      xtitle='adc1024', ytitle='detector id +1', title='Calibration Groups'
    for i=0,31 do oplot, mm[*,1,i],fltarr(2)+i+1,psy=-1, color=(i+2) mod 12, thick=3
  
    for i=0,2 do for j=0,1 do oplot, g81[j,i]+fltarr(2), [0,40],col=([5,7,9])[i], thick=6, linestyle=i
  
  endif
  if !d.name eq 'PS' then begin
    device,/close
    x
    file_move,'idl.ps', 'stix_calib_groups.ps', /overwrite
  endif
  
end