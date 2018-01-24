;+
; :file_comments:
;      Creating a graphics object to represent a detector with summed pixels
;      in sum scheme 2 (summing the top, the small and the bottom pixels in one
;      column to a total of 4 'pixels').
;      Based on the first version create by Nicky Hochmuth (FHNW).
;
; :categories:
;
; :examples:
;
; :history:
;    17-Dec-2015 - Roman Boutellier (FHNW),
;-
;
;+
; :description:
;    Initializing the object. This function is called automatically
;    upon creation of the object.
;    It creates all the IDL graphics objects which build together the
;    representation of a detector.
;
; :Keywords:
;    _extra
;
; :returns:
;
; :history:
;    17-Dec-2015 - Roman Boutellier (FHNW),
;-
function stx_detector_summed_2_object_graphics::init, _extra=extra
  if (~self->idlgrmodel::init(_extra=ex)) then return, 0b
  ; Set the values
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

  ; Prepare the sizes of the large and the small pixels
  ; Large pixel x-size
  lpx = 2.2d3
  ; Large pixel y-size
  lpy = 4.6d3
  ; Large pixel y-ratio
  lyr = lpy/lpx
  
  ; Small pixel x-size
  spx = 1.1d3
  ; Small pixel y-size
  spy = 0.91d3
  ; Small pixel x-ratio
  sxr = spx/lpx
  ; Small pixel y-ratio
  syr = spy/lpy * lyr
  
  ; x- and y-coordinates for the corners of the rectangles (the first corner
  ; is used twice to ensure drawing all edges)
  ; 
  ; 0/1 ------ 1/1
  ;  |          |
  ;  |          |
  ;  |          |
  ;  |          |
  ; 0/0 ------ 1/0
  x = [0,1,1,0,0]
  y = [0,0,1,1,0]
  
  yb = x
  xb = y 
  
  sy = syr*(y-0.5)
  
  ; Set the default color
  rgb=[250,0,0]
  
  ; Create and add the lines in the pixels
  tplot = obj_new('IDLgrPlot', [-2,2], [-2,2], name="tplot", color=255);[-2,2], [0,2], name="tplot", color=255)
  bplot = obj_new('IDLgrPlot', [-2,2], [-2,-2], name="bplot", color=255);[-2,2], [0,-2], name="bplot", color=255)
  self->add, tplot
  self->add, bplot
  
  ; Create the graphic objects for the 4 big pixels in the top row
  t1 = obj_new('IDLgrPolygon', transpose([[x[0]-2,x[1]-2,x[2]-2,x[3]-2,x[4]-2],[y[0]+2,y[1]+2,y[2]-3,y[3]-3,y[4]+2]]), name="t1", color=rgb )
  t2 = obj_new('IDLgrPolygon', transpose([[x[0]-1,x[1]-1,x[2]-1,x[3]-1,x[4]-1],[y[0]+2,y[1]+2,y[2]-3,y[3]-3,y[4]+2]]), name="t2", color=rgb )
  t3 = obj_new('IDLgrPolygon', transpose([[x],[y[0]+2,y[1]+2,y[2]-3,y[3]-3,y[4]+2]]), name="t3", color=rgb )
  t4 = obj_new('IDLgrPolygon', transpose([[x[0]+1,x[1]+1,x[2]+1,x[3]+1,x[4]+1],[y[0]+2,y[1]+2,y[2]-3,y[3]-3,y[4]+2]]), name="t4", color=rgb )
  ; Add the 4 top row big pixels and their lines
  self->add, obj_new('IDLgrPolyline', *t1.data, name="bt1")
  self->add, obj_new('IDLgrPolyline', *t2.data, name="bt2")
  self->add, obj_new('IDLgrPolyline', *t3.data, name="bt3")
  self->add, obj_new('IDLgrPolyline', *t4.data, name="bt4")
  self->add, t1
  self->add, t2
  self->add, t3
  self->add, t4
  
  ; Add the label showing the total counts of the detector
  self->add, obj_new('IDLgrText', self.name , name="countlabel", location=[0,2.1], CHAR_DIMENSIONS=[0.6,0.6], ALIGNMENT=0.5)
  
  ; Add additional properties
  if (isa(ex)) then self->SetProperty, _extra=ex
  
  ; Update the plots
  self->_update_plot
  self->_update_border
  self->_update_data
  
  return, 1b
end

