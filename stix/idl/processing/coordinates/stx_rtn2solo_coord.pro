;+
;
; NAME:
;
;   stx_rtn2solo_coord
;
; PURPOSE:
;
;   Transform a two-element array of coordinates from Solar Orbiter - Sun Radial-Tnagential-Normal coordinate frame
;   to the Solar Orbiter coordinate frame and viceversa. Essentially, it performs a correction for the instrument pointing
;
; CALLING SEQUENCE:
;
;   xy_coord_new = stx_rtn2solo_coord(xy_coord, aux_data)
;
; INPUTS:
;
;   xy_coord: two-element array of coordinates (arcsec). If the 'inverse' keyword is set to 0,
;             the coordinates are assumed to be in Solar Orbiter - Sun Radial-Tnagential-Normal coordinate frame
;             and they are transformed into the corresponding ones in the Solar Orbiter coordinate frame
;
;   aux_data: 'stx_aux_data' structure containing information on STIX pointing and spacecraft roll angle
;
;
; KEYWORDS:
;
;   inverse: if set, the invese transformation is applied. In this case, the coordinates in 'xy_coord'
;            are assumed to be in the Solar Orbiter coordinate frame and they are transformed
;            into the corresponding ones in the Solar Orbiter - Sun Radial-Tnagential-Normal coordinate frame
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