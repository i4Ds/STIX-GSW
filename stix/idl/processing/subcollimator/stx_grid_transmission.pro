;+
;
; NAME:
;
;   stx_grid_transmission
;
; PURPOSE:
;
;   Compute the trasmission of a STIX grid corrected for internal shadowing
;
; CALLING SEQUENCE:
;
;   int_shadow = stx_grid_transmission(x_flare, y_flare, grid_orient, grid_pitch, grid_slit, grid_thick)
;
; INPUTS:
; 
;   x_flare: X coordinate of the flare location (arcsec, in the STIX coordinate frame)
;   
;   y_flare: Y coordinate of the flare location (arcsec, in the STIX coordinate frame)
;
;   grid_orient: orientation angle of the slits of the grid (looking from detector side, in degrees)
;
;   grid_pitch: dimension of pitch of the grid (mm)
;   
;   grid_slit: dimension of slit of the grid (mm)
;   
;   grid_thick: thickness of the grid (mm)
;
; OUTPUTS:
;
;   A float number that represent the grid transmission value
;
; HISTORY: August 2022, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-


function stx_grid_transmission, x_flare, y_flare, grid_orient, grid_pitch, grid_slit, grid_thick

  ;; Distance of the flare on the axis perpendicular to the grid orientation
  flare_dist   = abs(x_flare * cos(grid_orient * !dtor) + y_flare * sin(grid_orient * !dtor))
  
  ;; Internal shadowing
  shadow_width = grid_thick  * tan(flare_dist / 3600. * !dtor)
  
  return, (grid_slit - shadow_width) / grid_pitch


end