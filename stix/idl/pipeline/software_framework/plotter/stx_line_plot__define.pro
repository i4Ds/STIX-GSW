;+
; :file_comments:
;   The line plot base object. It can be used as a base object to plot any kind of
;   STIX line plots (e.g. lightcurves, background).
;   It provides a plot method and an append method.
;   The plot method can be used to plot any given data suitable for line plots (i.e. containing
;   data points for the x- and the y-axis).
;   The append method can be used after the plot method has been used to append new data to the
;   plotted lines.
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
function stx_line_plot::init
  
  ; Initialize the base object
  base_initialization = self->stx_base_plot::init() 
  
  return, base_initialization
end

;+
; :description:
; 	 Cleanup procedure
;
; :returns:
;
; :history:
; 	 28-Jul-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_line_plot::cleanup
  self->stx_base_plot::cleanup
end

function stx_line_plot::_plot, x_data, y_data, $
                        dimensions=dimensions, $
                        position=position, $
                        current=current, $
                        styles=styles, $
                        ytitle=ytitle, $
                        names=names, $
                        xstyle=xstyle, $
                        ystyle=ystyle, $
                        ylog=ylog, $
                        add_legend=add_legend, $
                        overplot=overplot, $
                        layout=layout, $
                        additional_text=additional_text, $
                        _extra=extra

  ; Check if x_data and y_data has been passed to the method
  if((~isvalid(x_data)) or (~isvalid(y_data))) then begin
    message, 'Invalid input: x data and y data has to be provided'
    return, -1
  endif
  ; Show an error message in case the dimensions of x_data and y_data do not agree
  dim_x = size(x_data, /dimensions)
  dim_y = size(reform(y_data), /dimensions)
  if(((size(dim_x,/dimensions))[0] eq 1) or ((size(dim_y,/dimensions))[0] eq 1)) then begin
    if(size(dim_x,/dimensions) ne size(dim_y,/dimensions)) then begin
      message, 'Invalid input: dimensions for x and y data do not agree'
      return, -1
    endif
  endif else begin
    if((dim_x[0] ne dim_y[0]) or (dim_x[1] ne dim_y[1])) then begin
      message, 'Invalid input: dimensions for x and y data do not agree'
      return, -1
    endif
  endelse
  
  ; In case the current keyword is set, select the according window
  if isvalid(current) then current.select
;  
  ; Get the default styling
  default_style = self->_get_styles_line_plot()
  
  default, styles, default_style.styles
  default, ytitle, default_style.ytitle
  default, names, default_style.names
  default, xstyle, default_style.xstyle
  default, ystyle, default_style.ystyle
  default, ylog, default_style.ylog
  default, position, default_style.position
