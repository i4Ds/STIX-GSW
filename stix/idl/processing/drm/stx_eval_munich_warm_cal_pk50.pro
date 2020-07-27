;+
; :Description:
;    Identify the narrow line spectra in the warm cal Munich data and fit the main peak
;    Not all detectors, pixels, and runs qualify. The criteria for fitting for all runs turns out
;    to be those spectra with peaks gt 50 counts.  This is not a normal calibration run and should not
;    be treated as such. It requires customization. In flight calibrations should be small displacements from
;    their previous calibrations. This fits the peaks with a simple gaussian and adds the fitted peak to the
;    input Spectra structure
;
;
;
;
;
; :Author: 26-nov-2019, rschwartz70@gmail.com
;-
pro stx_eval_munich_warm_cal_pk50, spectra, threshold = threshold, filename = filename
  default, threshold, 50
  sps,/land, /color
  linecolors
  device, filename = filename
  izx = findgen(250) + 300.5
  !p.multi = [0, 8, 8]
  z = where( abs( spectra.totsp -600 ) lt 400 and spectra.vpk ge threshold, nz)
  f31 = fltarr( 11, nz)
  fpar = fltarr( 3, nz )
  for iz= 0L, nz-1 do begin
    s = spectra[z[iz]]
    data = s.data
    plot, izx+.5, data, xtickint=100, xcharsize=1., psym=10, title= 'p:'+strtrim(s.ip,2)+' d:'+strtrim(s.id,2)+$
      ' run:'+strtrim( s.irun, 2), yrang= [0, max(data)*1.2]
    use = s.ipk-5+indgen(11)
    f31[0,iz] = gaussfit(  izx[use], s.data[use],a, sig=sig)
    fpar[0,iz] = a[0:2]
    oplot, izx[use], f31[*,iz], col=7, thick=2, psy=-1, symsize=.2
  endfor
  device,/cl
 
  !p.multi = 0

  set_x
  ;Modify the spectra structure array 
  spectra = add_tag( spectra, 0.0, 'gauss_pk')
  spectra[z].gauss_pk = reform( fpar[1,*] )
end
