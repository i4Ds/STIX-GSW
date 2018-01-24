;+
; NAME:
;
;       stx_interval_plot
;
; PURPOSE:
;
; create several plots for the interval selection
;
; CALLING SEQUENCE:
;
; stx_interval_plot,spectrogram,time_axis,energy_axis,intervals
;
; INPUTS:
;
;
; KEYWORD PARAMETERS:
;
;       PS = draw to PS
;
;
;
; MODIFICATION HISTORY:
;
; Nicky Hochmuth, i4Ds, 2011-02-01.
;
;
;
;       hochmuth.nicky@fhnw.ch
;
;-

pro stx_interval_plot,spectrogram_in , intervals = intervals_in, overplot=overplot, PS = ps, plotnr = plotnr, minCount=minCount, thermalboundary=thermalboundary, plot_energy_binning=plot_energy_binning, ylog=ylog,  title=title, skipcontour=skipcontour

  compile_opt IDL2
  
  default, overplot, 0
  default, ylog, 1
  default, plot_energy_binning, 0
  default, ps, 0
  default, THERMALBOUNDARY, 20
  default, title, "spectrogram"
  default, skipcontour, 0
  
  if ppl_typeof(spectrogram_in,COMPARETO="stx_fsw_ivs_spectrogram") then begin
    ltime = byte(spectrogram_in.counts)
    ltime[*] = 1
    energy_axis = spectrogram_in.energy_axis
    energy_axis_orig = stx_construct_energy_axis()
    spectrogram = stx_spectrogram(spectrogram_in.counts,spectrogram_in.time_axis, energy_axis, ltime)
    
    if isa(intervals_in) then begin
      intervals = replicate(stx_ivs_interval(), n_elements(intervals_in))
      intervals.start_time = intervals_in.start_time
      intervals.end_time = intervals_in.end_time
      intervals.start_time_idx  = intervals_in.start_time_idx
      intervals.end_time_idx = intervals_in.end_time_idx
      intervals.start_energy = energy_axis_orig.low[intervals_in.start_energy_idx]
      intervals.end_energy = energy_axis_orig.high[intervals_in.end_energy_idx]
      intervals.start_energy_idx = intervals_in.start_energy_idx
      intervals.end_energy_idx = intervals_in.end_energy_idx
      intervals.counts = intervals_in.counts
      intervals.trim = intervals_in.trim
      intervals.spectroscopy = intervals_in.spectroscopy
    end
  endif else begin
    spectrogram = spectrogram_in
    if isa(intervals_in) then intervals=intervals_in
    
  end
  
  xsize = 12.5;
  ysize = 8
  dpi = 100;
  ;margin = 0.1;
  margin = 1
  
  if ~overplot then begin
    if ps then begin
            
