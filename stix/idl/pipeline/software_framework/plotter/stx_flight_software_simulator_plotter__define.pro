
;+
; :file_comments:
;    this is the gui for the flight software simulator
;
; :categories:
;    flight software simulation, software, gui
;
; :examples:
;
; :history:
;    17-Nov-2014 - Roman Boutellier (FHNW), Initial release
;    30-Oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;    10-May-2016 - Laszlo I. Etesi (FHNW), updated file to use new data structures
;-

;+
; :description:
;      This function initializes the object. It is called automatically upon creation of the object.
;
; :Params:
;    FSW, in, required, type='stx_software_framework'
;       The stx_flight_software_simulator object to be plotted.
;
; :returns:
;
; :history:
;      17-Nov-2014 - Roman Boutellier (FHNW), Initial release
;-
function stx_flight_software_simulator_plotter::init, fsw, plot=plot, _extra=extra
  if ~isa(fsw,'stx_flight_software_simulator') then return, 0
  self.fsw = fsw
  
  return, self->stx_plotter::init(plot=plot, _extra = extra)
end

pro stx_flight_software_simulator_plotter::cleanup
  ; Call our superclass Cleanup method
  self->stx_plotter::Cleanup
end

pro stx_flight_software_simulator_plotter::plot, $
    detector_health = detector_health, $
    lightcurve = lightcurve, $
    archive_buffer = archive_buffer, $
    states = states, $
    all=all, $
    _extra=extra

  default, all, 0

  default, lightcurve, all
  default, detector_health, all
  default, archive_buffer, all
  default, states, all

  self.fsw->getproperty, current_bin=current_bin

  ; ensure there are data to plot
  if current_bin lt 8 then begin
    message, "skiped plotting due to insufficient data values, at least 8 itterations are required", /continue
;    if isa(current) then begin
;      void = plot([0,1], [0,1], /nodata, title="skiped plotting due to insufficient data values, at least 8 itterations are required",current=current)
;    end
    return
  endif

  if detector_health then begin
    self->stx_plotter::create_plot, function_name='_create_plot_health', key='windows_health', _extra=extra
    self->_update_plot_health
  end

  if lightcurve then begin
    self->stx_plotter::create_plot, function_name='_create_plot_lightcurve', key='windows_lightcurve', _extra=extra
    self->_update_plot_lightcurve
  end

  if archive_buffer then begin
    self->stx_plotter::create_plot, function_name='_create_plot_archive_buffer', key='windows_archive_buffer', _extra=extra
    self->_update_plot_archive_buffer
  end

  if states then begin
    self->stx_plotter::create_plot, function_name='_create_plot_states', key='windows_states', _extra=extra
    self->_update_plot_states
  end

end

function stx_flight_software_simulator_plotter::_create_plot_health, current=current, showxlabels=showxlabels, position=position, _extra=extra
  COMPILE_OPT IDL2, HIDDEN

  default, position, [0.1,0.1,0.7,1]
  default, showxlabels, 1
  
  self.fsw->getProperty, active_detectors=active_detectors, flare_flag = flare_flag
  
  flare_flag.type='stx_flare_flag'
  dhp = stx_detector_health_plott(active_detectors, flare_flag=flare_flag, current=current)
  
  (self.plots)["detector"] = dhp
  
  self->_registermouseevents, dhp.window  
  ;(self.plots)["windows_lightcurve"] = lc_0.window
  return, dhp.window
  
end

pro stx_flight_software_simulator_plotter::_update_plot_health  
  self.fsw->getProperty, active_detectors=active_detectors, reference_time=reference_time, flare_flag=flare_flag
  flare_flag.type = 'stx_flare_flag'
  
  dhp = (self.plots)["detector"]

  dhp->setdata, active_detectors, flare_flag=flare_flag, start_time=reference_time, current_time=current_time
 
  ;idl 8.3 hack showtext ist turned off somewhere
  ax = dhp.baseplot.AXES
  ax[3].showtext = 1

  self->_store_reset_position, dhp.baseplot
  
end

function stx_flight_software_simulator_plotter::_create_plot_archive_buffer, current=current, showxlabels=showxlabels, position=position, _extra=extra
  default, position, [0.1,0.1,0.7,1]
  default, showxlabels, 1

  var = plot([0,10],"b-", current=current, thick=2, /xstyle, /ystyle, ytitle="Variance / Total Counts", name="Variance", /ylog, _extra=extra,  position=position) ; current=window
  var->Refresh, /DISABLE
  self->_registermouseevents, var.window

  ax = var.AXES
  if showxlabels then begin
     ax[0].title = "Start Date: " + stx_time2any(self.fsw.start_time,/vms)
     ax[0].showtext = 1
  endif else begin
     ax[0].showtext = 0
  endelse

  ab = plot([0,1],"r", /overplot, name="AB acc. duration", thick=2)
  ab_dur = plot([0,1],"g-", /overplot, name="AB total counts", thick=2)
  ab_lt = plot([0,1],"m:", /overplot, name="AB trigger count", thick=2)

  leg =  legend(TARGET=[var, ab, ab_dur, ab_lt], /AUTO_TEXT_COLOR, TRANSPARENCY=50, HORIZONTAL_ALIGNMENT="right", position=[1,1])

  ; Store the different plots in the gui hash parameter of the self object
  (self.plots)["variance"] = [var, ab, ab_dur, ab_lt]
  
  ;(self.plots)["windows_archive_buffer"] = var.window
  return, var.window

