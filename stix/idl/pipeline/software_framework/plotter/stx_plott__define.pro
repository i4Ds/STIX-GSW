function stx_plott::init, data,  current=current, _extra=extra
  ; Initialize the object fields
  self.idlsupports_histogram_plot = float(!Version.Release) ge 8.22
  self.plots = list()

  
  self->setProperty, data=data, window=current
  self->createPlot, _extra=extra
  self->updatePlot

  return, 1
end

pro stx_plott::cleanup
  
  if isa(self.window) then self.window->close
  obj_destroy, self.window, self.legend, self.plots
  PTR_FREE, self.data
end

PRO stx_plott::GetProperty,  $
  window=window, $
  legend=legend, $
  plots=plots, $
  baseplot=baseplot, $
  data=data

  COMPILE_OPT IDL2

  ; If "self" is defined, then this is an "instance".
  IF (ISA(self)) THEN BEGIN
    ; User asked for an "instance" property.
    IF arg_present(window)       THEN window = self.window
    IF arg_present(legend)       THEN legend = self.legend
    IF arg_present(plots)        THEN plots = self.plots
    IF arg_present(baseplot)     THEN baseplot = N_ELEMENTS(self.plots) gt 0 ? (self.plots)[0] : []
    IF arg_present(data)         THEN data = *self.data
  
  endif
END


PRO stx_plott::SetProperty, $
  ;plot=plot, $
  window=window, $
  ;legend=legend, $
  ;overplots=overplots, $
  data=data, $
  _extra=extra
  
  COMPILE_OPT IDL2
  
  error = 0
  catch, error
  if(error ne 0) then begin
    catch, /cancel
    message, !ERR_STRING,  /continue
    return
  endif
  
  ; If user passed in a property, then set it.
  if ISA(window)       then self.window = window
  if ISA(data)         then self.data = ptr_new(data)
  if ISA(extra)        then (self.plots)[0]->setProperty, _extra=extra
end

pro stx_plott::_create_plot, overplot=overplot, _extra=extra
  COMPILE_OPT hidden
end

pro stx_plott::setData, data, update=update, _extra=extra
  default, update, 1
  self->SetProperty, data=data
  if update then self->updatePlot, _extra=extra
end

pro stx_plott::updatePlot
  
end


function stx_plott::line_data2histogram, line, test_first=test_first, x=x
  if keyword_set(test_first) && self.idlsupports_histogram_plot then return, line  
  if keyword_set(x) then return, [(shift(rebin(line,n_elements(line)*2, /sample),1))[2:-1],line[-1]]
  return, [(shift(rebin(line,n_elements(line)*2, /sample),1))[1:-2],line[-1]]
  ;return, rebin(line,n_elements(line)*2, /sample)
end



pro stx_plott__define
  compile_opt idl2

  define = {stx_plott, $
      window    : obj_new(), $
      plots     : list(),  $
      legend    : obj_new(), $
      data      : ptr_new(), $
      idlsupports_histogram_plot : 0b, $
      inherits idl_object $
  }

end