;  if n_elements(layout) eq 0 then default, position, default_style.position
;  default, layout, [1,1,1]
  default, dimensions, default_style.dimension
  
  
  y_size = size(y_data)

  ; Prepare the pointer which stores the plots
  ; Default is n_dim (which represents the number of different plot lines) equals 1
  ; and n_elem (which represents the number of points of the plot line) equals dim_y[0]
  n_dim = 1
  if(size(dim_y,/n_elements) gt 1) then begin
    n_elem = dim_y[1]
  endif else begin
    n_elem = 1
  endelse
  ; In case more than one plot line will be plotted, adjust the numbers
  if y_size[0] eq 2 then begin
    n_dim = y_size[1]
    n_elem = y_size[2]
  endif
  ; Prepare the plot list of the base plot object
  self->stx_base_plot::_prepare_plot_list,number_plots=n_dim
    
  ; Plot the data
  for dim_idx = 0L, n_dim-1 do begin
    ; Create the plot (distinguish between the first plot and all overplots)
    if dim_idx eq 0 then begin
      if keyword_set(overplot) then begin
        ; Check if only one plot line will be plotted.
        if n_dim eq 1 then begin
          plot_object = plot(x_data, y_data, styles[dim_idx], ytitle=ytitle, name=names[dim_idx], xstyle=xstyle, $
                              ystyle=ystyle, ylog=ylog, dimensions=dimensions, position=position, layout=layout, current=current, /overplot, _extra = extra)
          ; Add the additional text
          if n_elements(additional_text) gt 0 then begin
            t = text(position, additional_text)
          endif
        endif else begin
          plot_object = plot(x_data[dim_idx,*], y_data[dim_idx,*], styles[dim_idx], ytitle=ytitle, name=names[dim_idx], xstyle=xstyle, $
                              ystyle=ystyle, ylog=ylog, dimensions=dimensions, position=position, layout=layout, current=current, /overplot, _extra = extra)
          ; Add the additional text
          if n_elements(additional_text) gt 0 then begin
            t = text(position, additional_text)
          endif
        endelse
      endif else begin
        ; Check if only one plot line will be plotted.
        if n_dim eq 1 then begin
          plot_object = plot(x_data, y_data, styles[dim_idx], ytitle=ytitle, name=names[dim_idx], xstyle=xstyle, $
                             ystyle=ystyle, ylog=ylog, dimensions=dimensions, position=position, layout=layout, current=current, _extra = extra)
          ; Add the additional text
          if n_elements(additional_text) gt 0 then begin
            t = text(position, additional_text)
          endif
        endif else begin
          plot_object = plot(x_data[dim_idx,*], y_data[dim_idx,*], styles[dim_idx], ytitle=ytitle, name=names[dim_idx], xstyle=xstyle, $
                             ystyle=ystyle, ylog=ylog, dimensions=dimensions, position=position, layout=layout, current=current, _extra = extra)
          ; Add the additional text
          if n_elements(additional_text) gt 0 then begin
            size_x = position[2] - position[0]
            size_y = position[3] - position[1]
            x_diff = size_x / 15
            y_diff = size_y / 10
            text_position = [position[0] + x_diff, position[3] - y_diff]
            t = text(text_position[0], text_position[1], additional_text, font_size=10)
          endif
        endelse
      endelse
                          
      ; Store the window
      self.plot_window = plot_object.window
  
      ; Set the retain variable of the window to 2 to prevent the plot from disappearing
      ; (e.g. when another window is moved on top of the plot window)
;      window, self.plot_window, retain=2
    endif else begin
      plot_object = plot(x_data[dim_idx,*], y_data[dim_idx,*], styles[dim_idx], /overplot, name=names[dim_idx], _extra=extra)
    endelse
    
    ; Store the plot object
    self->stx_base_plot::_add_plot_object,plot_object=plot_object,object_index=dim_idx 
  endfor

  ; Plot the legend in the same graphics window
  if keyword_set(add_legend) then self.legend = legend(target=self.plot_objects, /auto_text_color, transparency=50, horizontal_alignment="right", position=[0.95,0.95])
  plot_objects = self->stx_base_plot::_get_plot_list_ptr()
  return, plot_objects
end


function stx_line_plot::plot_objects 
  plot_objects = self->stx_base_plot::_get_plot_list_ptr()
  return, plot_objects
end


pro stx_line_plot::delete
  plot_objects_ptr = self->stx_base_plot::_get_plot_list_ptr()
  for p_idx=0L, n_elements(*plot_objects_ptr)-1 do begin
    p = (*plot_objects_ptr)[p_idx]
    if isa(p) then p->setdata, 0, 0
  endfor
end

pro stx_line_plot::_append, x_data, y_data, histogram=histogram, full_new_data=full_new_data
  ; Check if x_data and y_data has been passed to the method
  if((~isvalid(x_data)) or (~isvalid(y_data))) then begin
    message, 'Invalid input: x data and y data has to be provided'
    return
  endif
  ; Show an error message in case the dimensions of x_data and y_data do not agree
  dim_x = size(x_data, /dimensions)
  dim_y = size(reform(y_data), /dimensions)
  if(((size(dim_x,/dimensions))[0] eq 1) or ((size(dim_y,/dimensions))[0] eq 1)) then begin
    if(size(dim_x,/dimensions) ne size(dim_y,/dimensions)) then begin
      message, 'Invalid input: dimensions for x and y data do not agree'
      return
    endif
  endif else begin
    if((dim_x[0] ne dim_y[0]) or (dim_x[1] ne dim_y[1])) then begin
      message, 'Invalid input: dimensions for x and y data do not agree'
      return
    endif
  endelse
  
  
  y_size = size(y_data)
  ; Prepare the pointer which stores the plots
  ; Default is n_dim (which represents the number of different plot lines) equals 1
  ; and n_elem (which represents the number of points of the plot line) equals dim_y[0]
  n_dim = 1
  if(size(dim_y,/n_elements) gt 1) then begin
    n_elem = dim_y[1]
  endif else begin
    n_elem = 1
  endelse
  ; In case more than one plot line will be plotted, adjust the numbers
  if y_size[0] eq 2 then begin
    n_dim = y_size[1]
    n_elem = y_size[2]
  endif
  
  ; Get the list of plot objects
  plot_objects_ptr = self->stx_base_plot::_get_plot_list_ptr()
  
  ; Show an error message if the X dimensions disagree with the number of internal plots
  if (n_dim ne n_elements(*plot_objects_ptr)) then message, 'X dimension disagrees with number of internal plots'
  
  ; Append the data
  for p_idx=0L, n_elements(*plot_objects_ptr)-1 do begin
    (*plot_objects_ptr)[p_idx]->getdata, old_x, old_y
