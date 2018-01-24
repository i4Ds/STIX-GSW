function stx_graphic_detector::init, _extra=ex
  
  if (~self->GRAPHIC::init(_extra=ex)) then return, 0b
  
  self.bordercolor = 255
  self.borderthick = 2
  self.linecolor = [255,0,0]
  self.linethick = 2
  self.linestyle = 0
  self.showsin = 0b
  self.datarange = [0ul,100ul]
  self.uvalue = ptr_new([0,100,100,0,45,85,85,45,0,40,60,0])
  
  self.components = hash()
 
  
  lpx = 2.2d3
  lpy = 4.6d3
  
  lyr = lpy/lpx
  
  spx = 1.1d3
  spy = 0.91d3
  
  sxr = spx/lpx
  syr = spy/lpy * lyr
  
  x = [0,1,1,0,0]
  y = [0,0,1,1,0]
  
  yb = x
  xb = y 
  
  sy = syr*(y-0.5)
    
  rgb=[250,0,0]
  
  
  
  mainp = plot([-2,2], [-2,2], name="mplot", color=255, title="counts", xrange=[-2,2], yrange=[-2,2], /xstyle, /ystyle, axis_style=0, /nodata, aspect_ratio=1, _extra=ex )
  mainp.Refresh, /DISABLE
    
  
  (self.components)['mainp']=mainp
    
  (self.components)['t1'] = Polygon( transpose([[x-2],[lyr*y]]), name="t1", fill_color=rgb,  /data, target=mainp )
  (self.components)['t2'] = Polygon( transpose([[x-1],[lyr*y]]), name="t2", fill_color=rgb,  /data, target=mainp )
  (self.components)['t3'] = Polygon( transpose([[x],  [lyr*y]]), name="t3", fill_color=rgb,  /data, target=mainp )
  (self.components)['t4'] = Polygon( transpose([[x+1],[lyr*y]]), name="t4", fill_color=rgb,  /data, target=mainp )
  
  (self.components)['b1'] = Polygon( transpose([[xb-2],[-lyr*yb]]), name="b1", fill_color=rgb, /data, target=mainp )
  (self.components)['b2'] = Polygon( transpose([[xb-1],[-lyr*yb]]), name="b2", fill_color=rgb, /data, target=mainp )
  (self.components)['b3'] = Polygon( transpose([[xb],  [-lyr*yb]]), name="b3", fill_color=rgb, /data, target=mainp )
  (self.components)['b4'] = Polygon( transpose([[xb+1],[-lyr*yb]]), name="b4", fill_color=rgb, /data, target=mainp )
  
  (self.components)['s1'] = Polygon( transpose([[sxr*x-2],[sy]]), name="s1", fill_color=rgb,  /data, target=mainp)
  (self.components)['s2'] = Polygon( transpose([[sxr*x-1],[sy]]), name="s2", fill_color=rgb,  /data, target=mainp)
  (self.components)['s3'] = Polygon( transpose([[sxr*x],  [sy]]), name="s3", fill_color=rgb,  /data, target=mainp)
  (self.components)['s4'] = Polygon( transpose([[sxr*x+1],[sy]]), name="s4", fill_color=rgb,  /data, target=mainp)
  
  (self.components)['tplot'] = plot([-2,2], [0,2], name="tplot", overplot=mainp, color=255, axis_style=0)
  (self.components)['bplot'] = plot([-2,2], [0,-2], name="bplot", overplot=mainp, color=255, axis_style=0)
  
  IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
  
  mainp.Refresh
  
  ;self->_update_data
  ;self->_update_plot
  ;self->_update_border
  
  return, 1b

end

pro stx_graphic_detector::_update_border
   COMPILE_OPT IDL2, HIDDEN
   
   borders = ["s1","s2","s3","s4","t1","t2","t3","t4","b1","b2","b3","b4"]
   
   foreach bordername, borders do begin
      border = (self.components)[bordername]
      border->setProperty, thick=self.borderthick, color=self.bordercolor
   endforeach 
      
end

pro stx_graphic_detector::_update_plot
   COMPILE_OPT IDL2, HIDDEN
   
   plots = ["tplot","bplot"]
   
   foreach plotname, plots do begin
      plot = (self.components)[plotname]
      plot->setProperty, thick=self.linethick, color=self.linecolor, linestyle=self.linestyle
   endforeach 
      
end

