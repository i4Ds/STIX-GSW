function stx_lightcurve_plott::init, data,  current=current, _extra=extra

  return, self->stx_plott::init(data,current=current,_extra=extra)
  
end

pro stx_lightcurve_plott::cleanup
  
  self->stx_plott::cleanup
end


pro stx_lightcurve_plott::createPlot, $
  name_prefix=name_prefix, $
  overplot=overplot, $
  styles=styles, $
  showlegend=showlegend, $
  showxlabels=showxlabels, $
  ytitle = ytitle, $
  position=position, $
  xstyle = xsytle, $
  ystyle = ystyle, $
  ylog = ylog, $
  starttime = starttime, $
  histogram=histogram, $
  _extra=extra
  
  COMPILE_OPT hidden
  
  data = *self.data
  
  default, showxlabels, 1
  default, position, [0.1,0.1,0.7,1]
  default, showlegend, 1
  default, styles, stx_plott_linestyles()
  default, ytitle, data.unit
  default, name_prefix, "LC"
  default, ylog, 1
  default, xstyle, 1
  default, ystyle, 1
  default, histogram, 1
  default, starttime, data.time_axis.time_start[0]

  
  precision = '(F6.2)'

  lc_e_axis = string(data.energy_axis.low, precision)+" -"+string(data.energy_axis.high, precision)+"keV"
  names = name_prefix+" "+lc_e_axis
  
  skip = 0
  
  if ~isa(overplot) then begin
  
    plot = plot([0,1], styles[skip], current=self.window, ytitle=ytitle, name=names[skip], xstyle=xstyle, ystyle=ystyle, ylog=ylog, position=position, _extra=extra)
    skip = 1
    plot->Refresh, /DISABLE
    self.plots->add, plot
    
    ax = plot.AXES
    ax[0].showtext = showxlabels    
    self.window = plot.window
  endif else begin
    self.window = overplot.window
  endelse
  
   
  for i=skip, N_ELEMENTS(data.energy_axis.WIDTH)-1 do begin
    oplot = plot([0,1],styles[i], /overplot, name=names[i])
    self.plots->add, oplot
  endfor
  

  ; Plot the legend in the same graphics window
  self.legend = legend(TARGET=self.plots, /AUTO_TEXT_COLOR, TRANSPARENCY=50, HORIZONTAL_ALIGNMENT="right", position=[1,1])
 

  if self.idlsupports_histogram_plot  then begin
    foreach pl, (self.plots) do pl.histogram=histogram
  end
  
end

pro stx_lightcurve_plott::updatePlot, start_time = start_time, current_time=current_time
   
  baseplot = (self.plots)[0]
  data = *self.data
  default, start_time, data.time_axis.time_start[0]
  default, current_time, data.time_axis.time_end[-1]
  
  baseplot->Refresh, /DISABLE
  
  ;idl 8.3 hack showtext ist turned off somewhere
  ax = baseplot.AXES
  ax[3].showtext = 0
  ax[0].title = "Start Date: " + stx_time2any(start_time,/vms)

  time_axis = stx_time2any(data.time_axis.time_end) - stx_time2any(start_time)
  time_range = stx_time2any([start_time, current_time])-stx_time2any(start_time)

  if ~self.idlsupports_histogram_plot then begin
    time_axis = self->line_data2histogram(time_axis, /x)
  end

  baseplot[0].xrange = time_range

  for lc_i=0, n_elements(data.energy_axis.mean)-1 do begin
    (self.plots)[lc_i]->setData, time_axis, self->line_data2histogram(reform(data.data[lc_i,*]), /test_first)
  end
  
  baseplot->Refresh
end


pro stx_lightcurve_plott__define
  compile_opt idl2

  define = {stx_lightcurve_plott, $
      inherits stx_plott $
  }

end