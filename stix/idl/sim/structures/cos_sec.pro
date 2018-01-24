;+
; :Description:
;    Integrate a cos function with an offset over
;    four equal intervals from 0 to 2pi as for a STIX moire pattern
;
; :Params:
;    theta - offset angle in radians
;
;
;
; :Author: rschwartz70@gmail.com
; :History: written 10-oct-2017
;-
function cos_sec, theta
  n = findgen(4)
  sdim = [4, n_elements( theta ) ]
  n = rebin( n, sdim )
  theta4 = rebin( reform( theta, 1, sdim[1]), sdim )
  p2 = !pi/2
  return, p2 + (  sin( (n+1)*p2  + theta4 ) - sin( n * p2 + theta4 ) )
end