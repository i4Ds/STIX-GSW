function stx_detector_health_plott::init, data,  current=current, flare_flag=flare_flag, _extra=extra
  
  self.flare_flag = ptr_new(flare_flag)
  return, self->stx_plott::init(data,current=current,_extra=extra)

end

pro stx_detector_health_plott::cleanup
  
  self->stx_plott::cleanup
  
end

pro stx_detector_health_plott::setData, data, flare_flag=flare_flag, update=update, _extra=extra
  
  if isa(flare_flag) then self.flare_flag = ptr_new(flare_flag)
  self->stx_plott::setData, data, flare_flag=flare_flag, update=update, _extra=extra
  
end


pro stx_detector_health_plott::createPlot, $
  name_prefix=name_prefix, $
  overplot=overplot, $
  styles=styles, $
  showlegend=showlegend, $
  showxlabels=showxlabels, $
  ytitle = ytitle, $
  position=position, $
  starttime = starttime, $
  _extra=extra
  
  COMPILE_OPT hidden
  
  data = *self.data
  
  default, showxlabels, 1
  default, position, [0.1,0.1,0.7,1]
  default, starttime, data.time_axis.time_start[0]

  det_names = ['1a','1b','1c','2a','2b','2c','3a','3b','3c','4a','4b','4c','5a','5b','5c','6a','6b','6c','7a','7b','7c','8a','8b','8c','9a','9b','9c','10a','10b','10c','cfl','bkg','flare']
  
  if ~isa(overplot) then begin

    plot = plot(indgen(10), intarr(10)+1, "-", thick=10, name=det_names[0], yrange=[0,34], RGB_TABLE=34, current=current, /xstyle, /ystyle, position=position)
    plot->Refresh, /DISABLE
    self.plots->add, plot

    ax = plot.AXES
    ax[0].showtext = showxlabels
    self.window = plot.window
    skip = 1
  endif else begin
    self.window = overplot.window
    plot = overplot
    skip = 0
  endelse
 
  ax = plot.AXES
  if showxlabels then begin
    ax[0].title = "Start Date: " + stx_time2any(starttime,/vms)
    ax[0].showtext = 1
  endif else begin
    ax[0].showtext = 0
  endelse
  ax[1].showtext = 0

  ax[3].hide = 0
  ax[3].title = "Detectors"
  ax[3].tickvalues = indgen(33)+1
  ax[3].MINOR = 0
  ax[3].TICKNAME = det_names
  ax[3].tickfont_name = "courier"
  ax[3].showtext = 1
 
  for i=skip, 31 do begin
    self.plots->add, plot(indgen(10), intarr(10)+1+i, "-", thick=10, overplot=plot, name=det_names[i] , RGB_TABLE=34 );, sym_size=15, /sym_filled, symbol=3)    
  endfor

  self.plots->add, plot(indgen(10), intarr(10)+1+i, "k-", thick=5, symbol=3, sym_thick=5, overplot=plot, name='flareflag')
    
end

pro stx_detector_health_plott::updatePlot, start_time = start_time, current_time=current_time
   
  baseplot = (self.plots)[0]
  active_detectors = *self.data
  flare_flag = *self.flare_flag
  
  o = [11,13,18,12,19,17,7,29,1,25,5,23,6,30,2,15,27,31,24,8,28,21,26,4,16,14,32,3,20,22,10,9]-1

  
  default, start_time, active_detectors.time_axis.time_start[0]
  default, current_time, active_detectors.time_axis.time_end[-1]
  
  baseplot->Refresh, /DISABLE
  
  ;idl 8.3 hack showtext ist turned off somewhere
  ax = baseplot.AXES
  ax[3].showtext = 0
  ax[0].title = "Start Date: " + stx_time2any(start_time,/vms)

 
  ;idl 8.3 hack showtext ist turned off somewhere
  ax = baseplot.AXES
  ax[3].showtext = 1


  time_axis = stx_time_diff(active_detectors.time_axis.time_end,start_time)

  n_t = n_elements(active_detectors.time_axis.duration)
  points = uintarr(n_t)+1

  colors = bytarr(n_t)

  for i=0, 31 do begin
    (self.plots)[i]->setData, time_axis, points+i
    colors[*] = 0b

    ; compress detector state into one byte: 0 disabled, 1 Enabled, 10 yellow disabled, 11 yellow enabled

    g = where(active_detectors.data[*,o[i]] eq 1, n_g)
    r = where(active_detectors.data[*,o[i]] eq 0 or active_detectors.data[*,o[i]] eq 10, n_r)
    y = where(active_detectors.data[*,o[i]] eq 11, n_y)
    if n_g gt 0 then colors[g] = 120
    if n_r gt 0 then colors[r] = 255
    if n_y gt 0 then colors[y] = 200

    (self.plots)[i]->setProperty, vert_colors =colors
  endfor
  
  if ppl_typeof(flare_flag, COMPARETO='stx_flare_flag') then begin
    
    flare_flag_time = flare_flag.time_axis
    flare_flag = double(flare_flag.data ge 1)
    nf_i = where(flare_flag eq 0, nf_n)
    if nf_n gt 0 then flare_flag[nf_i]=!VALUES.d_nan
  
    (self.plots)[32]->setData, stx_time2any(flare_flag_time.time_end)- stx_time2any(start_time), flare_flag+32

  endif
  
  baseplot->Refresh
end


pro stx_detector_health_plott__define
  compile_opt idl2

  define = {stx_detector_health_plott, $
      flare_flag : ptr_new(), $
      inherits stx_plott $
  }

end