end


pro stx_flight_software_simulator_plotter::_update_plot_archive_buffer
  COMPILE_OPT IDL2, HIDDEN

  self.fsw->getProperty,  start_time = start_time, $
                          current_time  = current_time, $
                          total_counts = total_counts, $
                          variance = variance, $
                          livetime = livetime, $
                          ql_data = ql_data

  ; Load the plots from the gui hash
  var_plots = (self.plots)["variance"]
  var_plots[0]->Refresh, /DISABLE
  lc_data = ql_data["stx_fsw_ql_lightcurve"]

  var_plots[0].xrange = [0, stx_time_diff(current_time,start_time)]
  var_plots[0]->setData, stx_time2any(variance.time_axis.time_end) - stx_time2any(start_time),  f_div(variance.data, double(reform(total(lc_data.ACCUMULATED_COUNTS,1))))

  ;Archive buffer
  ;duration
  ab_time_axis = stx_time2any(total_counts.time_axis.time_end) - stx_time2any(start_time)
  var_plots[1]->setData, ab_time_axis, total_counts.time_axis.duration
  ;total counts
  var_plots[2]->setData, ab_time_axis, total_counts.data
  ;LT
  ;var_plots[3]->setData, stx_time2any(livetime.time_axis.time_end) - stx_time2any(start_time),  livetime.data
  var_plots[3]->setData, ab_time_axis,  total(livetime.data, 2, /integer)

  var_plots[0]->Refresh
  self->_store_reset_position, var_plots[0]
end

function stx_flight_software_simulator_plotter::_create_plot_states, current=current, showxlabels=showxlabels, position=position, _extra=extra
  COMPILE_OPT IDL2, HIDDEN

  default, position, [0.1,0.1,0.7,1]

  default, showxlabels, 1
  st_0 = plot([0,10],"k-", current=current, yrange=[-1,8], thick=2, name="flare", ytitle="States", position=position, _extra=extra)
  self->_registermouseevents, st_0.window
  st_0->Refresh, /DISABLE

  ax = st_0.AXES
  if showxlabels then begin
     ax[0].title = "Start Date: " + stx_time2any(self.fsw.start_time,/vms)
     ax[0].showtext = 1
  endif else begin
     ax[0].showtext = 0
  endelse

  st_1 = plot([5,10], "c-", overplot=st_0, thick=2, name="rate control")
  ax[3].hide = 1

  pos_x = plot([0,-10],"rD-", current=st_0.window, ytitle="Flare Location", name="cfl x", position=position)
  pos_x->Refresh, /DISABLE
  self->_registermouseevents, pos_x.window
  pos_y = plot([0,1],"gD-", overplot=pos_x, name="cfl y")
  ax = pos_x.AXES
  ax[0].showtext = 0
  ax[0].hide = 1
  ax[1].hide = 1
  ax[2].hide = 1
  ax[3].title = "Flare Location"
  ax[3].showtext = 1

  leg =  legend(TARGET=[st_0,st_1,pos_x,pos_y], /AUTO_TEXT_COLOR, TRANSPARENCY=50, HORIZONTAL_ALIGNMENT="right", position=[1,1])

  (self.plots)["states"] = [st_0,st_1]
  (self.plots)["position"] = [pos_x, pos_y]
  
  ;(self.plots)["windows_states"] = st_0.window
  return, st_0.window

end


