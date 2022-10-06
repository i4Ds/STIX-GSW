;+
; NAME:
;    fit_map_2dgauss
;
; PURPOSE:
;    Fits a 2D-Gaussian on a previously computed map
;
; CALLING SEQUENCE:
;    fit_map_2dgauss, in_map [, /do_plot]
;
; INPUTS:
;    in_map : a map structure, as returned by imaging functions
;
; OPTIONAL KEYWORD:
;   do_plot : if set, overplots contours at 25%, 50% and 75% of the Gaussian peak on the map
;             (note that the map has to be already plotted in the active window) 
;
; OUTPUTS:
;   None. The centroid positions obtained from Gaussian fitting is printed on screen, in both
;         helioprojective cartesian coordinates and heliographic (Stonyhurst) longitude and latitude
;
; MODIFICATION HISTORY:
;    2022-01-07: F. Schuller (AIP, Germany): created
;
;-
pro fit_map_2dgauss, in_map, do_plot=do_plot
  ; Dimensions of the map array
  if not is_struct(in_map) then begin
    print,"ERROR: input variable is not a structure."
    return
  endif

  sz  = size(in_map.data)
  nbX = sz[1]  &  nbY = sz[2]
  
  ; Fit a 2D-Gaussian to the data
  res = gauss2dfit(in_map.data, coeff, /tilt)
  ; Here are the center coordinates
  gauss_X = in_map.xc + in_map.dx*(coeff[4] - nbX/2.)
  gauss_Y = in_map.yc + in_map.dY*(coeff[5] - nbY/2.)
  print, gauss_X, gauss_Y, format='(" Source centred at X = ",F7.1,"  Y = ",F7.1)'
  roll_xy, gauss_X/60.,gauss_Y/60., -1.*in_map.roll_angle, p1_x, p1_y
  coord = arcmin2hel(p1_x,p1_y, date=in_map.time, rsun=in_map.rsun, b0=in_map.b0, l0=in_map.l0)
  print,coord[1],coord[0],format='("   --> Heliographic LON = ",F7.2," ; LAT = ",F6.2)'

  ; Overplot contours at 25%, 50% and 75% of peak
  if keyword_set(do_plot) then begin
    ; arrays of X and Y coordinates
    x_map = in_map.xc + in_map.dx*(indgen(nbX)-nbX/2.)
    y_map = in_map.yc + in_map.dy*(indgen(nbY)-nbY/2.)
    contour, res, x_map, y_map, levels=max(res)*[0.25,0.5,0.75], /overplot
  endif
end
