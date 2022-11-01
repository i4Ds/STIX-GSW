;+
;
; NAME:
;
;   stx_rtn2stx_coord
;
; PURPOSE:
;
;   Transform a bi-dimensional array of coordinates from Solar Orbiter - Sun Radial-Tnagential-Normal coordinate frame
;   to the STIX coordinate frame and viceversa
;
; CALLING SEQUENCE:
;
;   xy_coord_new = stx_rtn2stx_coord(xy_coord, aux_data)
;
; INPUTS:
;
;   xy_coord: bi-dimensional array of coordinates (arcsec). If the 'inverse' keyword is set to 0,
;             the coordinates are assumed to be in Solar Orbiter - Sun Radial-Tnagential-Normal coordinate frame
;             and they are transformed into the corresponding ones in the STIX coordinate frame
;
;   aux_data: 'stx_aux_data' structure containing information on STIX pointing and spacecraft roll angle
;
;
; KEYWORDS:
;
;   inverse: if set, the invese transformation is applied. In this case, the coordinates in 'xy_coord'
;            are assumed to be in the Solar Orbiter - Sun Radial-Tnagential-Normal coordinate frame and they are transformed
;            into the corresponding ones in the STIX coordinate frame
;
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



function stx_rtn2stx_coord, xy_coord, aux_data, inverse=inverse

default, stx_offset, [0.,0.]
default, stx_rotat, 90.
default, inverse, 0


if ~inverse then begin
  
  xy_coord_solo  = stx_rtn2solo_coord(xy_coord, aux_data, inverse=inverse)
  xy_coord_final = stx_solo2stx_coord(xy_coord_solo, inverse=inverse)

endif else begin
  
  xy_coord_solo  = stx_solo2stx_coord(xy_coord, inverse=inverse)
  xy_coord_final = stx_rtn2solo_coord(xy_coord_solo, aux_data, inverse=inverse)

endelse

return, xy_coord_final

end