pro stx_flight_software_simulator_plotter::_update_plot_states
  COMPILE_OPT IDL2, HIDDEN

  self.fsw->getProperty,  flare_flag = flare_flag, $
                          rate_control = rate_control, $
                          current_time = current_time, $
                          start_time = start_time, $
                          coarse_flare_location = cfl

  ; Load the plots from the gui hash
  state_plots = (self.plots)["states"]
  pos_plots = (self.plots)["position"]

  state_plots[0]->Refresh, /DISABLE
  pos_plots[0]->Refresh, /DISABLE

    ;idl 8.3 hack showtext ist turned off somewhere
  ax = pos_plots[0].AXES
  ax[3].showtext = 1

  flare_flag_time = flare_flag.time_axis
  flare_flag = double(flare_flag.data ge 1)
  nf_i = where(flare_flag eq 0, nf_n)
  if nf_n gt 0 then flare_flag[nf_i]=!VALUES.d_nan

  time_range = [0, stx_time_diff(current_time,start_time)]

  state_plots[0].xrange = time_range
  state_plots[0]->setData, stx_time2any(flare_flag_time.time_end)- stx_time2any(start_time), flare_flag
  state_plots[1]->setData, stx_time2any(rate_control.time_axis.time_end)- stx_time2any(start_time),  rate_control.data

  pos_plots[0].xrange = time_range
  pos_plots[0]->setData, stx_time2any(cfl.time_axis.time_end) - stx_time2any(start_time),  cfl.data[*,0]

  cfl_range = minmax(cfl.data,/nan)
  cfl_range[0] = finite(cfl_range[0], /nan) ? -10 : cfl_range[0]
  cfl_range[1] = finite(cfl_range[1], /nan) ? 10 : cfl_range[1]

  pos_plots[0].yrange = cfl_range
  pos_plots[1]->setData, stx_time2any(cfl.time_axis.time_end) - stx_time2any(start_time),  cfl.data[*,1]
  pos_plots[1].yrange = pos_plots[0].yrange

  state_plots[0]->Refresh
  pos_plots[0]->Refresh
  
  self->_store_reset_position, state_plots[0]
  self->_store_reset_position, pos_plots[0]
end


function stx_flight_software_simulator_plotter::_create_plot_lightcurve, current=current, showxlabels=showxlabels, position=position, _extra=extra
  COMPILE_OPT IDL2, HIDDEN

  default, showxlabels, 1
  default, position, [0.1,0.1,0.7,1]
    
  self.fsw->getProperty, reference_time = reference_time, $
    current_time  = current_time, $
    stx_fsw_ql_lightcurve=lightcurve, $
    stx_fsw_m_background = bg, $
    /complete, /combine
  
  stx_plot_object = obj_new('stx_plot')


  lightcurve = stx_construct_lightcurve(from=lightcurve)
  background = stx_construct_lightcurve(from=bg)
  background.energy_axis = lightcurve.energy_axis
 
  lcp = stx_plot_object.create_stx_plot(lightcurve, /lightcurve, dimensions=[1260,350], position=[0.1,0.1,0.7,0.95])
  bgp = stx_plot_object.create_stx_plot(background, /background, /add_legend)
  
  lcp = stx_plot_object.stx_plots[lcp] 
  bgp = stx_plot_object.stx_plots[bgp] 
 
  ;bgp.legend.position = lcp.legend.position - [0,0.3]
  ;idl 8.3 hack showtext ist turned off somewhere
  ;ax = lcp.baseplot.AXES
  ;ax[3].title = bgp.data.unit
  ;ax[3].showtext = 1
  
  (self.plots)["lightcurve"] = lcp
  (self.plots)["background"] = bgp
  
  self->_registermouseevents, lcp.PLOT_WINDOW
  ;(self.plots)["windows_lightcurve"] = lc_0.window
  return, lcp.PLOT_WINDOW
end

pro stx_flight_software_simulator_plotter::_update_plot_lightcurve
  COMPILE_OPT IDL2, HIDDEN

   self.fsw->getProperty, reference_time = reference_time, $
    current_time  = current_time, $
    stx_fsw_ql_lightcurve=lightcurve, $
    stx_fsw_m_background = bg, $
    /complete, /combine
  
  lightcurve = stx_construct_lightcurve(from=lightcurve)
  background = stx_construct_lightcurve(from=bg)
  background.energy_axis = lightcurve.energy_axis
  lcp = (self.plots)["lightcurve"]
  
  lcp->setData, lightcurve, start_time = reference_time, current_time=current_time
  (self.plots)["background"]->setData, background, start_time = reference_time, current_time=current_time
  
  ;idl 8.3 hack showtext ist turned off somewhere
  ax = lcp.baseplot.AXES
  ax[3].showtext = 1
   
  self->_store_reset_position, lcp.baseplot
end

pro stx_flight_software_simulator_plotter::sync_plot, sel_graphics
     xrange = sel_graphics[0].xrange

     if (self.plots)->hasKey("lightcurve") then (self.plots)["lightcurve"].xrange = xrange
     if (self.plots)->hasKey("states") then (self.plots)["states", 0].xrange = xrange
     if (self.plots)->hasKey("position") then (self.plots)["position", 0].xrange = xrange
     if (self.plots)->hasKey("variance") then (self.plots)["variance", 0].xrange = xrange
     if (self.plots)->hasKey("detector") then (self.plots)["detector", 0].xrange = xrange
end


pro stx_flight_software_simulator_plotter__define
  compile_opt idl2

  define = {stx_flight_software_simulator_plotter, $
      fsw: obj_new(), $
      inherits stx_plotter $
  }

end
