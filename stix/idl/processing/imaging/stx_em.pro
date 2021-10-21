;+
;
; NAME:
;   stx_em
;
; PURPOSE:
;   This function implements the count-based Expectation Maximization 
;   algorithm (see Massa, P., et al., "Count-based imaging model for the Spectrometer/Telescope for
;   Imaging X-rays (STIX) in Solar Orbiter", 2019).
;
; INPUTS:
;   pixel_data: type="stx_pixel_data_summed"
;               pixel data structure containing photon counts per time, energy, detector, and pixel
;               (the counts registered are summed as if they were recorded by 4 virtual pixels per
;               detector). For details on the summation see the header of 'stx_pixel_sums.pro'.
; KEYWORDS:
;   DET_USED: array containing the indices of detector used 
;             (default is 0-31, 8 and 9 excluded)
;   IMSIZE: output map size in pixels (default is [129, 129])
;   PIXEL: pixel size in arcsec (default is [1., 1.])
;   MAXITER: max number of iterations (default is 5000)
;   TOLERANCE: parameter for the stopping rule (default is 0.01)
;   SILENT: if not set, plots the STD (variable to test convergence) and the
;           C-statistic every 25 iterations
;   MAKEMAP: if set, returns the map structure. Otherwise returns the 2D matrix
;   XYOFFSET: array containing the map center coordinates.
;
; RETURNS:
;   an image (2D matrix) or an image map in the structure format provided by the
;   routine make_map.pro
;
; HISTORY: January 2018, Duval-Poo, M. A., Benvenuto F. created
;          January 2019, Massa P., modified taking into account 
;             -the time range of the measurements 
;             -the xyoffset 
;             -the detector used
;             -the summation of the counts recorded by the pixels.
;             
;CONTACT: massa.p@dima.unige.it
;-
function stx_em, countrates, u, v, phase_corr, IMSIZE=imsize, PIXEL=pixel, XYOFFSET=xyoffset, SUMCASE = sumcase, $
                 MAXITER=maxiter, TOLERANCE=tolerance, SILENT=silent, MAKEMAP=makemap

  default, maxiter, 5000
  default, imsize, [129, 129]
  default, pixel, [1., 1.]
  default, tolerance, 0.001
  default, silent, 0
  default, makemap, 0
  default, xyoffset, [0, 0]
  n_det_used = n_elements(u)
  default, phase_corr, fltarr(n_det_used)
  
  ; input parameters control
  if imsize[0] ne imsize[1] then message, 'Error: imsize must be square.'
  if pixel[0] ne pixel[1] then message, 'Error: pixel size per dimension must be equal.'
  
  

  ; Creation of the matrix 'H' used in the EM algorithm
  H = stx_map2pixelabcd_matrix(imsize, pixel, u, v, phase_corr, xyoffset = xyoffset, SUMCASE = sumcase)

  ; Vectorization of the matrix 'pixel_data.counts' containing the number of counts recorded
  ; by STIX pixels
  y = reform(countrates, n_det_used*4)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; EXPECTATION MAXIMIZATION ALGORITHM

  ;Initialization
  x = fltarr((size(H,/dim))[1]) + 1.
  y_index = where(y gt 0.)
  Ht1 = H ## (y*0.0+1.0)
  H2 = H^2

  if ~keyword_set(silent) then print, 'EM iterations: ' & print, 'N. Iter:      STD:          C-STAT:'

  ; Loop of the algorithm
  for iter = 1, maxiter do begin
    Hx = H # x
    z = f_div(y , Hx)
    Hz = H ## z

    x = x * transpose(f_div(Hz, Ht1))

    cstat = 2. / n_elements(y[y_index]) * total(y[y_index] * alog(f_div(y[y_index],Hx[y_index])) + Hx[y_index] - y[y_index])

    ; Stopping rule
    if iter gt 10 and (iter mod 25) eq 0 then begin
      emp_back_res = total((x * (Ht1 - Hz))^2)
      std_back_res = total(x^2 * (f_div(1.0, Hx) # H2))
      std_index = f_div(emp_back_res, std_back_res)

      if ~keyword_set(silent) then print, iter, std_index, cstat

      if std_index lt tolerance then break
 
    endif
  endfor

  x_im = reform(x, imsize[0],imsize[1])

  return, makemap ? make_map(x_im, xcen=xyoffset[0], ycen=xyoffset[1], dx=pixel[0], dy=pixel[0], id = 'EM') : x_im

end
