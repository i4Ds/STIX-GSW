
;; Pointing correction

function stx_rtn2solo_coord, xy_coord, aux_data, inverse=inverse

  default, inverse, 0
  
  stx_pointing = aux_data.STX_POINTING
  
  if ~inverse then begin
    
    xy_coord_final = xy_coord - stx_pointing
    
  endif else begin
    
    xy_coord_final = xy_coord + stx_pointing
    
  endelse

  return, xy_coord_final

end