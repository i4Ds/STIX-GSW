
;+
; :file_comments:
;   The spectra plot object. It can be used to plot STIX spectra.
;   
; :categories:
;   Plotting, GUI
;   
; :examples:
;
; :history:
;    03-Jul-2017 - Nicky Hochmuth (FHNW), Initial release
;-

;+
; :description:
;    This function initializes the object. It is called automatically upon creation of the object.
;
; :returns:
;
; :history:
;     03-Jul-2017 - Nicky Hochmuth (FHNW), Initial release
;-
function stx_spectra_plot::init
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
; 	  03-Jul-2017 - Nicky Hochmuth (FHNW), Initial release
;
;-
pro stx_spectra_plot::plot, spectra, detectors, current_time=current_time, duration=duration, $
                          overplot=overplot, dimensions=dimensions, $
                          position=position, current_window=current_window, $
                          add_legend=add_legend, _extra=extra
  
  default, current_time, stx_time()
  default, duration, 4 
                          
  ; Load the default styles
  default_styles = self->_get_styles()
  
  ;Set the default styles
  default, showxlabels, default_styles.showxlabels
  default, position, default_styles.position
  default, dimensions, default_styles.dimension
  default, styles, default_styles.styles
  default, xstyle, default_styles.xstyle
  default, ystyle, default_styles.ystyle
  default, ytitle, default_styles.ytitle
  default, xtitle, default_styles.xtitle
  default, ylog, default_styles.ylog
  
  
  plot_names =  default_styles.NAME_PREFIX + trim(fix(detectors)+1)
  
  spectra = transpose(spectra)
  
  n_d = n_elements(spectra[*,0])
  n_e = n_elements(spectra[0,*])
  
  y_out = transpose(reform(reproduce(transpose(indgen(n_e)),n_d)))
  
  if ~isa(current) then begin
    current = window(dimensions=dimensions)
  endif
  
  
  title = [ "Time: "+stx_time2any(current_time, /stime ), $
            "Duration: " + trim(fix(duration)) + " [s]", $
            "tot Counts: " + trim(total(spectra, /preserve_type))]
  
  void = self->stx_line_plot::_plot(y_out, spectra, dimensions=dimension, position=position, current=current, styles=styles, $
                    ytitle=ytitle, xtitle=xtitle, names=plot_names, xstyle=xstyle, title=title , ystyle=ystyle, ylog=ylog, /add_legend, /overplot, _extra=extra)
  
end

function stx_spectra_plot::_get_styles
  ; Get the default styles
  default_styles = stx_line_plot_styles(/spectra)
  return, default_styles
end



pro stx_spectra_plot__define
  compile_opt idl2
  
  define = {stx_spectra_plot, $
    inherits stx_line_plot $
  }
end