;+
;
; NAME:
;
;   stx_estimate_spectral_index
;
; PURPOSE:
;
;   Computes the spectral index in the different energy bins of a STIX spectrum, assuming a powerlaw dostribution in each energy bin.
;
; CALLING SEQUENCE:
;
;   results = stx_estimate_spectral_index(e_low, e_high, spectrum)
;   
; INPUTS:
;
;   e_low: array containing the lower edges of the energy bins
;   
;   e_high: array containing the higher edges of the energy bins
;   
;   spectrum: array containing the values of the STIX spectrum in the different energy bins
;
; OUTPUTS:
; 
;   Structure containing the following fields:
;
;     index_final: array containing the final estimate of the spectral indices in the different energy bins
;     
;     idx_peak: int, index corresponding to the peak of the spectrum. The spectral index at the peak is 0 by default.
;
;
; HISTORY: April 2025, Krucker S. and Massa P., first release 
;
; CONTACT:
;   samuel.krucker@fhnw.ch
;   paolo.massa@fhnw.ch
;   
;-
function stx_estimate_spectral_index, e_low, e_high, spectrum

  e_mean=(e_low+e_high)/2.
  ;weighted average calculated below
  e_weighted=e_mean*0.
  de=(e_high-e_low)


  ;;**** Calculate power law using the center of the energy bin
  
  ;value using center of bin
  index_tmp=fltarr(n_elements(spectrum))
  ;value using weighted average of energy bin
  index_final=fltarr(n_elements(spectrum))
  
  idx_peak = where(spectrum eq max(spectrum))
  idx_peak = idx_peak[0]
  
  if idx_peak gt 0 then begin
    
    for i=0,idx_peak-1 do begin
      this_x=alog(e_mean(i+1))-alog(e_mean(i))
      this_y=alog(spectrum(i+1))-alog(spectrum(i))
      index_tmp(i)=this_y/this_x
      ;use initial value to calculate weighted center
      h0=(e_high(i)^(index_tmp(i)+2)-e_low(i)^(index_tmp(i)+2))/(index_tmp(i)+2)
      h1=(e_high(i)^(index_tmp(i)+1)-e_low(i)^(index_tmp(i)+1))/(index_tmp(i)+1)
      e_weighted(i)=h0/h1
    endfor
    
  endif
  
  ;above peak (negative index)
  for i=idx_peak+1,n_elements(spectrum)-1 do begin
    this_x=alog(e_mean(i))-alog(e_mean(i-1))
    this_y=alog(spectrum(i))-alog(spectrum(i-1))
    index_tmp(i)=this_y/this_x
    ;use initial value to calculate weighted center
    h0=(e_high(i)^(index_tmp(i)+2)-e_low(i)^(index_tmp(i)+2))/(index_tmp(i)+2)
    h1=(e_high(i)^(index_tmp(i)+1)-e_low(i)^(index_tmp(i)+1))/(index_tmp(i)+1)
    e_weighted(i)=h0/h1
  endfor
  
  ;for peak, no value is calculated
  ;set e_weighted to center
  e_weighted(idx_peak)=e_mean(idx_peak)
  
  ;recalculate slopes with weighted center
  for i=idx_peak+1,n_elements(spectrum)-1 do begin
    this_x=alog(e_weighted(i))-alog(e_weighted(i-1))
    this_y=alog(spectrum(i))-alog(spectrum(i-1))
    index_final(i)=this_y/this_x
  endfor
  
  if idx_peak gt 0 then begin
    
    for i=0,idx_peak-1 do begin
      this_x=alog(e_weighted(i+1))-alog(e_weighted(i))
      this_y=alog(spectrum(i+1))-alog(spectrum(i))
      index_final(i)=this_y/this_x
    endfor
    
  endif
  
  ;; Change sign to be consistent with definition of powerlaw: E^-idx
  index_final = -index_final
  
  ;; Set NAN or INF values equal to 0
  idx_nan_inf = where(~finite(index_final), /null)
  index_final[idx_nan_inf] = 0.
  
  ;; Set indices >= 8 or <= -8 equal to 8 and -8, respectively.
  idx_large_abs = where(abs(index_final) ge 8.)
  index_final[idx_large_abs] = signum(index_final[idx_large_abs]) * 8.
    
  results = {index_final: index_final, $
             idx_peak: idx_peak}
  
  return, results
    
end
