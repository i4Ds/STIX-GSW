;+
; :description:
;    Demonstration script in which the 81 keV calibration line spectrum including the effects of hole tailing is fit
;
; :categories:
;    demo, example
;
; :examples:
;    stx_hecht_fit_demo
;
; :history:
;    14-Jun-2017 - ECMD (Graz), initial release
;
;-
pro stx_hecht_fit_demo
  ;with of energy bins in keV
  de = 0.5
  
  ;array of energies
  e =  findgen(146/de)*de + 4.
  pall = [[0.36,24.,10000.], [0.18,12.,10000.], [0.09,6.,10000.]]
  
  for i =0, 2 do begin
  
    ;set the parameters for the expected radiation damage level
    ptrue = reform(pall[*,i])
    
    ;simulate shape of 81 keV line including hole tailing
    f = stx_hecht_fit( e, ptrue )
    
    ;add constant noise component at the expected average background level
    fr = long(f) + 0.3
    
    ;add some poisson noise to the simulated spectrum
    ff = poidev(fr, seed = seed)
    
    ef = sqrt(ff)
    
    ; only perform the fit in a region around the calibrating line
    u = where(e gt 40 and e lt 85)
    
    ; set the assumed starting parameters for the fit
    p0  = [1,50,10000.]
    
    ;perform the fit on the simulated spectrum
    param = mpfitfun('stx_hecht_fit', e[u], ff[u], ef[u]*0+1, p0)
    
    ;calculate the model spectrum using the fitted parameters
    y = stx_hecht_fit(e, param)
    discr = abs(param - ptrue) / ptrue*100.
    pos = [75./640.,50./510.,600./640.,420./510.]
    
    ;plot the simulated and fit spectra
    p1 = plot( e, ff, xtitle = 'energy (kev)', ytitle = 'Counts', name = 'Input spectrum' + strjoin(strcompress(string(ptrue, format='(f8.2)'))), position = pos)
    p2 = plot( e, y, color ='lime  green', linestyle =2, /current, /overplot, name = 'Fitted spectrum' + strjoin(strcompress(string(param, format='(f8.2)'))))
    p3 = plot( e, 0.*y, color ='white', linestyle =2, /current, /overplot, name = '% Discrepancy' + strjoin(strcompress(string(discr, format='(f8.2)'))))
    leg = legend(target=[p1,p2, p3], position=[520/640.,505./510.], font_size=12, shadow = 0)
    
    ;print the percentage discrepancy between the true and fitted parameters
    print, discr
  endfor
  
end
