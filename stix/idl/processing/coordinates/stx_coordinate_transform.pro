;+
;
; NAME:
;
;   stx_coordinate_transform
;
; PURPOSE:
; 
;   Transform a bi-dimensional array of coordinates from Helioprojective Cartesian coordinate frame 
;   (Solar Orbiter vantage point) to STIX coordinate frame and viceversa
;
; CALLING SEQUENCE:
;
;   xy_coord_new = stx_coordinate_transform(xy_coord, aux_data)
;
; INPUTS:
;
;   xy_coord: bi-dimensional array of coordinates (arcsec). If the 'inverse' keyword is set to 0,
;             the coordinates are assumed to be in the Helioprojective Cartesian coordinate frame
;             (Solar Orbiter vantage point) and they are transformed into the corresponding ones 
;             in the STIX coordinate frame
;             
;   aux_data: 'stx_aux_data' structure containing information on STIX pointing and spacecraft roll angle
;   
;
; KEYWORDS:
;
;   inverse: if set, the invese transformation is applied. In this case, the coordinates in 'xy_coord'
;            are assumed to be in the STIX coordinate frame and they are transformed into the corresponding 
;            ones in the Helioprojective Cartesian coordinate frame
;
; OUTPUTS:
;
;   A bi-dimensional array containing the transformed coordinates
;
; HISTORY: August 2022, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-

function stx_coordinate_transform, xy_coord, aux_data, inverse=inverse

default, inverse, 0

xy_coord_spacecraft = fltarr(2)
xy_coord_final      = fltarr(2)

;; STIX pointing coordinates (in the spacecraft coordinate frame, i.e. no rotation by 90 degrees due to 
;; the fact that STIX is mounted on the side of the spacecraft)
stx_pointing = aux_data.STX_POINTING

;; Spacecraft roll angle (degrees)
roll_angle = aux_data.ROLL_ANGLE * !dtor

if ~inverse then begin
  
  ;;************** Transformation from Helioprojective Cartesian coordinates to spacecraft reference system coordinates
  xy_coord_spacecraft[0] = cos(roll_angle)  * xy_coord[0] + sin(roll_angle) * xy_coord[1] - stx_pointing[0]
  xy_coord_spacecraft[1] = -sin(roll_angle) * xy_coord[0] + cos(roll_angle) * xy_coord[1] - stx_pointing[1]
  
  ;;************** Transformation from spacecraft reference system coordinates to STIX reference system coordinates
  xy_coord_final[0] = xy_coord_spacecraft[1]
  xy_coord_final[1] = -xy_coord_spacecraft[0]

endif else begin
  
  ;;************** Transformation from STIX reference system coordinates to spacecraft reference system coordinates
  xy_coord_spacecraft[0] = -xy_coord[1]
  xy_coord_spacecraft[1] = xy_coord[0]
  
  ;;************** Transformation from spacecraft reference system coordinates to Helioprojective Cartesian coordinates 
  xy_coord_final[0] = cos(roll_angle) * (xy_coord_spacecraft[0]+stx_pointing[0]) - sin(roll_angle) * (xy_coord_spacecraft[1]+stx_pointing[1]) 
  xy_coord_final[1] = sin(roll_angle) * (xy_coord_spacecraft[0]+stx_pointing[0]) + cos(roll_angle) * (xy_coord_spacecraft[1]+stx_pointing[1])
  
endelse

return, xy_coord_final

end