pro stx_graphic_detector::_update_data
   COMPILE_OPT IDL2, HIDDEN
   
   if ~isa(self.uvalue) || ~isa(*self.uvalue, /array, /number) then return
   
   
   
   mplot = (self.components)['mainp']
   mplot->Refresh, /DISABLE
   
   
   bottom_elements = ["bplot","s1","s2","s3","s4","b1","b2","b3","b4"]
      
   data = reform(*self.uvalue)
   colors = self->_getColor(data)
   n_data = n_elements(data)
   
   
   mplot.setProperty, title=trim(total(data))
   
   foreach name, ["t1","t2","t3","t4","b1","b2","b3","b4","s1","s2","s3","s4"], index do begin
          if index ge n_data then break
          (self.components)[name].fill_color = reform(colors[index,*])
      
          
   endforeach
   
   if n_data ge 4 then begin
      tplot =  (self.components)["tplot"]
      self->_getPlotData, data[0:3], x=x,y=y
      tplot->setData, x, y
   end 
   
   if n_data gt 4 && n_data le 12 then begin
      foreach name, bottom_elements do begin
          (self.components)[name].hide = 0
      endforeach
      
      bplot =  (self.components)["bplot"]
      self->_getPlotData, data[4:7], x=x,y=y
      bplot->setData, x, y-2
   end else begin
      foreach name, bottom_elements do begin
          (self.components)[name].hide = 1
      endforeach  
   end
   
   mplot->Refresh
end

pro stx_graphic_detector::_getPlotData, data, x=x, y=y
      COMPILE_OPT IDL2, HIDDEN 
      
      if self.showsin then begin
        n_plot_points = 20.d
        
        x_data = 2.d*!pi * findgen(n_plot_points) / (n_plot_points-1)
        x = 4 * findgen(n_plot_points) / (n_plot_points-1) - 2
        
        y_data = stx_sine(x_data, scale_vector(data,  minvalue=self.datarange[0], maxvalue=self.datarange[1]))
        y = (y_data * 2.)
        
      endif else begin
        x = [-2,-1,-1,0,0,1,1,2]
        y = scale_vector(data[[0,0,1,1,2,2,3,3]],  minvalue=self.datarange[0], maxvalue=self.datarange[1]) * 2
      endelse
      
      
end

function stx_graphic_detector::_getColor, value
  COMPILE_OPT IDL2, HIDDEN
  
  TVLCT, r, g, b, /Get 
  
  index = bytscl(value, min=self.datarange[0], max=self.datarange[1])
  
  return, [[r[index]],[g[index]],[b[index]]]
end

pro stx_graphic_detector::cleanup
  self->GRAPHIC::cleanup
end

pro stx_graphic_detector::SetProperty, _EXTRA=ex, $
  bordercolor = bordercolor, $
  borderthick = borderthick, $
  linestyle = linestyle, $
  linethick = linethick, $
  linecolor = linecolor, $
  datarange = datarange, $
  showsin = showsin, $
  uvalue = uvalue
  
  self->GRAPHIC::SetProperty, _EXTRA=ex
  
  
  update_border = 0
  update_plot   = 0
  update_data   = 0
  
  if (ISA(bordercolor,/number))                 then begin 
                                                      self.bordercolor = bordercolor
                                                      update_border = 1  
                                                     end
  if (ISA(borderthick,/number))                 then begin 
                                                       self.borderthick = borderthick
                                                       update_border = 1
                                                     end 
  if (ISA(linethick,/number))                   then begin 
                                                       self.linethick = linethick
                                                       update_plot = 1
                                                     end
  if (ISA(linecolor,/number))                   then begin 
                                                       self.linecolor = linecolor
                                                       update_plot = 1
                                                     end
  if (ISA(linestyle,/number))                   then begin 
                                                       self.linestyle = linestyle
                                                       update_plot = 1
                                                     end
 
  if (ISA(showsin,/number))                     then begin 
                                                       self.showsin= byte(showsin gt 0)
                                                       update_data = 1
                                                     end
  
   if ISA(uvalue, /array, /number)              then begin
                                                       self.uvalue = ptr_new(uvalue)
                                                       update_data = 1
                                                     end
   if ISA(datarange, /array, /number)           then begin
                                                       self.datarange = ulong(datarange)
                                                       update_data = 1
                                                     end
                                                     
  if update_border then self->_update_border
  if update_plot then self->_update_plot
  if update_data then self->_update_data
end


pro stx_graphic_detector__define
  
  define = { stx_graphic_detector, $
             bordercolor : 255, $
             borderthick : 2, $
             linecolor : [255b,0,0], $
             linethick : 2, $
             linestyle : 1, $
             showsin   : 0b, $
             datarange : [0ul,0ul], $
             uvalue      : ptr_new(), $
             components  : hash(), $
             inherits GRAPHIC}
end