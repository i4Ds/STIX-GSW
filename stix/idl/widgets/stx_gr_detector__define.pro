function stx_gr_detector::init, _extra=ex
  if (~self->idlgrmodel::init(_extra=ex)) then return, 0b
  
  self.bordercolor = 255
  self.borderthick = 1
  self.linecolor = 255
  self.linethick = 2
  self.linestyle = 0
  self.showsin = 0b
  self.datarange = [0ul,100ul]
  self.uvalue = ptr_new([0,100,100,0,45,85,85,45,0,4,4,0])
  self.smallpixelboost = 1.0
  
  self.palette = idlgrpalette()
  
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
   
  s1 = obj_new('IDLgrPolygon', transpose([[sxr*x-2],[sy]]), name="s1", color=rgb)
  s2 = obj_new('IDLgrPolygon', transpose([[sxr*x-1],[sy]]), name="s2", color=rgb)
  s3 = obj_new('IDLgrPolygon', transpose([[sxr*x],  [sy]]), name="s3", color=rgb)
  s4 = obj_new('IDLgrPolygon', transpose([[sxr*x+1],[sy]]), name="s4", color=rgb)
  
    
  self->add, obj_new('IDLgrPolyline', *s1.data, name="bs1")
  self->add, obj_new('IDLgrPolyline', *s2.data, name="bs2")
  self->add, obj_new('IDLgrPolyline', *s3.data, name="bs3")
  self->add, obj_new('IDLgrPolyline', *s4.data, name="bs4")
  
  self->add, s1
  self->add, s2
  self->add, s3
  self->add, s4
  
  tplot = obj_new('IDLgrPlot', [-2,2], [0,2], name="tplot", color=255)
  bplot = obj_new('IDLgrPlot', [-2,2], [0,-2], name="bplot", color=255)
  
  self->add, tplot
  self->add, bplot
    
  t1 = obj_new('IDLgrPolygon', transpose([[x-2],[lyr*y]]), name="t1", color=rgb )
  t2 = obj_new('IDLgrPolygon', transpose([[x-1],[lyr*y]]), name="t2", color=rgb )
  t3 = obj_new('IDLgrPolygon', transpose([[x],  [lyr*y]]), name="t3", color=rgb )
  t4 = obj_new('IDLgrPolygon', transpose([[x+1],[lyr*y]]), name="t4", color=rgb )
  
  self->add, obj_new('IDLgrPolyline', *t1.data, name="bt1")
  self->add, obj_new('IDLgrPolyline', *t2.data, name="bt2")
  self->add, obj_new('IDLgrPolyline', *t3.data, name="bt3")
  self->add, obj_new('IDLgrPolyline', *t4.data, name="bt4")
  
  b1 = obj_new('IDLgrPolygon', transpose([[xb-2],[-lyr*yb]]), name="b1", color=rgb )
  b2 = obj_new('IDLgrPolygon', transpose([[xb-1],[-lyr*yb]]), name="b2", color=rgb )
  b3 = obj_new('IDLgrPolygon', transpose([[xb],  [-lyr*yb]]), name="b3", color=rgb )
  b4 = obj_new('IDLgrPolygon', transpose([[xb+1],[-lyr*yb]]), name="b4", color=rgb )
  
  self->add, obj_new('IDLgrPolyline', *b1.data, name="bb1")
  self->add, obj_new('IDLgrPolyline', *b2.data, name="bb2")
  self->add, obj_new('IDLgrPolyline', *b3.data, name="bb3")
  self->add, obj_new('IDLgrPolyline', *b4.data, name="bb4")
  
  self->add, t1
  self->add, t2
  self->add, t3
  self->add, t4
  
  self->add, b1
  self->add, b2
  self->add, b3
  self->add, b4
  
  self->add, OBJ_NEW('IDLgrText', self.name , name="countlabel", location=[0,2.1], CHAR_DIMENSIONS=[0.6,0.6], ALIGNMENT=0.5)
  
  IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
  
  
  self->_update_plot
  self->_update_border
  self->_update_data
  
  return, 1b

end

function stx_gr_detector::_overloadPrint
       if (!D.NAME eq 'WIN') then newline = string([13B, 10B]) else newline = string(10B)
       pixel_data = *self.uvalue 
      
      tempString = "Detector " + self.name + ":  "+trim(total(pixel_data))+newline + STRJOIN(string(pixel_data[0:3]))
      if n_elements(pixel_data) gt 4 then tempString = tempString + newline + STRJOIN(string(pixel_data[8:11])) + newline + STRJOIN(string(pixel_data[4:7]))
       
      RETURN, tempString