;+
; :description:
;    Overloading the print statement of a detector graphics object.
;    It prints the detector name and all the count values for each pixel.
;
; :returns:
;
; :history:
;    17-Dec-2015 - Roman Boutellier (FHNW),
;-
function stx_detector_summed_2_object_graphics::_overloadPrint
       if (!D.NAME eq 'WIN') then newline = string([13B, 10B]) else newline = string(10B)
       pixel_data = *self.uvalue 
      
      tempString = "Detector " + self.name + ":  "+trim(total(pixel_data))+newline + STRJOIN(string(pixel_data[0:3]))
      if n_elements(pixel_data) gt 4 then tempString = tempString + newline + STRJOIN(string(pixel_data[8:11])) + newline + STRJOIN(string(pixel_data[4:7]))
       
      RETURN, tempString
end

;+
; :description:
;    Updating the borders of the detector plot (thick, color, hide).
;
; :returns:
;
; :history:
;    17-Dec-2015 - Roman Boutellier (FHNW),
;-
pro stx_detector_summed_2_object_graphics::_update_border
   compile_opt idl2, hidden
   
   borders = ["bt1","bt2","bt3","bt4"]
   
   foreach bordername, borders do begin
      border = self->getbyname(bordername)
      hide = self.borderthick eq 0
      border->setProperty, thick=self.borderthick, color=self.bordercolor, hide=hide
   endforeach 
      
end

;+
; :description:
;    Update the lines in the pixels.
;
; :returns:
;
; :history:
;    17-Dec-2015 - Roman Boutellier (FHNW),
;-
pro stx_detector_summed_2_object_graphics::_update_plot
   compile_opt idl2, hidden
   
   plots = ["tplot","bplot"]
   
   foreach plotname, plots do begin
      plot = self->getbyname(plotname)
      plot->setProperty, thick=self.linethick, color=self.linecolor, linestyle=self.linestyle
   endforeach 
      
end

;+
; :description:
;    Update the data represented by the detector.
;
; :returns:
;
; :history:
;    17-Dec-2015 - Roman Boutellier (FHNW),
;-
pro stx_detector_summed_2_object_graphics::_update_data
   compile_opt idl2, hidden
   
   if ~isa(self.uvalue) || ~isa(*self.uvalue, /array, /number) then return
   
   bottom_elements = ["bplot"]
      
   data = reform(*self.uvalue)
   colors = self->_getColor(data)
   n_data = n_elements(data)
   
   text =  self->getbyname("countlabel")
   text.setProperty, strings=trim(total(data));+" "+self.name
   
   foreach name, ["t1","t2","t3","t4"], index do begin
          if index ge n_data then break
          
          gr = self->getbyname(name)
          gr.setProperty, color = reform(colors[index,*])
          
   endforeach
   
   if n_data ge 4 then begin
      tplot =  self->getbyname("tplot")
      self->_getPlotData, data[0:3], x=x,y=y
      tplot->setProperty, datax=x, datay=y
   end 
   
   if n_data gt 4 && n_data le 12 then begin
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

;+
; :description:
;    Get the data used to create the lines in the pixels of the plot.
;
; :Params:
;    data
;
; :Keywords:
;    x, out, required
;    y, out, required
;
; :returns:
;
; :history:
;    17-Dec-2015 - Roman Boutellier (FHNW),
;-
pro stx_detector_summed_2_object_graphics::_getPlotData, data, x=x, y=y
  compile_opt idl2, hidden
      
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

;+
; :description:
;    Get the colors according to the input data.
;
; :Params:
;    _value
;
; :returns:
;
; :history:
;    17-Dec-2015 - Roman Boutellier (FHNW),
;-
function stx_detector_summed_2_object_graphics::_getColor, _value
  compile_opt idl2, hidden
  
  value = _value
  
  self.palette->getProperty, blue_values=b, green_values=g, red_values=r  
  
  index = bytscl(value, min=self.datarange[0], max=self.datarange[1])
  
  return, [[r[index]],[g[index]],[b[index]]]
end

pro stx_detector_summed_2_object_graphics::cleanup
  self->idlgrmodel::cleanup
end

;+
; :description:
;    Set properties.
;
; :Keywords:
;    _EXTRA
;    bordercolor
;    borderthick
;    linestyle
;    linethick
;    linecolor
;    datarange
;    showsin
;    uvalue
;    smallpixelboost
;    palette
;
; :returns:
;
; :history:
;    17-Dec-2015 - Roman Boutellier (FHNW),
;-
pro stx_detector_summed_2_object_graphics::SetProperty, _EXTRA=ex, $
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


pro stx_detector_summed_2_object_graphics__define
  compile_opt idl2
  
  define = {stx_detector_summed_2_object_graphics, $
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