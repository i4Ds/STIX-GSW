;+
; :file_comments:
;   This is the base class for the different STIX plots. All plots (e.g. lightcurve plot) inherit
;   this class.
;   
; :categories:
;   Plotting, GUI
;   
; :examples:
;
; :history:
;    30-Mar-2015 - Roman Boutellier (FHNW), Initial release
;    07-Apr-2015 - Roman Boutellier (FHNW), - Added idl_supports_histogram_plot field to the object
;                                           - During init this field is set
;-


;+
; :description:
;    This function initializes the object. It is called automatically upon creation of the object.
;
; :returns:
;   1 in case of correct initialization
;   
; :history:
; 	 30-Mar-2015 - Roman Boutellier (FHNW), Initial release
;    07-Apr-2015 - Roman Boutellier (FHNW), - Setting idl_supports_histogram_plot field
;-
function stx_base_plot::init, base_window=base_window
  ; Store the plot window id in case it has been passed
;  if arg_present(plot_window_id) then begin
;    self.base_window = base_window
;  endif else begin
;    if self.base_window ne !NULL then begin
;      self.base_window = window()
;    endif
;  endelse
;  
;  self.base_window.select

  ; Check if IDL supports HISTOGRAM
  if float(!VERSION.release) ge 8.3 then self.idl_supports_histogram_plot=1L else self.idl_supports_histogram_plot=0L
  
  return, 1
end

pro stx_base_plot::cleanup
  if obj_valid(self.legend) then obj_destroy, self.legend
  if obj_valid(self.plot_window) then obj_destroy, self.plot_window
  if obj_valid(self.base_window) then obj_destroy, self.base_window
  if ptr_valid(self.plot_objects) then begin
    plot_array = *self.plot_objects
    for ind=0,size(plot_array,/n_elements)-1 do begin
      obj_destroy, plot_array[ind]
    endfor
    ptr_free, self.plot_objects
  endif
  obj_destroy, self
end

;+
; :description:
; 	 The plot routine plots the given data.
; 	 Must be overwritten by the subclass.
;
; :Keywords:
;
; :returns:
;
; :history:
; 	 30-Mar-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_base_plot::_plot, x, y, _extra=extra

end

;+
; :description:
; 	 Prepare the list of plot objects by creating a new pointer, pointing to an array
; 	 of object references with the given number of (empty) entries.
;
; :Keywords:
;    number_plots, in, required, type='Long'
;
; :returns:
;    -
;
; :history:
; 	 01-Apr-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_base_plot::_prepare_plot_list, number_plots=number_plots
  self.plot_objects = ptr_new(objarr(number_plots))
end

;+
; :description:
; 	 Adds the given plot object at the given index to the list of plot objects.
;
; :Keywords:
;    plot_object, in, required, type='plot'
;    
;    object_index, in, required, type='Long'
;
; :returns:
;    -
;
; :history:
; 	 01-Apr-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_base_plot::_add_plot_object, plot_object=plot_object, object_index=object_index
  (*self.plot_objects)[object_index] = plot_object
end

;+
; :description:
; 	 Get the pointer to the list of plot objects.
;
; :returns:
;    A pointer to the list of plot objects.
;    
; :history:
; 	 01-Apr-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_base_plot::_get_plot_list_ptr
  return, self.plot_objects
end

;;+
;; :description:
;;    Extract the data from a STIX lightcurve object.
;;
;; :Params:
;;    light_curve, in, required, type='stx_lightcurve'
;;       The STIX lightcurve object to extract the data from.
;;
;; :Keywords:
;;    x_out, out, required
;;       This variable will hold the data for the x axis.
;;    y_out, out, required
;;       This variable will hold the data for the y axis.
;;    e_axis_out, out, required
;;       This variable will hold the edge values of the energy axis
;;
;; :returns:
;;
;; :history:
;;    31.03.2015 - Roman Boutellier (FHNW), Initial release
;;-
;pro stx_base_plot::_lc2array, light_curve, x_out=x_out, y_out=y_out, e_axis_out=e_axis_out
;  ; Set the y_out data
;  y_out = light_curve.data
;  
;  ; Set the x_out data
;  dim_y = size(y_out,/dimensions)
;  n_dim = dim_y[0]
;  n_elem = dim_y[1]
;  x_out = dblarr(n_dim, n_elem)
;  for i=0, n_dim-1 do x_out[i,*] = stx_time2any(light_curve.time_axis.time_end) - stx_time2any(light_curve.time_axis.time_start[0])
;  
;  ; Set the energy axis data
;  e_axis_out = light_curve.energy_axis.edges_1
;end
;
;function stx_base_plot::_line_data2histogram, line, test_first=test_first, x=x
;  if keyword_set(test_first) && self.idl_supports_histogram_plot then return, line
;  if keyword_set(x) then return, [(shift(rebin(line, n_elements(line)*2, /sample),1))[2:-1], line[-1]]
;  return, [(shift(rebin(line, n_elements(line)*2, /sample),1))[1:-2], line[-1]]
;end

function stx_base_plot::getWindow
  return, self.plot_window
end

pro stx_base_plot__define
  compile_opt idl2
  
  define = {stx_base_plot, $
    plot_objects: ptr_new(), $
    legend: obj_new(), $
    plot_window: obj_new(), $
    base_window: obj_new(), $
    idl_supports_histogram_plot: 0L $
  }
end