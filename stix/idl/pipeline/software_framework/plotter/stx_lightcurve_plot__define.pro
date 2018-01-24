;+
; :file_comments:
;   The lightcurve plot object. It can be used to plot STIX lightcurves.
;   Therefore STIX lightcurve objects are consumed and a plot is created out
;   of the data.
;   
; :categories:
;   Plotting, GUI
;   
; :examples:
;
; :history:
;    30-Mar-2015 - Roman Boutellier (FHNW), Initial release
;-

;+
; :description:
;    This function initializes the object. It is called automatically upon creation of the object.
;
; :returns:
;
; :history:
; 	 30-Mar-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_lightcurve_plot::init
  
  ; Initialize the base object
  base_initialization = self->stx_line_plot::init()   
  return, base_initialization
end


;+
; :description:
; 	 Plots the data of a stx_lightcurve object.
;
; :Params:
;    stx_lightcurve_object, in, required
;
; :returns:
;
; :history:
; 	 30-Mar-2015 - Roman Boutellier (FHNW), Initial release
;    23-Jan-2017 – ECMD (Graz), Now using x-axis title found in stx_line_plot_styles as default for all plots.
;-
pro stx_lightcurve_plot::plot, lightcurve_object, overplot=overplot, dimension=dimension, position=position, current=current, add_legend=add_legend, _extra=extra
  ; Show an error message in case the input is not a lightcurve object
  if(~ppl_typeof(lightcurve_object, compareto='stx_lightcurve', /raw)) then message, 'Invalid input: Only stx_lightcurve allowed'
  
;  ; In case the current keyword is set, select the according window
;  if isvalid(current) then current.select
  
  ; Extract the data
  self->stx_line_plot::_lc2array, lightcurve_object, x_out=x_out, y_out=y_out, e_axis_out=e_axis_out
  
  ; Get the default styling
  default_style = self->_get_styles()
  
  default, position, default_style.position
  default, dimension, default_style.dimension
  default, ytitle, lightcurve_object.unit
  default, xtitle, default_style.xtitle

  ; Check if y data is present
  if isvalid(y_out) then begin
    ; Get the dimensions
    dim_y = size(y_out,/dimensions)
    n_dim = dim_y[0]
    n_elem = dim_y[1]
    
    ; Check if the x data is present. If not, create it, otherwise use it.
    if (~isvalid(x_out)) then begin
      x_out = lonarr(n_dim, n_elem)
      for x_idx = 0L, n_dim-1 do x_out[x_idx,*] = lindgen(n_elem)
    endif else if (n_elements(x_out) ne n_elements(y_out)) then message, 'X and Y elment counts disagree'
    
    ; Prepare variables for the plot names
    plot_names = make_array(n_dim,/string)
    precision = '(F6.2)'
    for dim_idx = 0L, n_dim-1 do begin
      ; Prepare the plot names
      plot_names[dim_idx] = default_style.name_prefix + ' ' + string(lightcurve_object.energy_axis.low[dim_idx], precision) + ' - ' + string(lightcurve_object.energy_axis.high[dim_idx], precision) + 'keV'
    endfor
    
    ; Plot the data
    if keyword_set(overplot) then begin
      ; Plot the legend if needed
      if keyword_set(add_legend) then begin
        void = self->stx_line_plot::_plot(x_out, y_out, dimensions=dimension, position=position, current=current, styles=default_style.styles, $
                    ytitle=ytitle,  xtitle=xtitle, names=plot_names, xstyle=default_style.xstyle, $
                    ystyle=default_style.ystyle, ylog=default_style.ylog, /add_legend, /overplot, _extra=extra)
      endif else begin
        void = self->stx_line_plot::_plot(x_out, y_out, dimensions=dimension, position=position, current=current, styles=default_style.styles, $
                    ytitle=ytitle, xtitle=xtitle, names=plot_names, xstyle=default_style.xstyle, $
                    ystyle=default_style.ystyle, ylog=default_style.ylog, /overplot, _extra=extra)
      endelse
    endif else begin
      ; Plot the legend if needed
      if keyword_set(add_legend) then begin
        void = self->stx_line_plot::_plot(x_out, y_out, dimensions=dimension, position=position, current=current, styles=default_style.styles, $
                    ytitle=ytitle,  xtitle=xtitle, names=plot_names, xstyle=default_style.xstyle, $
                    ystyle=default_style.ystyle, ylog=default_style.ylog, /add_legend, _extra=extra)
      endif else begin
        void = self->stx_line_plot::_plot(x_out, y_out, dimensions=dimension, position=position, current=current, styles=default_style.styles, $
                    ytitle=ytitle, xtitle=xtitle,  names=plot_names, xstyle=default_style.xstyle, $
                    ystyle=default_style.ystyle, ylog=default_style.ylog, _extra=extra)
      endelse
    endelse
  endif
;  
;        ; Set the retain variable of the window to 2 to prevent the plot from disappearing
;        ; (e.g. when another window is moved on top of the plot window)
;;        window, self.plot_window, retain=2
end

pro stx_lightcurve_plot::append_data, lightcurve_object, histogram=histogram
  ; Show an error message in case the input is not a lightcurve object
  if(~ppl_typeof(lightcurve_object, compareto='stx_lightcurve', /raw)) then message, 'Invalid input: Only stx_lightcurve allowed'
  
  ; Extract the data
  self->stx_line_plot::_lc2array, lightcurve_object, x_out=x_out, y_out=y_out, e_axis_out=e_axis_out
  
  ; Show an error message if the x_out and y_out dimensions disagree
  if (n_elements(x_out) ne n_elements(y_out)) then message, 'X and Y element counts disagree'
  
  ; Append the data
  self->stx_line_plot::_append, x_out, y_out, histogram=histogram
end

function stx_lightcurve_plot::_get_styles
  ; Get the default styles
  default_styles = stx_line_plot_styles(/lightcurve)
  return, default_styles
end

pro stx_lightcurve_plot__define
  compile_opt idl2
  
  define = {stx_lightcurve_plot, $
    inherits stx_line_plot $
  }
end