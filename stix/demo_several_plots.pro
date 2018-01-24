;+
; :description:
; 	 Generate data to plot.
;
; :returns:
;    {x: [x-data],
;     y: [y-data]}
;     
; :history:
; 	 22-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function get_data_for_plot
  sigma = float(round(randomu(seed)*100))/10
  array = randomn(seed,1024)*sigma + 50
  h = histogram(array, binsize=0.1, locations=hlocs)
  return, {x:hlocs,y:h}
end

;+
; :description:
; 	 Plot a line plot consisting of 12 lines at the given position within
; 	 the given widget_window. The data for the plot is generated within this
; 	 procedure before the plot is drawn.
;
; :Params:
;    position, in, required
;       Array containing the position of the plot ([x_low, y_low, y_high, y_high])
;    window, in, required
;       widget_window where the plot will be drawn
;    dimensions
;       Dimension of the widget_window
;
; :returns:
;    -
;
; :history:
; 	 22-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro plot_single_plot, position, window, dimensions
  ; Prepare the color array
  colors = ['blue', 'green', 'red', 'aqua', 'purple', 'orange', 'gold', 'fuchsia', 'maroon', 'navy', 'gray', 'lime']
  ; Get the data for the first plot
  data = get_data_for_plot()
  ; Draw the first plot
  p = plot(data.x, data.y, position=position, current=window, dimensions=dimensions, xrange=[0,100],yrange=[0,200])
  ; Draw the 11 other lines (using overplot)
  for i=0,11 do begin
    current_data = get_data_for_plot()
    p_i = plot(current_data.x, current_data.y, color=colors[i], position=position, current=window, dimensions=dimensions, /overplot)
  endfor
end

;+
; :description:
; 	 Plotting a total of 8 line plots consisting of 12 lines each.
; 	 
; :returns:
;    -
;
; :history:
; 	 22-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro demo_several_plots
tic
  ; Set the dimensions of the window
  dimensions_base = [800,600]
  dimensions_window = [800,550]
  ; Prepare the positions
  positions = [[0.15,0.66,0.29,0.9],[0.385,0.66,0.515,0.9],[0.61,0.66,0.75,0.9],[0.15,0.385,0.29,0.615],$
               [0.385,0.385,0.515,0.615],[0.61,0.385,0.75,0.615],[0.15,0.1,0.29,0.34],[0.385,0.1,0.515,0.34]]
  ; Prepare the tlb and all the widgets of the GUI
  base = widget_base(title='Test',xsize=dimensions_base[0], ysize=dimensions_base[1], /column)
  label = widget_label(base, value='Plotting 8 line plots consisting of 12 lines each.')
  window_plots = widget_window(base, xsize=dimensions_window[0], ysize=dimensions_window[1])
  ; Realize the GUI
  widget_control, base, /realize
  xmanager, 'test', base, /no_block
  
  ; Disable refreshing the window
  widget_control, window_plots, get_value=plot_window
  plot_window.refresh, /disable
  
  ; Plot the 8 line plots
  plot_window.select
  for j=0,7 do begin
    
    plot_single_plot, positions[*,j], window_plots, dimensions_window
    
  endfor
  
  ; Refresh the window
  plot_window.refresh
  toc
end