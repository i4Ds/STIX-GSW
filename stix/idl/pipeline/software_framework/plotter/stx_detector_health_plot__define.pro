;+
; :file_comments:
;   The detector health plot object. It can be used to plot STIX health plots showing information about
;   each detector and about when the flare occured.
;   
; :categories:
;   Plotting, GUI
;   
; :examples:
;
; :history:
;    10-May-2015 - Roman Boutellier (FHNW), Initial release
;-

;+
; :description:
;    This function initializes the object. It is called automatically upon creation of the object.
;
; :returns:
;
; :history:
;    10-May-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_detector_health_plot::init
  
  
  ; Initialize the base object
  base_initialization = self->stx_line_plot::init()
  ; Initizalize the list of plots
  self.detector_plots = list()
  self.detector_order = [11,13,18,12,19,17,7,29,1,25,5,23,6,30,2,15,27,31,24,8,28,21,26,4,16,14,32,3,20,22,10,9]-1

  return, base_initialization
end

pro stx_detector_health_plot::plot, detector_monitor=detector_monitor, flare_flag=flare_flag, $
                            name_prefix=name_prefix, styles=styles, showxlabels=showxlabels, $
                            ytitle=ytitle, start_time=start_time, current_time=current_time, $
                            overplot=overplot, dimensions=dimensions, $
                            position=base_position, plot_position=plot_position, current_window=current_window, $
                            add_legend=add_legend, _extra=extra
                            
  ; Get the default styles
  default_styles = self->_get_styles()
  
  ;Set the default styles
  default, name_prefix, default_styles.name_prefix
  default, styles, default_styles.styles
  default, showxlabels, default_styles.showxlabels
  default, ytitle, default_styles.ytitle
  default, dimensions, default_styles.dimensions
  default, plot_position, default_styles.plot_position
  default, names, default_styles.names
  default, start_time, detector_monitor.time_axis.time_start[0]
  default, current_time, detector_monitor.time_axis.time_end[-1]
  default, base_position, default_styles.base_position
  default, thick, default_styles.thick
  default, flare_thick, default_styles.flare_thick


  ; Prepare the time axis
  time_axis = stx_time_diff(detector_monitor.time_axis.time_end,start_time)

  ; Create the base plot. This plot ensures the correct window dimensions and axes etc.
  self.base_plot = *(self->stx_line_plot::_plot(time_axis, intarr(n_elements(time_axis)), thick=0, yrange=[0,34], RGB_TABLE=34, current=current_window, position=base_position, dimensions=dimensions, $
                                                /xstyle, /ystyle, ylog=0))
  self.base_plot->Refresh, /disable
;  self.base_plot = plot(indgen(10), intarr(10)+1, "-", thick=0, yrange=[0,34], RGB_TABLE=34, current=current_window, position=base_position, /xstyle, /ystyle)
 
  ; Get the number of time points (extracted from the duration)
  n_t = n_elements(detector_monitor.time_axis.duration)
  points = uintarr(n_t)+1
  
  ; Prepare the array which will hold the color values
  colors = bytarr(n_t)
  
  ; Go over detectors and plot the according line plot
  for i=0, 31 do begin
    ; First create the plot
    detector_plot = *(self->stx_line_plot::_plot(time_axis, points+i, thick=thick, yrange=[0,34], position=base_position, dimensions=dimensions, /overplot, $;current=current_window, $
                                                name=names[i], RGB_TABLE=34, ylog=0))
    
    ; Clear all the entries of the colors array
    colors[*] = 0b;
    
    ; Compress the detector staties into one byte:
    ;   - 0 disabled
    ;   - 1 enabled
    ;   - 10 yellow disabled
    g = where(detector_monitor.active_detectors[self.detector_order[i],*] eq 1, n_g)
    r = where(detector_monitor.active_detectors[self.detector_order[i],*] eq 0, n_r)
    
    ;TODO N.H every time = 1?
    y = where(detector_monitor.noisy_detectors[self.detector_order[i],*] eq 0, n_y)
    if n_g gt 0 then colors[g] = 120
    if n_r gt 0 then colors[r] = 255
    if n_y gt 0 then colors[y] = 200
    
    ; Set the colors for the plot
    detector_plot->setProperty, vert_colors = colors
    ; Store the plot
    self.detector_plots.add, detector_plot
  endfor
  
  ; Plot the flare flag
  if ppl_typeof(flare_flag, COMPARETO='stx_fsw_m_flare_flag') then begin
    
    flare_flag_time = flare_flag.time_axis
    flare_flag_signal = double(flare_flag.FLARE_FLAG ge 1)
    nf_i = where(flare_flag_signal eq 0, nf_n)
    if nf_n gt 0 then flare_flag_signal[nf_i]=!VALUES.d_nan
  
    ; Create the plot
    self.flare_plot = *(self->stx_line_plot::_plot(stx_time2any(flare_flag_time.time_end)- stx_time2any(start_time), flare_flag_signal+32, thick=flare_thick, $
                                                 symbol=3, sym_thick=5, current=current_window, /overplot, name='flareflag', yrange=[0,34], ylog=0))
  endif
  
  
  ; Set the axes
  base_axes = self.base_plot.axes
  base_axes[0].showtext = showxlabels
  if keyword_set(showxlabels) then begin
    ; Set the label of the x-axis
    base_axes[0].title = "Start Date: " + stx_time2any(start_time,/vms)
    base_axes[0].showtext = 1
  endif else begin
    ; Hide the label of the x-axis
    base_axes[0].showtext = 0
  endelse
  ; Hide the tick labels of the y-axis to the left of the plot
  base_axes[1].showtext = 0
  ; Create the y-axis labels to the right of the plot
  base_axes[3].hide = 0
  base_axes[3].title = "Detectors"
  base_axes[3].tickvalues = indgen(33)+1
  base_axes[3].minor = 0
  base_axes[3].tickname = names
  base_axes[3].tickfont_name = "courier"
  base_axes[3].showtext = 1
  
  self.base_plot->Refresh
