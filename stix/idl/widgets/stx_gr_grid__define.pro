function stx_gr_grid::init, _extra=ex
  if (~self->idlgrmodel::init(_extra=ex)) then return, 0b
  
  self.slit = 479
  self.pitch = 909.644
  self.slat = self.pitch - self.slit
  self.orientation = 151.481
  
  self.width =  22.0d3
  self.height = 20.0d3
   
 
  
  IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
  
  
  self->_update_plot
  
  return, 1b

end

function stx_gr_grid::_overloadPrint
       if (!D.NAME eq 'WIN') then newline = string([13B, 10B]) else newline = string(10B)
      
      tempString = "grid " + self.name 
       
      RETURN, tempString
end


pro stx_gr_grid::_update_plot
   COMPILE_OPT IDL2, HIDDEN
   
    bwith = 20.0d3 
    
    border = IDLgrModel(name="border")
    grid = IDLgrModel(name="grid")
    
    
    b1 = IDLgrPolygon(transpose([[self.width,self.width,0,0],[0,-bwith,-bwith,0]]), name="b1")
    b2 = IDLgrPolygon(transpose([[0,-bwith,-bwith,0],[-bwith,-bwith,self.height+bwith,self.height+bwith]]), name="b2")
    b3 = IDLgrPolygon(transpose([[0,0,self.width,self.width],[self.height,self.height+bwith,self.height+bwith,self.height]]), name="b3")
    b4 = IDLgrPolygon(transpose([[self.width,self.width+bwith,self.width+bwith,self.width],[self.height+bwith,self.height+bwith,-bwith,-bwith]]), name="b4")
    
    border->translate, -self.width / 2., -self.height /2. , 0
    
  border->add, [b1,b2,b3,b4]
  
  x = idlgraxis(0, range=[-40.0d3,40.0d3], /NOTEXT) 
  y = idlgraxis(1, range=[-40.0d3,40.0d3], /NOTEXT)
  
  
  
  n = (self.width+bwith)/self.pitch
  
  for i=0l, n-1 do begin
      
      
      x1 = -bwith/2 + i * self.pitch 
      x2 = x1+self.slit
      
      y1 = -bwith/2
      y2 = self.height+bwith/2
      
        
      grid->add, idlgrpolygon(transpose([[x1,x1,x2,x2],[y1,y2,y2,y1]]), name="p"+trim(i))
  end  
  
  grid->translate, -self.width / 2., -self.height /2. , 0
  grid->rotate, [0,0,1], self.orientation
        
  self->add, grid
  self->add, border
  ;self->add, [x,y]
end


pro stx_gr_grid::cleanup
  self->idlgrmodel::cleanup
end

pro stx_gr_grid::SetProperty, _EXTRA=ex, $
  slit = slit, $
  pitch = pitch, $
  orientation = orientation, $
  width = width, $
  height = height

  self->idlgrmodel::SetProperty, _EXTRA=ex
  
  update_plot = 0
  update_slat = 0
  if (ISA(slit,/number))                 then begin 
                                                      self.slit = slit
                                                      update_plot = 1
                                                      update_slat = 1
                                                        
                                                     end
 
  if (ISA(pitch,/number))                   then begin 
                                                       self.pitch = pitch
                                                       update_plot = 1
                                                       update_slat = 1
                                                     end
  if (ISA(orientation,/number))                   then begin 
                                                       self.orientation = orientation
                                                       update_plot = 1
                                                     end
  if (ISA(width,/number))                   then begin 
                                                       self.width = width
                                                       update_plot = 1
                                                     end
 
  if (ISA(height,/number))                     then begin 
                                                       self.height= height
                                                       update_plot = 1
                                                     end
                                                     
  if update_slat then self.slat = self.pitch-self.slit
  if update_plot then self->_update_plot
end


pro stx_gr_grid__define
  
  define = { stx_gr_grid, $
             slit : 0d, $
             slat : 0d, $
             pitch: 0d, $
             orientation: 0d, $
             width: 0d, $
             height: 0d, $
             inherits IDLgrModel, $
             inherits IDL_Object}
end