;      time = anytim(spectrogram.t_axis.time[0],/utc_ext)
;      
;      time_str = trim(time.year)+'_'+trim(time.month)+'_'+trim(time.day)
;      
;      psfile = 'stx_ivs_plot_' +time_str+"_"+strtrim(long(systime(/sec)),1)+'.ps';
;      ;sps, /landscape 
;      ps_on, FILENAME=psfile, /land;, MARGIN=margin, PAGE_SIZE =[xsize,ysize], /INCHES, /landscape
    endif else begin
      window, XSIZE = dpi*xsize, YSIZE = dpi*ysize, /free, title=title
    endelse
  endif
  
  yrange=[4,150]
  
  ; extract the used data from the input
  n_t = n_elements(spectrogram.t_axis.time_start)
  n_e = n_elements(spectrogram.e_axis.width)
  
  XX=rebin(stx_time2any(spectrogram.t_axis.mean),n_t,n_e, /SAMPLE)
  YY=rebin(transpose(spectrogram.e_axis.mean),n_t,n_e, /SAMPLE)
  
  cl=39 ;39
  
  loadct, cl
    
  ;plot the spectrogram
  
  plotdata = transpose(spectrogram.data)
  
  if ~overplot then begin
    time_range=stx_time2any([spectrogram.t_axis.time_start[0],spectrogram.t_axis.time_end[-1]])
    spectro_plot2, plotdata, stx_time2any(spectrogram.t_axis.mean), spectrogram.e_axis.mean, cbar=1, xstyle=1, ystyle=1,yrange=yrange, YTITLE ='Energy keV', ylog=ylog, xrange=time_range
    
    ;overplot a contour of the spectrogram
    if ~skipcontour then contour, plotdata ,XX,YY, yrange=yrange, xrange=time_range, xstyle=1, ystyle=1, xticks=1, yticks=1, levels=[10,20,50,100,150,200,300,400,500,1000,1500,2000], Color=254, ylog=ylog, /overplot
    if keyword_set(thermalboundary) then oplot, stx_time2any([spectrogram.t_axis.time_start[0],spectrogram.t_axis.time_end[n_t-1]]), [thermalboundary,thermalboundary], thick=5, color=200, linestyle=2
    xyouts, stx_time2any(spectrogram.t_axis.time_end[n_t-1]), thermalboundary, " TB: "+trim(thermalboundary), color=200
    
    atState = float(spectrogram.attenuator_state)
    atState[where(atState eq 0)] = !VALUES.f_nan
    oplot, stx_time2any(spectrogram.t_axis.mean), atState*149, thick=5, color=100, psym=10
    xyouts, stx_time2any(spectrogram.t_axis.time_end[n_t-1]), 149, " Attenuator" , color=100
   
    
  endif
  
  if plot_energy_binning gt 0 then begin
    axis, plot_energy_binning, yaxis=1, color=200, ystyle=1, yrange=yrange, YTICKS=n_elements(spectrogram.e_axis.low), YTICKV=spectrogram.e_axis.low, ylog=ylog
  end
  

  
  ;interval plot
  if keyword_set(intervals) then begin
      colors = bytscl(intervals.counts)
      
      for spectroscopy=0, 1  do begin
        cells = where(intervals.spectroscopy eq spectroscopy, n_cells)
        
        for idx=0 , n_cells-1 do begin
          
          i = cells[idx]
          
          intervalBGColor = spectroscopy eq 0 ? 255 : 100
          intervalColor =  spectroscopy eq 0 ? 255 : 100
          intervallThick = 2
          
          fcolor = 150;
          
          ;fcolor = colors[i]
          fill = intervals[i].trim eq 10
          
          if fill then begin
            rectangle, stx_time2any(intervals[i].start_time),intervals[i].start_energy,stx_time_diff(intervals[i].end_time,intervals[i].start_time),intervals[i].end_energy-intervals[i].start_energy,color=intervalBGColor, thick=intervallThick, fcolor=fcolor ,fill=fill, orientation=90
            rectangle, stx_time2any(intervals[i].start_time),intervals[i].start_energy,stx_time_diff(intervals[i].end_time,intervals[i].start_time),intervals[i].end_energy-intervals[i].start_energy,color=intervalBGColor, thick=intervallThick, fcolor=fcolor ,fill=fill, orientation=45
            rectangle, stx_time2any(intervals[i].start_time),intervals[i].start_energy,stx_time_diff(intervals[i].end_time,intervals[i].start_time),intervals[i].end_energy-intervals[i].start_energy,color=intervalBGColor, thick=intervallThick, fcolor=fcolor ,fill=fill, orientation=-45
          end
          rectangle, stx_time2any(intervals[i].start_time),intervals[i].start_energy,stx_time_diff(intervals[i].end_time,intervals[i].start_time),intervals[i].end_energy-intervals[i].start_energy,color=intervalBGColor, thick=intervallThick, fcolor=fcolor ,fill=fill, orientation=0
          
        endfor
      endfor ;spectroscopy
    
  endif;interval plot
  
end