end

pro stx_detector_health_plot::update_plots, detector_monitor=detector_monitor, flare_flag=flare_flag, $
                                            start_time=start_time, current_time=current_time, _extra=extra
                                            
  ; Disable refreshing of the plots
  self.base_plot->Refresh, /disable

  ; Prepare the array with the indices to decide upon the color of the bars
  ; Prepare the time axis
  time_axis = stx_time_diff(detector_monitor.time_axis.time_end,start_time)
  ; Get the number of time points (extracted from the duration)
  n_t = n_elements(detector_monitor.time_axis.duration)
  points = uintarr(n_t)+1
  
  ; Prepare the array which will hold the color values
  colors = bytarr(n_t)
  
  ; Go over detectors and plot the according line plot
  for i=0, 31 do begin
    ; Get the plot
    current_plot = (self.detector_plots)[i]
    ; Set the new data
    current_plot->setData, time_axis, points+i
    
    ; Clear all the entries of the colors array
    colors[*] = 0b;
    
    ; Compress the detector staties into one byte:
    ;   - 0 disabled
    ;   - 1 enabled
    ;   - 10 yellow disabled
    ;   - 11 yellow enabled
    g = where(detector_monitor.active_detectors[self.detector_order[i],*] eq 1, n_g)
    r = where(detector_monitor.active_detectors[self.detector_order[i],*] eq 0, n_r)
    
    ;TODO N.H every time = 1?
    y = where(detector_monitor.noisy_detectors[self.detector_order[i],*] eq 0, n_y)
    if n_g gt 0 then colors[g] = 120
    if n_r gt 0 then colors[r] = 255
    if n_y gt 0 then colors[y] = 200
    
    ; Set the colors for the plot
    current_plot->setProperty, vert_colors = colors
  endfor
  
  ; Plot the flare flag
  if ppl_typeof(flare_flag, COMPARETO='stx_flare_flag') then begin
    
    flare_flag_time = flare_flag.time_axis
    flare_flag_signal = double(flare_flag.FLARE_FLAG ge 1)
    nf_i = where(flare_flag_signal eq 0, nf_n)
    if nf_n gt 0 then flare_flag_signal[nf_i]=!VALUES.d_nan
  
    ; Create the plot
    self.flare_plot->setData,stx_time2any(flare_flag_time.time_end)- stx_time2any(start_time), flare_flag_signal+32
  endif
  
  ; Refresh the plots
  self.base_plot->Refresh
end

function stx_detector_health_plot::_get_styles
  ; Get the default styles
  default_styles = stx_line_plot_styles(/detector_health)
  return, default_styles
end

pro stx_detector_health_plot::delete
   if isa(self.base_plot) then self.base_plot->setdata, 0, 0
   if isa(self.flare_plot) then self.flare_plot->setdata, 0, 0
   foreach dp, self.detector_plots do begin
      if isa(dp[0]) then dp[0]->setdata, 0, 0
   endforeach

end

pro stx_detector_health_plot__define
  compile_opt idl2
  
  define = {stx_detector_health_plot, $
    base_plot: obj_new(), $
    flare_plot: obj_new(), $
    detector_plots: list(), $
    detector_order: intarr(32), $
    inherits stx_line_plot $
  }
end