;+
;
; NAME:
;
;   stx_solo2stx_coord
;
; PURPOSE:
;
;   Transform a two-element array of coordinates from the Solar Orbiter coordinate frame to the STIX coordinate frame 
;   and viceversa. Essentially, it performs a 90 deg rotation as STIX is mounted on the side of the spacecraft
;
; CALLING SEQUENCE:
;
;   xy_coord_new = stx_solo2stx_coord(xy_coord)
;
; INPUTS:
;
;   xy_coord: two-element array of coordinates (arcsec). If the 'inverse' keyword is set to 0,
;             the coordinates are assumed to be in the Solar Orbiter coordinate frame and they are transformed 
;             into the corresponding ones in the STIX coordinate frame
;
;
; KEYWORDS:
;
;   inverse: if set, the invese transformation is applied. In this case, the coordinates in 'xy_coord'
;            are assumed to be in the STIX coordinate frame and they are transformed into the corresponding
;            ones in the Solar Orbiter coordinate frame
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

function stx_solo2stx_coord, xy_coord, inverse=inverse

default, inverse, 0

xy_coord_final = fltarr(2)

if ~inverse then begin
  
xy_coord_final[0] =  xy_coord[1]
xy_coord_final[1] = -xy_coord[0]

endif else begin
  
xy_coord_final[0] =  -xy_coord[1]
xy_coord_final[1] = xy_coord[0]

endelse

return, xy_coord_final

end