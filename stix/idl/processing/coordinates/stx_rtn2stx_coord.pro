
;; stx_offset: potential offset between stix optical axis and the solar orbiter one
;; stx_rotat: rotation between stix and solo (default 90 deg)


function stx_rtn2stx_coord, xy_coord, aux_data, stx_offset=stx_offset, stx_rotat=stx_rotat, inverse=inverse

default, stx_offset, [0.,0.]
default, stx_rotat, 90.
default, inverse, 0


if ~inverse then begin
  
  xy_coord_solo  = stx_rtn2solo_coord(xy_coord, aux_data, inverse=inverse)
  xy_coord_final = stx_solo2stx_coord(xy_coord_solo, stx_offset=stx_offset, stx_rotat=stx_rotat, inverse=inverse)

endif else begin
  
  xy_coord_solo  = stx_solo2stx_coord(xy_coord, stx_offset=stx_offset, stx_rotat=stx_rotat, inverse=inverse)
  xy_coord_final = stx_rtn2solo_coord(xy_coord_solo, aux_data, inverse=inverse)

endelse

return, xy_coord_final

end