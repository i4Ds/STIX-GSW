;+
; :description:
;    Helper method for calculate the sin functions fitting the pixels best for the plotting
;
; :params:
;    x : x value
;    pixels : the pixel data [A,B,C,D]
;
;-
function stx_sine, x, pixels 
  A = pixels[0]
  B = pixels[1]
  C = pixels[2]
  D = pixels[3]
  
  a = sqrt(2d)/4d * sqrt((A-C)^2 + (D-B)^2)
  
  k = mean(pixels)
  
  p = atan(D-B,A-C) + (!pi/4.d)
  
  return,   a * sin( x + p) + k
end
