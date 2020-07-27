;+
; :file_comments:
;   The STIX plot object combines several STIX plots into one object and also
;   one plot window.
;   
; :categories:
;   plotting, GUI
;   
; :examples:
;
; :history:
;    07-Apr-2015 - Roman Boutellier (FHNW), Initial release
;-


function stx_plot::init, plot
  ; Initialize the list of plots
  self.stx_plots = list()
  
  ; In case a plot has been passed, add it to the list
  if arg_present(plot) then begin 
    self.stx_plots.add, plot
  endif
  
  return, 1
end

;+
; :description:
; 	 Inserts a new plot in the list of plots and returns its index.
;
; :Params:
;    plot, in, required, type='stx_base_plot'
;
; :returns:
;    index of inserted plot in the list
;    
; :history:
; 	 07-Apr-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_plot::add_stx_plot, plot
  ; Add the new plot at the end of the list
  self.stx_plots.add, plot
  
  ; Return the index of the newly added plot in the list
  return, self.stx_plots.count() - 1
end

pro stx_plot::delete
  foreach p, self.stx_plots do begin
    p->delete
  endforeach

end

function stx_plot::plot_object
  return, (*((self.stx_plots[0])._get_plot_list_ptr()))[0]
end

function stx_plot::getWindow
  return, (self.stx_plots)[0].getWindow()
end

function stx_plot::create_stx_plot, data, lightcurve=lightcurve, background=background, append=append, idx=idx, _extra=extra
  if keyword_set(lightcurve) then begin
    ; Check if the plot window already exists
    if (self.stx_plots.count() gt 0) then begin
      if keyword_set(append) then begin
        ; Get the correct stx plot
        plot_object = (self.stx_plots)[idx]
        plot_object.append_data, data, /histogram
      endif else begin
        p = obj_new('stx_lightcurve_plot')
        p.plot, data, /overplot, _extra=extra
        idx = self->add_stx_plot(p)
      endelse
    endif else begin
      p = obj_new('stx_lightcurve_plot')
      p.plot, data, position=[0.1,0.1,0.7,0.95], _extra=extra, /histogram
      idx = self->add_stx_plot(p)
    endelse
  endif else begin
    ; Plot the background
    if keyword_set(background) then begin
    ; Check if the plot window already exists
    if (self.stx_plots.count() gt 0) then begin
      if keyword_set(append) then begin
        ; Get the correct stx plot
        plot_object = (self.stx_plots)[idx]
        plot_object.append_data, data, /histogram
      endif else begin
        p = obj_new('stx_background_plot')
        p.plot, data, /overplot, _extra=extra, /histogram
        idx = self->add_stx_plot(p)
      endelse
    endif else begin
      p = obj_new('stx_background_plot')
      p.plot, data, position=[0.1,0.1,0.7,0.95], _extra=extra
      idx = self->add_stx_plot(p)
    endelse
  endif
  endelse
  
  return, idx
end

pro stx_plot__define
  compile_opt idl2
  
  define = {stx_plot, $
    stx_plots: list() $
  }
end