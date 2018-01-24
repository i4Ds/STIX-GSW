function stx_plotter::init, fsw, plot=plot, _extra=extra
  ; Initialize the object fields
  self.plots = hash()
  self.reset_positions = hash() 
  self.idlsupports_histogram_plot = float(!Version.Release) ge 8.22
  
  if keyword_set(plot) then begin
      self->plot, _extra=extra
  endif
  return, 1
end

pro stx_plotter::cleanup
  
  foreach gui, self.plots->values() do begin
    if isa(gui,"GRAPHICSWIN") then gui.close
    obj_destroy, gui
  end
  
  obj_destroy, self.plots
  obj_destroy, self.reset_positions
end

pro stx_plotter::plot, all=all
  default, all, 0
end

pro stx_plotter::create_plot, function_name = function_name, key=key, current=current, _extra=extra
  default, function_name, 'print'
  default, key, function_name
  
  if n_elements(self.plots) eq 0 || ~(self.plots)->hasKey(key) || ~isa(((self.plots)[key])[0],"GRAPHICSWIN") then begin 
    if isa(current) then current.select
    function_call =  "(self.plots)[key] = self->"+function_name+"(current=current,_extra=extra)"
    void = execute(function_call)
  endif
end


function stx_plotter::line_data2histogram, line, test_first=test_first, x=x
  if keyword_set(test_first) && self.idlsupports_histogram_plot then return, line  
  if keyword_set(x) then return, [(shift(rebin(line,n_elements(line)*2, /sample),1))[2:-1],line[-1]]
  return, [(shift(rebin(line,n_elements(line)*2, /sample),1))[1:-2],line[-1]]
  ;return, rebin(line,n_elements(line)*2, /sample)
end

pro stx_plotter::reset_plot, window
  
  print, "reset Plot"
  
  foreach plot_id, self.reset_positions->keys() do begin
     plot = obj_valid(plot_id, /cast)
     if ~obj_valid(polt) then begin
        (self.reset_positions)->remove, plot_id
        continue
     end
     if isa(window) && ~(plot.window eq window) then continue
     pos = (self.reset_positions)[plot_id]
     plot.xrange = pos.xrange
     plot.yrange = pos.yrange
  endforeach
  
end

pro stx_plotter::sync_plot, sel_graphics
  print, "sync plot"
end


pro stx_plotter::_registerMouseEvents, window
  COMPILE_OPT IDL2, HIDDEN
  window.mouse_down_handler = 'stx_plotter_MOUSE_DOWN_HANDLER'
  ;window.mouse_wheel_handler = 'stx_plotter_MOUSE_WHEEL_HANDLER'
  window.uvalue = self
end

pro stx_plotter::_store_reset_position, plot
  COMPILE_OPT IDL2, HIDDEN
  ;help, self
  (self.reset_positions)[obj_valid(plot,/get_heap_identifier)] = {xrange : plot.xrange, yrange : plot.yrange }
end


FUNCTION stx_plotter_MOUSE_DOWN_HANDLER , window, X, Y, iButton, KeyMods, nClicks

  print, "mouse down"
  sel_graphics = window.GetSelect()
  
  ; ctrl-click resets the zoom levels
  if KeyMods eq 2 then begin
    window.uvalue->reset_plot, window
  endif else begin
    if KeyMods eq 8 && isa(sel_graphics) then begin
       window.uvalue->sync_plot, sel_graphics
    endif
  endelse
  
  RETURN, 1 ; go on with event handling

END

;FUNCTION stx_plotter_MOUSE_WHEEL_HANDLER , window, X, Y, Delta, KeyMods  
;  ; Using window.uvalue is similar to self
;  
;  sel_graphics = window.GetSelect()
;  
;  if KeyMods eq 8 && isa(sel_graphics) then begin
;     window.uvalue->syncPlot, sel_graphics
;  end
;  
;  RETURN, 1 ; go on with event handling
;
;END


pro stx_plotter__define
  compile_opt idl2

  define = {stx_plotter, $
      plots: hash(),  $
      reset_positions : hash(), $
      idlsupports_histogram_plot : 0b, $
      inherits idl_object $
  }

end