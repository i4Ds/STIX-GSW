function stx_gr_collimator::init, _extra=ex, front=front, rear=rear, distance_front_rear=distance_front_rear
  if (~self->idlgrmodel::init(_extra=ex)) then return, 0b
  
  default, distance_front_rear, 545.30d3
  
  
  
  
  front =  ppl_typeof(front, compareto='stx_grid') ? $ 
    stx_gr_grid(slit=front.SLIT_WD, pitch=front.pitch, orient=front.angle,  width=front.XSIZE, height=front.YSIZE,  name="front") : $
    stx_gr_grid(slit=479d, pitch=909.644d, orient=151.481d,  width=22.0d3, height=22.0d3,  name="front")
      
  rear =  ppl_typeof(rear, compareto='stx_grid')   ? $ 
    stx_gr_grid(slit=rear.SLIT_WD, pitch=rear.pitch, orient=rear.angle,  width=rear.XSIZE, height=rear.YSIZE,  name="rear") : $ 
    stx_gr_grid(slit=479d, pitch=999.045d, orient=148.374d, width=13.0d3, height=13.0d3, name="rear")
  
  rear->translate, 0, 0, distance_front_rear
  
  ;light = idlgrlight(location=[0,0,-10*front_rear_distance], TYPE=1, color=[255,0,0])
  
  self->add, front
  self->add, rear
  ;self->add, light
  
  
  return, 1b
  

end

function stx_gr_collimator::_overloadPrint
       if (!D.NAME eq 'WIN') then newline = string([13B, 10B]) else newline = string(10B)
      
      tempString = "grid " + self.name 
       
      RETURN, tempString
end

pro stx_gr_collimator::cleanup
  self->idlgrmodel::cleanup
end

pro stx_gr_collimator__define
  
  define = { stx_gr_collimator, $
             inherits IDLgrModel}
end