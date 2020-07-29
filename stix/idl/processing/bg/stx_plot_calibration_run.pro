;+
; :description:
;
;  This procedure produces a postscript plot of all individual calibration spectra. The plots are made over a set ACD range.
;
; :categories:
;
;  calibartion, plotting
;
; :params:
;
;  spec_array: in, required the array containing all calibration spectra to be plotted
;
; :keywords:
;
;  range :  in, optional, type="int arry"
;           two element array specifying the maximum and minimum ADC values to be plotted
;           for all spectra
;
;
; :examples:
;
;    stx_plot_calibration_run, calibration_spectrum_array, asw_ql_calibration_spectra
;
; :history:
;    21-Jul-2020 - ECMD (Graz), initial release
;
;-
pro stx_plot_calibration_run, spec_array, asw_ql_calibration_spectra, range = range

  nrun = asw_ql_calibration_spectra.count()

  ; the default range in ADC to show calibration peaks for all spectra accumulated
  default, range, [250, 750]

  ix = indgen( range[1]- range[0] ) + range[0]

  loadct, 0

  ;If the the array only contains spectra corresponding to a single run the trailing dimension is
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
    device, filename = 'all_spectra_' +time2fid(atime(stx_time2any(asw_ql_calibration_spectra[irun].start_time)), /full, /time)+ '.ps'
    for idet = 0, 31 do for ipix = 0,11 do  begin
      sp = spectra[*,ipix, idet, irun]
      plot, ix, float(sp), xtickint = 100, xcharsize=1., psym=10, title= ' Det:'+strtrim(idet+1,2) + ' Pix:'+strtrim(ipix,2) ;following numbering convention that detectors are numbered 1-32 and pixels 0-11
    endfor
    device,/cl

  endfor

  ; if multiple runs are present in the array two more files are generated comparing and summing the spectra for each detector pixel
  if nrun gt 1 then begin

    device, filename= 'all_spectra_compared_scaled.ps'
    for idet = 0, 31 do for ipix = 0, 11 do  begin
      plot, ix, float( spectra[*,ipix, idet, 0])/max( spectra[*,ipix, idet, 0]), xtickint=100, xcharsize=1., psym=10, title= ' Det:'+strtrim(idet+1,2) + ' Pix:'+strtrim(ipix,2), yrange = [0,1.1] , /yst
      for irun = 1, nrun-1 do oplot, ix,  float( spectra[*,ipix, idet, irun])/max( spectra[*,ipix, idet, irun]), psym=10, color = irun, line = 1
    endfor
    device,/cl


    device, filename= 'all_spectra_summed.ps'
    for idet = 0, 31 do for ipix = 0, 11 do  begin
      sp = total(spectra[*,ipix, idet, *], 2)
      plot, ix, float(sp), xtickint=100, xcharsize=1., psym=10, title= ' Det:'+strtrim(idet+1,2) + ' Pix:'+strtrim(ipix,2)
    endfor
    device,/cl

  endif
  ;change p.multi back to standard value
  !p.multi = 0

end