;    new_x = self->stx_base_plot::_line_data2histogram(reform(x_out[p_idx,*]),/test_first,/x)
    if keyword_set(histogram) then begin
      new_x = self->_line_data2histogram(reform(x_data[p_idx,*]),/test_first,/x)
      new_y = self->_line_data2histogram(reform(y_data[p_idx, *]), /test_first)
    endif else begin
      if keyword_set(full_new_data) then begin
        new_x = x_data
        new_y = y_data
      endif else begin
        ; Check if only one plot line will be plotted.
        if n_dim eq 1 then begin
          new_x = [old_x,x_data]
          new_y = [old_y,y_data]
        endif else begin
          new_x = [old_x,reform(x_data[p_idx,*])]
          new_y = [old_y,reform(y_data[p_idx,*])]
        endelse
      endelse
    endelse
    (*plot_objects_ptr)[p_idx]->setdata, new_x, new_y
  endfor
end


;+
; :description:
; 	 Creates the legend and plots it in the window with the given id
; 	 
; :Keywords:
;    window_id
;
; :returns:
;
; :history:
; 	 07-Aug-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_line_plot::_plot_legend, window_id=window_id
  widget_control, window_id,get_value=owidget
;  owidget.select
  self.legend = legend(target=self.plot_objects, /auto_text_color, transparency=50, horizontal_alignment="right", position=[0.95,0.95], window=owidget)
  return, self.legend
end

function stx_line_plot::_get_styles_line_plot
  return, stx_line_plot_styles(/default_line)
end

;+
; :description:
;    Extract the data from a STIX lightcurve object.
;
; :Params:
;    light_curve, in, required, type='stx_lightcurve'
;       The STIX lightcurve object to extract the data from.
;
; :Keywords:
;    x_out, out, required
;       This variable will hold the data for the x axis.
;    y_out, out, required
;       This variable will hold the data for the y axis.
;    e_axis_out, out, required
;       This variable will hold the edge values of the energy axis
;
; :returns:
;
; :history:
;    04-May-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_line_plot::_lc2array, light_curve, x_out=x_out, y_out=y_out, e_axis_out=e_axis_out
  ; Set the y_out data
  

  n_dim = n_elements(light_curve.energy_axis.mean)
  n_elem = n_elements(light_curve.time_axis.duration)
  
  y_out = reform(light_curve.data, n_dim, n_elem)
  
  x_out = dblarr(n_dim, n_elem)
  for i=0, n_dim-1 do x_out[i,*] = stx_time2any(light_curve.time_axis.time_end) - stx_time2any(light_curve.time_axis.time_start[0])
  
  ; Set the energy axis data
  e_axis_out = light_curve.energy_axis.edges_1
end

function stx_line_plot::_line_data2histogram, line, test_first=test_first, x=x
  if keyword_set(test_first) && self.idl_supports_histogram_plot then return, line
  if n_elements(line) eq 1 then if keyword_set(x) then line = [line, 2*line] else line = [line, line]
  if keyword_set(x) then return, [(shift(rebin(line, n_elements(line)*2, /sample),1))[2:-1], line[-1]]
  return, [(shift(rebin(line, n_elements(line)*2, /sample),1))[1:-2], line[-1]]
end

pro stx_line_plot__define
  compile_opt idl2
  
  define = {stx_line_plot, $
    inherits stx_base_plot $
  }
end