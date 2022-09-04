
;; stx_offset: potential offset between stix optical axis and the solar orbiter one
;; stx_rotat: rotation between stix and solo (default 90 deg)


function stx_solo2stx_coord, xy_coord, stx_offset=stx_offset, stx_rotat=stx_rotat, inverse=inverse

default, stx_offset, [0.,0.]
default, stx_rotat, 90.
default, inverse, 0

xy_coord_final = fltarr(2)
stx_rotat *= !dtor

if ~inverse then begin
  
xy_coord_final[0] =  cos(stx_rotat) * xy_coord[0] + sin(stx_rotat) * xy_coord[1] - stx_offset[0]
xy_coord_final[1] = -sin(stx_rotat) * xy_coord[0] + cos(stx_rotat) * xy_coord[1] - stx_offset[1]

endif else begin
  
xy_coord_final[0] = cos(stx_rotat) * (xy_coord[0] + stx_offset[0]) - sin(stx_rotat) * (xy_coord[1] + stx_offset[1])
xy_coord_final[1] = sin(stx_rotat) * (xy_coord[0] + stx_offset[0]) + cos(stx_rotat) * (xy_coord[1] + stx_offset[1])

endelse

return, xy_coord_final

end