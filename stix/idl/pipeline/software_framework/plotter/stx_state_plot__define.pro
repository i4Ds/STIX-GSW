
;+
; :file_comments:
;   The state plot object. It can be used to plot STIX state plots (e.g. rate control regime, coarse flare location).
;   
; :categories:
;   Plotting, GUI
;   
; :examples:
;
; :history:
;    06-May-2015 - Roman Boutellier (FHNW), Initial release
;-

;+
; :description:
;    This function initializes the object. It is called automatically upon creation of the object.
;
; :returns:
;
; :history:
;    06-May-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_state_plot::init
  
  ; Initialize the base object
  base_initialization = self->stx_line_plot::init()   
  return, base_initialization
end

;+
; :description:
; 	 describe the procedure.
;
; :returns:
;
; :history:
; 	 06-May-2015 - Roman Boutellier (FHNW), Initial release
; 	 23-Jan-2017 – ECMD (Graz), Now using x-axis title found in stx_line_plot_styles as default for all plots.
;                               Removed unneeded extra axis 
;
;-
pro stx_state_plot::plot, flare_flag=flare_flag, rate_control=rate_control, current_time=current_time, $
                          start_time=start_time, coarse_flare_location=coarse_flare_location, $
                          overplot=overplot, dimensions=dimensions, $
                          position=position, current_window=current_window, $
                          add_legend=add_legend, _extra=extra

  ; Load the default styles
  default_styles = self->_get_styles()
  
  ;Set the default styles
  default, showxlabels, default_styles.showxlabels
  default, position, default_styles.position
  default, dimensions, default_styles.dimension
  default, styles, default_styles.styles
  default, names, default_styles.names
  default, thick, default_styles.thick
  default, xstyle, default_styles.xstyle
  default, ystyle, default_styles.ystyle
  default, ytitle, default_styles.ytitle
  default, xtitle, default_styles.xtitle
  default, ylog, default_styles.ylog
  
    
  
  ; Plotting the rate control data. Therefore the keywords rate_control and start_time must be set
  if (keyword_set(rate_control) and keyword_set(start_time)) then begin
    self.rc_plot = *(self->stx_line_plot::_plot(stx_time2any(rate_control.time_axis.time_end)- stx_time2any(start_time), rate_control.RCR, $
                                                dimensions=dimensions, position=position, current=current_window, $
                                                styles=styles[1], xtitle=xtitle, ytitle=strjoin(ytitle," / "), names=names[1], xstyle=xstyle, ystyle=ystyle, ylog=ylog, $
                                                thick=thick, /overplot, _extra=extra))
  endif else begin
    self.rc_plot = *(self->stx_line_plot::_plot([0,0],[5,10], dimensions=dimensions, position=position, current=current_window, $
                                                styles=styles[1], xtitle=xtitle,ytitle=ytitle, names=names[1], xstyle=xstyle, ystyle=ystyle, ylog=ylog, $
                                                thick=thick, /overplot, _extra=extra))
  endelse
  
  ; Plotting the position data. Therefore the keywords coarse_flare_location and start_time must be set
  if (keyword_set(coarse_flare_location) and keyword_set(start_time)) then begin
    
      self.cfl_x_plot = *(self->stx_line_plot::_plot(stx_time2any(coarse_flare_location.time_axis.time_end) - stx_time2any(start_time), coarse_flare_location.X_POS, $
                                                    dimensions=dimensions, position=position, current=current_window, $
                                                    styles=styles[2], ytitle=strjoin(ytitle," / "), xtitle=xtitle, names=names[2], xstyle=xstyle, ystyle=ystyle, $
                                                    ylog=ylog, thick=thick, /overplot,  _extra=extra))
      self.cfl_y_plot = *(self->stx_line_plot::_plot(stx_time2any(coarse_flare_location.time_axis.time_end) - stx_time2any(start_time), coarse_flare_location.Y_POS, $
                                                    dimensions=dimensions, position=position, current=current_window, $
                                                    styles=styles[3],ytitle=strjoin(ytitle," / "), xtitle=xtitle, names=names[3], xstyle=xstyle, ystyle=ystyle, ylog=ylog, $
                                                    thick=thick, /overplot, _extra=extra))
  endif else begin
      self.cfl_x_plot = *(self->stx_line_plot::_plot([0,0],[0,-10], dimensions=dimensions, position=position, current=current_window, $
                                                    styles=styles[2], ytitle=strjoin(ytitle," / "), names=names[2], xstyle=xstyle, ystyle=ystyle, $
                                                    ylog=ylog, thick=thick, /overplot, _extra=extra))
      self.cfl_y_plot = *(self->stx_line_plot::_plot([0,0],[0,1], ytitle=strjoin(ytitle," / "), xtitle=xtitle, dimensions=dimensions, position=position, current=current_window, $
                                                    styles=styles[3], names=names[3], xstyle=xstyle, ystyle=ystyle, ylog=ylog, $
                                                    thick=thick, /overplot, _extra=extra))
  endelse
  
  ; Plotting the flare data. Therefore the keywords flare_flag and start_time must be set
  if (keyword_set(flare_flag) and keyword_set(start_time)) then begin
    flare_flag_time = flare_flag.time_axis
    flare_flag_signal = double(flare_flag.flare_flag ge 1)
    nf_i = where(flare_flag_signal eq 0, nf_n)
    if nf_n gt 0 then flare_flag_signal[nf_i]=!VALUES.d_nan

    self.flare_plot = *(self->stx_line_plot::_plot(stx_time2any(flare_flag_time.time_end)- stx_time2any(start_time), flare_flag_signal, $
      dimensions=dimensions, position=position, current=current_window,$
      styles=styles[0], ytitle=strjoin(ytitle," / "), xtitle=xtitle, names=names[0], xstyle=xstyle, ystyle=ystyle, $
      ylog=ylog, thick=thick+2, _extra=extra, /overplot, add_legend=add_legend))
  endif else begin
    self.flare_plot = *(self->stx_line_plot::_plot([0,0], [0,10], dimensions=dimensions, position=position, current=current_window,$
      styles=styles[0], ytitle=strjoin(ytitle," / "), xtitle=xtitle, names=names[0], xstyle=xstyle, ystyle=ystyle, $
      ylog=ylog, thick=thick+2, _extra=extra, /overplot, add_legend=add_legend))
  endelse
  
