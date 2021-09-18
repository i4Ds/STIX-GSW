;+
;
; NAME:
;   stx_map2pixelabcd_matrix
;
; PURPOSE:
;   This function creates the matrix H that maps a vectorized flare image into an array containing 
;   the set of counts recorded by STIX pixels (for further details see Massa, P., et al., 
;   "Count-based imaging model for the Spectrometer/Telescope for Imaging X-rays (STIX) in Solar Orbiter", 2019)
;
; INPUTS:
;   imsize: array containing the size (number of pixels) of the image
;   pixel: array containing the pixel size (in arcsec) of the image
;   
; KEYWORDS:
;   XYOFFSET: array containing the coordinates of the center of the map (default is [0., 0.])
;   DURATION: duration of the flaring event (default is 1 sec)
;   DET_USED: array containing the indices of the detectors used (default is 0-31, 8 and 9 excluded)
;   SUMCASE: indicates which of the 12 pixels are summed to build the 4 virtual pixels (it is needed to 
;            compute the right value for the effective area). For further details on the summation 
;            see the header of 'stx_pixel_sums.pro'.
;  
; RETURNS:
;   A matrix that maps a vectorized flare image into an array containing the set of counts recorded by STIX pixels
;
; HISTORY: January 2018, Duval-Poo, M. A. and Benvenuto F. created
;          January 2019, Massa P. modified taking into account:
;           -constant factors M0, M1 (see papers: Giordano S. et al, "The process of data formation for the
;          Spectrometer/Telescope for Imaging X-rays (STIX) in Solar Orbiter" (2015)
;          and Massa P. et al., "Count-based imaging model for the Spectrometer/Telescope for
;          Imaging X-rays (STIX) in Solar Orbiter" (2019))
;          -xyoffset
;          -duration
;          -detector used
;          -sumcase
;
;CONTACT: massa.p@dima.unige.it
;-

function stx_map2pixelabcd_matrix, imsize, pixel, u, v, phase_corr, XYOFFSET=xyoffset, SUMCASE = sumcase

  default, xyoffset, [0., 0.]
  n_det_idx = n_elements(u)
  default, phase_corr, fltarr(n_det_idx)

;  subc_str = stx_construct_subcollimator()
  fact = 1.
;  case sumcase of
;    0: begin
;      indices = [0, 1] ;two big pixels used
;    end
;    1: begin
;      indices = indgen(3) ;two big pixels and small pixel used
;    end
;    2: begin
;      indices = [0] ;upper row pixels used
;    end
;    3: begin
;      indices = [1] ;'lower row pixels used
;    end
;    4: begin
;      indices = [2] ;small pixels used
;      fact=2.
;    end
;  endcase
;  
;  ;Computation of the effective area of the pixels used
;  tmp = subc_str.det.pixel.area
;  tmp = reform(tmp[*, 0], 4, 3)
;  tmp = reform(tmp[0, *])
;  effective_area = total(tmp[indices])
  if sumcase eq 4 then fact = 2.
  effective_area = 1.
  
  ; Computation of the constant factors M0 and M1
  M0 = effective_area/4.
  M1 = effective_area *fact* 4./(!pi^3.)*sin(!pi/(4.*fact))
  

  ; Initialization of the matrix 'H'
  npx2  = long(imsize[0])*long(imsize[1])
  H = dblarr(n_det_idx*4, npx2)
  
  ; Discretization of the Sun domain (multiplied by 2 pi)
  xypi = Reform( ( Pixel_coord( [imsize[0], imsize[1]] ) ), 2, imsize[0], imsize[1] )
  xypi[0, *, *] = xypi[0, *, *] * pixel[0] + xyoffset[0]
  xypi[1, *, *] = xypi[1, *, *] * pixel[0] + xyoffset[1]
  xypi = xypi * (2.0 * !pi)

  for i=0,n_det_idx-1 do begin
    
    phase =  u[i] * reform( xypi[0,*,*], npx2) + v[i] * reform( xypi[1,*,*], npx2) - phase_corr[i]

    H[i, *] = -cos(phase)
    H[n_det_idx + i, *] =  -sin(phase) 
    H[2*n_det_idx + i, *] = cos(phase) 
    H[3*n_det_idx + i, *] =  sin(phase) 

  endfor
  
  ; Application of the correction factors (needed because the units of the flux are photons s^-1 cm^-2 arcsec^-2)
  H = H * 2. * M1 + M0
  H = H * (pixel[0]*pixel[1])
  return, H

end