end

pro stx_gr_detector::_update_border
   COMPILE_OPT IDL2, HIDDEN
   
   borders = ["bs1","bs2","bs3","bs4","bt1","bt2","bt3","bt4","bb1","bb2","bb3","bb4"]
   
   foreach bordername, borders do begin
      border = self->getbyname(bordername)
      hide = self.borderthick eq 0
      border->setProperty, thick=self.borderthick, color=self.bordercolor, hide=hide
   endforeach 
      
end

pro stx_gr_detector::_update_plot
   COMPILE_OPT IDL2, HIDDEN
   
   plots = ["tplot","bplot"]
   
   foreach plotname, plots do begin
      plot = self->getbyname(plotname)
      plot->setProperty, thick=self.linethick, color=self.linecolor, linestyle=self.linestyle
   endforeach 
      
end

pro stx_gr_detector::_update_data
   COMPILE_OPT IDL2, HIDDEN
   
   if ~isa(self.uvalue) || ~isa(*self.uvalue, /array, /number) then return
   
   bottom_elements = ["bplot","bs1","bs2","bs3","bs4","bb1","bb2","bb3","bb4","s1","s2","s3","s4","b1","b2","b3","b4"]
      
   data = reform(*self.uvalue)
   colors = self->_getColor(data)
   n_data = n_elements(data)
   
   text =  self->getbyname("countlabel")
   text.setProperty, strings=trim(total(data));+" "+self.name
   
   foreach name, ["t1","t2","t3","t4","b1","b2","b3","b4","s1","s2","s3","s4"], index do begin
          if index ge n_data then break
          
          gr = self->getbyname(name)
          gr.setProperty, color = reform(colors[index,*])
          
   endforeach
   
   if n_data ge 5 then begin
      tplot =  self->getbyname("tplot")
      self->_getPlotData, data[0:3], x=x,y=y
      tplot->setProperty, datax=x, datay=y
   end 
   
   if n_data gt 5 && n_data le 12 then begin
      foreach name, bottom_elements do begin
          gr = self->getbyname(name)
          gr.hide = 0
      endforeach
      
      bplot =  self->getbyname("bplot")
      self->_getPlotData, data[4:7], x=x,y=y
      bplot->setProperty, datax=x, datay=y-2
   end else begin
      foreach name, bottom_elements do begin
          gr = self->getbyname(name)
          gr.hide = 1
      endforeach  
   end
end

pro stx_gr_detector::_getPlotData, data, x=x, y=y
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

function stx_gr_detector::_getColor, _value
  COMPILE_OPT IDL2, HIDDEN
  
  value = _value
  
  if n_elements(value) eq 12 then value[8:11] *= self.smallpixelboost
  
  self.palette->getProperty, blue_values=b, green_values=g, red_values=r  
  
  index = bytscl(value, min=self.datarange[0], max=self.datarange[1])
  
  return, [[r[index]],[g[index]],[b[index]]]
end

pro stx_gr_detector::cleanup
  self->idlgrmodel::cleanup
end

pro stx_gr_detector::SetProperty, _EXTRA=ex, $
  bordercolor = bordercolor, $
  borderthick = borderthick, $
  linestyle = linestyle, $
  linethick = linethick, $
  linecolor = linecolor, $
  datarange = datarange, $
  showsin = showsin, $
  uvalue = uvalue, $
  smallpixelboost = smallpixelboost, $
  palette = palette
  
  self->idlgrmodel::SetProperty, _EXTRA=ex
  
  
  update_border = 0
  update_plot   = 0
  update_data   = 0
  
  if (ISA(palette, "idlgrpalette"))                 then begin 
                                                      self.palette = palette
                                                      update_data = 1  
                                                     end
  
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
   if (ISA(smallpixelboost,/number))             then begin 
                                                      self.smallpixelboost = smallpixelboost
                                                      _update_data = 1  
                                                     end
                                                     
  if update_border then self->_update_border
  if update_plot then self->_update_plot
  if update_data then self->_update_data
end


pro stx_gr_detector__define
  
  define = { stx_gr_detector, $
             bordercolor : 255, $
             borderthick : 2, $
             linecolor : 255, $
             linethick : 2, $
             linestyle : 1, $
             showsin   : 0b, $
             palette   : obj_new(), $ 
             smallpixelboost : 1., $
             datarange : [0ul,0ul], $
             inherits IDLgrModel, $
             inherits IDL_Object}
end