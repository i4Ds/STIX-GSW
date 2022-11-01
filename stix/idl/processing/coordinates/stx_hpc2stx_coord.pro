;+
;
; NAME:
;
;   stx_hpc2stx_coord
;
; PURPOSE:
;
;   Transform a two-element array of coordinates from Helioprojective Cartesian coordinate frame
;   (Solar Orbiter vantage point) to STIX coordinate frame and viceversa
;
; CALLING SEQUENCE:
;
;   xy_coord_new = stx_hpc2stx_coord(xy_coord, aux_data)
;
; INPUTS:
;
;   xy_coord: two-element array of coordinates (arcsec). If the 'inverse' keyword is set to 0,
;             the coordinates are assumed to be in the Helioprojective Cartesian coordinate frame
;             (Solar Orbiter vantage point) and they are transformed into the corresponding ones
;             in the STIX coordinate frame
;
;   aux_data: 'stx_aux_data' structure containing information on STIX pointing and spacecraft roll angle
;
;
; KEYWORDS:
;
;   inverse: if set, the inverse transformation is applied. In this case, the coordinates in 'xy_coord'
;            are assumed to be in the STIX coordinate frame and they are transformed into the corresponding
;            ones in the Helioprojective Cartesian coordinate frame
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

function stx_hpc2stx_coord, xy_coord, aux_data, inverse=inverse

default, stx_offset, [0.,0.]
default, stx_rotat, 90.
default, inverse, 0
  
if ~inverse then begin
  
  xy_coord_rtn   = stx_hpc2rtn_coord(xy_coord, aux_data, inverse=inverse)
  xy_coord_solo  = stx_rtn2solo_coord(xy_coord_rtn, aux_data, inverse=inverse)
  xy_coord_final = stx_solo2stx_coord(xy_coord_solo, inverse=inverse)
  
endif else begin
  
  
  xy_coord_solo  = stx_solo2stx_coord(xy_coord, inverse=inverse)
  xy_coord_rtn   = stx_rtn2solo_coord(xy_coord_solo, aux_data, inverse=inverse)
  xy_coord_final = stx_hpc2rtn_coord(xy_coord_rtn, aux_data, inverse=inverse)
  
endelse
  
return, xy_coord_final

end