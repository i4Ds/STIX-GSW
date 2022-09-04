
;; Roll angle correction

function stx_hpc2rtn_coord, xy_coord, aux_data, inverse=inverse

default, inverse, 0

;; Spacecraft roll angle (degrees)
roll_angle = aux_data.ROLL_ANGLE * !dtor

xy_coord_final = fltarr(2)

if ~inverse then begin

  xy_coord_final[0] = cos(roll_angle)  * xy_coord[0] + sin(roll_angle) * xy_coord[1]
  xy_coord_final[1] = -sin(roll_angle) * xy_coord[0] + cos(roll_angle) * xy_coord[1]

endif else begin
  
  xy_coord_final[0] = cos(roll_angle) * xy_coord[0] - sin(roll_angle) * xy_coord[1]
  xy_coord_final[1] = sin(roll_angle) * xy_coord[0] + cos(roll_angle) * xy_coord[1]
  
endelse

return, xy_coord_final

end