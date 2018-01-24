;+
; :file_comments:
;   The archive buffer plot object. It can be used to plot STIX variance and total counts plots.
;   
; :categories:
;   Plotting, GUI
;   
; :examples:
;
; :history:
;    04-May-2015 - Roman Boutellier (FHNW), Initial release
;-

;+
; :description:
;    This function initializes the object. It is called automatically upon creation of the object.
;
; :returns:
;
; :history:
;    04-May-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_archive_buffer_plot::init
  
  ; Initialize the base object
  base_initialization = self->stx_line_plot::init()   
  return, base_initialization
end

;+
; :description:
;    
;
; :Params:
;    
;
; :returns:
;
; :history:
;    05-May-2015 - Roman Boutellier (FHNW), Initial release
;    23-Jan-2017 – ECMD (Graz), Now using x-axis title found in stx_line_plot_styles as default for all plots.
;-
pro stx_archive_buffer_plot::plot, start_time = start_time, current_time  = current_time, $
                                    lc_total_counts = lc_total_counts, variance = variance, $
                                    archive_buffer = archive_buffer,$
                                    overplot=overplot, dimensions=dimensions, $
                                    position=position, current_window=current_window, $
                                    add_legend=add_legend, _extra=extra
  
  ; Get the default styles
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
  
  ; Plotting variance data. Therefore the keywords variance, current_time and start_time must be set.
  ; Otherwise use default data.
  if (keyword_set(variance) and keyword_set(start_time) and keyword_set(current_time) and keyword_set(lc_total_counts)) then begin
   
    
    self.variance_plot = *(self->stx_line_plot::_plot(stx_time2any(variance.time_axis.time_end) - stx_time2any(start_time), $
                                f_div(variance.VARIANCE, lc_total_counts.data), $
                                dimensions=dimensions, position=position, current=current_window, styles=styles[0], ytitle=ytitle, xtitle=xtitle, names=names[0], $
                                xstyle=xstyle, ystyle=ystyle, ylog=ylog, thick=thick, _extra=extra, /histogram))
  endif else begin
    self.variance_plot = *(self->stx_line_plot::_plot([0,0], [0,10], dimensions=dimensions, position=position, current=current_window, styles=styles[0], ytitle=ytitle, xtitle=xtitle, names=names[0], $
                                  xstyle=xstyle, ystyle=ystyle, ylog=ylog, thick=thick, _extra=extra, /histogram))
  endelse
  
  ; Plotting archive buffer data. Therefore the keywords start_time, total_counts and livetime must be set.
  ; Otherwise use default data.
  if keyword_set(archive_buffer) and keyword_set(start_time) then begin
    ab_time_axis = stx_time2any(archive_buffer.time_axis.time_end) - stx_time2any(start_time)
    
    ; Duration
    self.duration_plot = *(self->stx_line_plot::_plot(ab_time_axis, archive_buffer.time_axis.duration, dimensions=dimensions, position=position, $
                                                      styles=styles[1], names=names[1], ytitle=ytitle, xtitle=xtitle, thick=thick, /overplot, _extra=extra, /histogram))
    ; Total counts
    self.total_counts_plot = *(self->stx_line_plot::_plot(ab_time_axis, archive_buffer.total_counts, dimensions=dimensions, position=position, $
                                                          styles=styles[2], names=names[2], ytitle=ytitle, xtitle=xtitle, thick=thick, /overplot, _extra=extra, /histogram))
    ; LT
    ; Check if the legend should be added
    if keyword_set(add_legend) then begin
      self.trigger_plot = *(self->stx_line_plot::_plot(ab_time_axis, total(archive_buffer.TRIGGERS.TRIGGERS, 1, /preserve), dimensions=dimensions, position=position, styles=styles[3], names=names[3], $
                                                ytitle=ytitle, xtitle=xtitle, thick=thick, /overplot, /add_legend, _extra=extra, /histogram))
    endif else begin
      self.trigger_plot = *(self->stx_line_plot::_plot(ab_time_axis, total(archive_buffer.TRIGGERS.TRIGGERS, 1, /preserve), dimensions=dimensions, position=position, $
                                                 styles=styles[3], names=names[3], ytitle=ytitle, xtitle=xtitle, thick=thick, /overplot, _extra=extra, /histogram))
    endelse
  endif else begin
    ; Duration
    self.duration_plot = *(self->stx_line_plot::_plot([0,0], [0,1], dimensions=dimensions, position=position, styles=styles[1], $
                                                    names=names[1], ytitle=ytitle, xtitle=xtitle, thick=thick, /overplot, _extra=extra, /histogram))
    ; Total counts
    self.total_counts_plot = *(self->stx_line_plot::_plot([0,0], [0,1], dimensions=dimensions, position=position, styles=styles[2], $
                                                          names=names[2], ytitle=ytitle, xtitle=xtitle, thick=thick, /overplot, _extra=extra, /histogram))
    ; LT
    ; Check if the legend should be added
    if keyword_set(add_legend) then begin
      self.trigger_plot = *(self->stx_line_plot::_plot([0,0], [0,1], dimensions=dimensions, position=position, styles=styles[3], $
                                                names=names[3], ytitle=ytitle, xtitle=xtitle, thick=thick, /overplot, /add_legend, _extra=extra,/histogram))
    endif else begin
      self.trigger_plot = *(self->stx_line_plot::_plot([0,0], [0,1], dimensions=dimensions, position=position, styles=styles[3], $
                                                names=names[3], ytitle=ytitle, xtitle=xtitle, thick=thick, /overplot, _extra=extra,/histogram))
    endelse
  endelse
