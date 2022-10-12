;+
;
; NAME:
;
;   stx_hpc2rtn_coord
;
; PURPOSE:
;
;   Transform a two-element array of coordinates from Helioprojective Cartesian coordinate frame
;   (Solar Orbiter vantage point) to the Solar Orbiter - Sun Radial-Tnagential-Normal coordinate frame and viceversa.
;   Essentially, it performs a rotation for the spacecraft roll angle
;
; CALLING SEQUENCE:
;
;   xy_coord_new = stx_hpc2rtn_coord(xy_coord, aux_data)
;
; INPUTS:
;
;   xy_coord: two-element array of coordinates (arcsec). If the 'inverse' keyword is set to 0,
;             the coordinates are assumed to be in the Helioprojective Cartesian coordinate frame
;             (Solar Orbiter vantage point) and they are transformed into the corresponding ones
;             in the Solar Orbiter - Sun Radial-Tnagential-Normal coordinate frame
;
;   aux_data: 'stx_aux_data' structure containing information on STIX pointing and spacecraft roll angle
;
;
; KEYWORDS:
;
;   inverse: if set, the invese transformation is applied. In this case, the coordinates in 'xy_coord'
;            are assumed to be in the Solar Orbiter - Sun Radial-Tnagential-Normal and they are transformed 
;            into the corresponding ones in the Helioprojective Cartesian coordinate frame
;
;
; OUTPUTS:
;
;   A two-element array containing the transformed coordinates
;
; HISTORY: August 2022, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-

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