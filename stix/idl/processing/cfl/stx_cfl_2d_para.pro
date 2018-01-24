;+
; :description:
;    This function creates a 2D paraboloid with different rates of
;    curvature in the X and Y directions. To be used with call to
;    MPFIT2DFUN() in STX_FLARE_LOCATION(), where rates of curvature
;    are forced to be negative (i.e., dropping off to create a peak).
;
; :params:
;    x:  in, required, type="integer"
;        nx-element 1D array of array locations in sky X sampling.
;
;    y:  in, required, type="integer"
;        ny-element 1D array of array locations in sky Y sampling.
;
;    p:  in, required, type="float"
;        5-element 1D array of elliptical paraboloid fit parameters.
;        Array values correspond to:
;           p[0] = parabola maximum value;
;           p[1] = parabola centroid location in X;
;           p[2] = parabola rate of curvature in X;
;           p[3] = parabola centroid location in Y;
;           p[4] = parabola rate of curvature in Y.
;
; :returns:
;    2D array [nx, ny] containing values corresponding to an
;    elliptical paraboloid peak.
;
; :history:
;    21-Aug-2013 - Shaun Bloomfield (TCD), created routine
;
;-
function stx_cfl_2d_para, x, y, p
  
  xim = x # ( (y*0) + 1 )
  yim = ( (x*0) + 1 ) # y
  
  zim = p[0] - ( ( ( xim - p[1] )^2. ) / ( p[2]^2. ) ) - ( ( ( yim - p[3] )^2. ) / ( p[4]^2. ) )
  
  return, zim
  
end
