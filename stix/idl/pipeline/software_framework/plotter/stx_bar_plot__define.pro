;+
; :file_comments:
;   The bar plot base object. It can be used as a base object to plot any kind of
;   STIX bar plots (e.g. health plot).
;   It provides a plot method and an append method.
;   The plot method can be used to plot any given data suitable for bar plots.
;   The append method can be used after the plot method has been used to append new data to the
;   plotted bars.
;   
; :categories:
;   Plotting, GUI
;   
; :examples:
;
; :history:
;    06-May-2015 - Roman Boutellier (FHNW), Initial release
;    07-May-2015 - Roman Boutellier (FHNW), Added first version of logic (created by Marek Steslicki (SRC Wro))
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
function stx_bar_plot::init
  
  ; Initialize the base object
  base_initialization = self->stx_base_plot::init() 
  
  return, base_initialization
end

function stx_bar_plot::_plot, min_x, max_x, data_beginnings, data_ends, $
                        dimensions=dimensions, $
                        position=position, $
                        current=current, $
                        styles=styles, $
                        axis_style = axis_style, $
                        ytitle=ytitle, $
                        names=names, $
                        add_legend=add_legend, $
                        overplot=overplot, $
                        _extra=extra
                        
  ; Get the default styles and set them
  default_styles = self._get_styles_bar_plot()
  default, dimensions, default_styles.dimensions
  default, position, default_styles.position
  default, styles, default_styles.styles
  default, axis_style, default_styles.axis_style
  default, ytitle, default_styles.ytitle
  default, names, default_styles.names
  default, fill_level, default_styles.fill_level
  default, linestyle, default_styles.linestyle
  
  ; Check if min_x, max_x, data_beginnings and data_ends have been passed to the method
  if((~isvalid(min_x)) or (~isvalid(max_x)) or (~isvalid(data_beginnings)) or (~isvalid(data_ends))) then begin
    message, 'Invalid input: minimal and maximal x-axis values and data beginnings and endings must be entered'
    return, -1
  endif

  ; Prepare the plot list of the base plot object
  self->stx_base_plot::_prepare_plot_list,number_plots=1

  ; Store the x range
  self.x_range = [min_x,max_x]
  
  ; Calculate the values needed to plot the bars
  ; For each bar, a total of 4 x- and y-values are created
  ; Those values are then used as edge-points of the bars
  n_b=n_elements(data_beginnings)
  n_e=n_elements(data_ends)
  data_x=dblarr(4*min(n_b,n_e))
  data_y=intarr(4*min(n_b,n_e))
  for i=0l,min(n_b,n_e)-1 do begin
      data_x[4*i]=data_beginnings[i]
      data_x[4*i+1]=data_beginnings[i]
      data_x[4*i+2]=data_ends[i]
      data_x[4*i+3]=data_ends[i]
      data_y[4*i]=0
      data_y[4*i+1]=1
      data_y[4*i+2]=1
      data_y[4*i+3]=0
  endfor
    
  ; Store the created data in the object
  d_x=list()
  d_x.add,data_x,/extract
  self.data_x=d_x
  d_y=list()
  d_y.add,data_y,/extract
  self.data_y=d_y

  ; Create the bar plot
  ; Therefore first prepare the data
  plot_data_x = self.data_x.toarray()
  plot_data_y = self.data_y.toarray()
  valid_ind = where(plot_data_x ge self.x_range[0] and plot_data_x le self.x_range[1])
  if plot_data_x[valid_ind[valid_ind[0]]] eq 1 then valid_ind = [valid_ind[0] - 1, valid_ind]
  nmbr_valid_ind = n_elements(valid_ind)
  if plot_data_x[valid_ind[nmbr_valid_ind-1]] eq 1 then valid_ind = [valid_ind, valid_ind[nmbr_valid_ind-1] + 1]
  
  ; In case the current keyword is set, select the according window
  if isvalid(current) then current.select
  
  plot_object = plot(data_x[valid_ind], data_y[valid_ind], $
                      dimensions = dimensions, $
                      position = position, $
                      current = current, $
                      axis_style = axis_style, $
                      /fill_background, $
                      fill_color = styles[0], $
                      color = styles[0], $
                      fill_level = fill_level, $
                      linestyle = linestyle, $
                      xrange = [self.x_range[0], self.x_range[1]], $
                      yrange = [0,1], $
                      overplot = overplot)
                      
  ; Store the plot object
  self->stx_base_plot::_add_plot_object,plot_object=plot_object,object_index=0
  
  return, plot_object
end

function stx_bar_plot::_get_styles_bar_plot
  return, stx_bar_plot_styles(/default_styles)
end

pro stx_bar_plot__define
  compile_opt idl2
  
  define = {stx_bar_plot, $
    data_x: list(), $
    data_y: list(), $
    x_range: [0.d, 0.d], $
    inherits stx_base_plot $
  }
end