end

pro stx_state_plot::append_data, flare_flag=flare_flag, rate_control=rate_control, current_time=current_time, $
                                 start_time=start_time, coarse_flare_location=coarse_flare_location
                                  
  ; Show an error message in case not all the inputs are present
  if(~keyword_set(start_time) or ~keyword_set(current_time) or ~keyword_set(flare_flag) $
      or ~keyword_set(rate_control) or ~keyword_set(coarse_flare_location)) then message, 'All input keywords are required'
      
  ; Prepare the data
  flare_flag_time = flare_flag.time_axis
  flare_flag_signal = double(flare_flag.FLARE_FLAG ge 1)
  nf_i = where(flare_flag_signal eq 0, nf_n)
  if nf_n gt 0 then flare_flag_signal[nf_i]=!VALUES.d_nan
  
  time_range = [0, stx_time_diff(current_time,start_time)]
  
  ; Set the new data
  self.flare_plot->setdata, stx_time2any(flare_flag_time.time_end)- stx_time2any(start_time), flare_flag_signal
  self.rc_plot->setdata, stx_time2any(rate_control.time_axis.time_end)- stx_time2any(start_time), rate_control.RCR
  self.cfl_x_plot->setdata, stx_time2any(coarse_flare_location.time_axis.time_end) - stx_time2any(start_time), coarse_flare_location.X_POS
  self.cfl_y_plot->setdata, stx_time2any(coarse_flare_location.time_axis.time_end) - stx_time2any(start_time), coarse_flare_location.Y_POS
end

function stx_state_plot::_get_styles
  ; Get the default styles
  default_styles = stx_line_plot_styles(/state_plot)
  return, default_styles
end

pro stx_state_plot::delete
  if isa(self.flare_plot) then self.flare_plot->setdata, 0, 0
  if isa(self.rc_plot) then self.rc_plot->setdata, 0, 0
  if isa(self.cfl_x_plot) then self.cfl_x_plot->setdata, 0, 0
  if isa(self.cfl_y_plot) then self.cfl_y_plot->setdata, 0, 0
end

pro stx_state_plot__define
  compile_opt idl2
  
  define = {stx_state_plot, $
    flare_plot: obj_new(), $
    rc_plot: obj_new(), $
    cfl_x_plot: obj_new(), $
    cfl_y_plot: obj_new(), $
    inherits stx_line_plot $
  }
end