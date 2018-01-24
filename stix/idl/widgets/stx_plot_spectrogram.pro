;+
; :description:
;        
; :categories:
;    plotting, visualization
;
; :params:
;  
; :keywords:
;               
;
; :examples:
;  
; :history:
;     07-Nov-2013, Version 1 written by Nicky Hochmuth (nicky.hochmuth@fhnw.ch)
;   ;-

pro stx_plot_spectrogram, time_energy_bin, time_range=time_range, energy_range=energy_range, ylog=ylog, thick=thick,  _EXTRA=_EXTRA
  default, ylog, 0
  default, thick, 0
  
  ;do not include cfl and bgm detectors
  ;TODO: N.H. find right detectors from config
  detectors = [lindgen(8),lindgen(22)+10]
  
  ;find time_range to plot
  if ~keyword_set(time_range) then begin
    time_range = minmax(stx_time2any(time_energy_bin.time_range))
  end    
  
  ;find energy range to plot
  if ~keyword_set(energy_range) then begin
    energy_range = minmax(time_energy_bin.energy_range)
  end
  
  ;find max counts for colorscaling
  global_range = 0
  valuetype = 0
  
  if tag_exist(time_energy_bin,"counts") then begin
    ;global_range = float(minmax(total(total(time_energy_bin.counts[detectors,*],2),1)))
    valuetype = 1 
  end else if tag_exist(time_energy_bin,"visibility") then begin
    ;global_range = minmax(total(abs(time_energy_bin.visibility.obsvis),1))
    valuetype = 2
  end
  
  utplot, time_range, energy_range, /nodata, _EXTRA=_EXTRA, ystyle=1, xstyle=1, ylog=ylog
  
  if ~is_struct(time_energy_bin) then return
  
  
  n_bins = n_elements(time_energy_bin)
    
   case (valuetype) of
      1: value = total(total((time_energy_bin).counts[detectors,*,*],1),1) 
      2: value = total(abs((time_energy_bin).visibility.obsvis),1)
      else: value = intarr(n_bins)
    endcase
  
  value = bytscl(value)
  
  for i=0L, n_bins-1 do begin
    t_range = stx_time2any((time_energy_bin[i]).time_range)
    e_range = (time_energy_bin[i]).energy_range
    
    ;color = byte(value / global_range[1] * 253 + 1)
    color = value[i]
    width =[t_range[1]-t_range[0], e_range[1]-e_range[0]]
    tvbox, width, t_range[0]+(width[0]/2.), e_range[0]+(width[1]/2.), color, thick=2, /data, color=color, /fill
    hit=0
    
    if thick gt 0 then rectangle,  t_range[0], e_range[0], t_range[1]-t_range[0], e_range[1]-e_range[0], color=255, linestyle=1, thick=thick
  end
  
   utplot, time_range, energy_range, /nodata, _EXTRA=_EXTRA, ystyle=1, xstyle=1, ylog=ylog, /noerase
    
end