end

pro stx_archive_buffer_plot::delete
  if isa(self.variance_plot) then self.variance_plot->setdata, 0, 0
  if isa(self.duration_plot) then self.duration_plot->setdata, 0, 0
  if isa(self.total_counts_plot) then self.total_counts_plot->setdata, 0, 0
  if isa(self.trigger_plot) then self.trigger_plot->setdata, 0, 0
end

pro stx_archive_buffer_plot::append_data, start_time = start_time, current_time  = current_time, $
                                    lc_total_counts = lc_total_counts, variance = variance, $
                                    archive_buffer = archive_buffer
  
  ; Show an error message in case not all the inputs are present
  if(~keyword_set(start_time) or ~keyword_set(current_time) or ~keyword_set(lc_total_counts) $
      or ~keyword_set(variance) or ~keyword_set(archive_buffer)) then message, 'All input keywords are required'
  
  
  ; Get all the data and put it into an array
  ; Variance data
  variance_x = stx_time2any(variance.time_axis.time_end) - stx_time2any(start_time)
  variance_y = f_div(variance.VARIANCE, lc_total_counts.data)
  ;Duration
  duration_x = stx_time2any(archive_buffer.time_axis.time_end) - stx_time2any(start_time)
  duration_y = archive_buffer.time_axis.duration
  ; Total counts
  total_counts_x = duration_x
  total_counts_y = archive_buffer.total_counts
  ; LT
  lt_x = duration_x
  lt_y = total(archive_buffer.TRIGGERS.TRIGGERS, 1, /preserve)
  
  ; Prepare the x_data_array and the y_data_array
;  x_data_array = [variance_x, duration_x, total_counts_x, lt_x]
;  y_data_array = [variance_y, duration_y, total_counts_y, lt_y]
  
  ; Append the data
  self.variance_plot->setdata, variance_x, variance_y
  self.duration_plot->setdata, duration_x, duration_y
  self.total_counts_plot->setdata, total_counts_x, total_counts_y
  self.trigger_plot->setdata, lt_x, lt_y
end

function stx_archive_buffer_plot::_get_styles
  ; Get the default styles
  default_styles = stx_line_plot_styles(/archive_buffer)
  return, default_styles
end

pro stx_archive_buffer_plot__define
  compile_opt idl2
  
  define = {stx_archive_buffer_plot, $
    variance_plot: obj_new(), $
    duration_plot: obj_new(), $
    total_counts_plot: obj_new(), $
    trigger_plot: obj_new(), $
    inherits stx_line_plot $
  }
end