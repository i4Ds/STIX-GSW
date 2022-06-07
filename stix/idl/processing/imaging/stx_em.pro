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
;          June 2022, Massa P., 'aux_data' added
;             
;CONTACT: massa.p@dima.unige.it

FUNCTION stx_em,countrates,energy_range,time_range,aux_data,IMSIZE=imsize,PIXEL=pixel,MAPCENTER=mapcenter, WHICH_PIX=which_pix, $
  subc_index=subc_index, MAXITER=maxiter, TOLERANCE=tolerance, SILENT=silent, MAKEMAP=makemap, XY_FLARE=xy_flare

default, which_pix, 'TOP+BOT'
default, subc_index, stix_label2ind(['3a','3b','3c','4a','4b','4c','5a','5b','5c','6a','6b','6c',$
                                       '7a','7b','7c','8a','8b','8c','9a','9b','9c','10a','10b','10c'])

default, maxiter, 5000
default, imsize, [129, 129]
default, pixel, [1., 1.]
default, tolerance, 0.001
default, silent, 0
default, makemap, 0
default, mapcenter, [0, 0]
default, xy_flare, [0.,0.]
n_det_used = n_elements(subc_index)
default, phase_corr, fltarr(n_det_used)

; input parameters control
if imsize[0] ne imsize[1] then message, 'Error: imsize must be square.'
if pixel[0] ne pixel[1] then message, 'Error: pixel size per dimension must be equal.'

;;;;;;;;;; Before

subc_str = stx_construct_subcollimator()

; Grid correction
phase_cal = read_csv(loc_file( 'GridCorrection.csv', path = getenv('STX_VIS_DEMO') ), header=header, table_header=tableheader, n_table_header=2 )
phase_corr = phase_cal.field2

; Phase correction
phase_cal = read_csv(loc_file( 'PhaseCorrFactors.csv', path = getenv('STX_VIS_DEMO')), header=header, table_header=tableheader, n_table_header=3 )
phase_corr += phase_cal.field2

; Pixel correction
phase_corr += 46.1

phase_corr *= !dtor

; Sum over top and bottom pixels
case which_pix of

  'TOP': begin
    pixel_ind = [0]
  end

  'BOT': begin
    pixel_ind = [1]
  end

  'TOP+BOT': begin
    pixel_ind = [0,1]
  end

endcase

pix = reform(countrates, 32, 4, 3)
countrates = n_elements( pixel_ind ) eq 1 ? reform(pix[*, *, pixel_ind , *]) : total( pix[*, *, pixel_ind, *], 3 )

eff_area = subc_str.det.pixel.area
eff_area = reform(transpose(eff_area), 32, 4, 3)
eff_area = n_elements( pixel_ind ) eq 1 ? reform(eff_area[*, *, pixel_ind , *]) : total(eff_area[*,*,pixel_ind], 3)

; To make the units: counts s^-1 keV^-1 cm^-2
countrates = countrates/eff_area
this_gtrans = stix_gtrans32_test_sep_2021(xy_flare)
for i=0,31 do begin
  countrates(i,*)=countrates(i,*) * this_gtrans(i) * 4.
endfor
countrates = countrates[subc_index, *]

uv = stx_uv_points_giordano()
u = -uv.u * subc_str.phase
v = -uv.v * subc_str.phase
u = u[subc_index]
v = v[subc_index]

phase_corr = phase_corr[subc_index]

;;;;;;;;;;;;
; Correct mapcenter:
; - if 'aux_data' contains the SAS solution, then we read it and we correct tha map center accordingly
; - if 'aux_data' does not contain the SAS solution, then we apply an average shift value to the map center
readcol, loc_file( 'Mapcenter_correction_factors.csv', path = getenv('STX_VIS_DEMO') ), $
  avg_shift_x, avg_shift_y, offset_x, offset_y
if ~aux_data.X_SAS.isnan() and ~aux_data.Y_SAS.isnan() then begin
  ; coor_mapcenter = SAS solution + discrepancy factor
  stx_pointing = [aux_data.X_SAS, aux_data.Y_SAS] + [offset_x, offset_y]
endif else begin
  ; coor_mapcenter = average SAS solution + spacecraft pointing measurement
  stx_pointing = [avg_shift_x,avg_shift_y] + [aux_data.YAW, aux_data.PITCH]
endelse

; Compute the mapcenter
;this_mapcenter = mapcenter - stx_pointing

roll_angle = aux_data.ROLL_ANGLE * !dtor

this_xy_flare = xy_flare
this_xy_flare[0] = cos(roll_angle)  * xy_flare[0] + sin(roll_angle) * xy_flare[1] - stx_pointing[0]
this_xy_flare[1] = -sin(roll_angle) * xy_flare[0] + cos(roll_angle) * xy_flare[1] - stx_pointing[1]

; Correct the mapcenter
this_mapcenter = mapcenter
this_mapcenter[0] = cos(roll_angle)  * mapcenter[0] + sin(roll_angle) * mapcenter[1] - stx_pointing[0]
this_mapcenter[1] = -sin(roll_angle) * mapcenter[0] + cos(roll_angle) * mapcenter[1] - stx_pointing[1]


XYOFFSET=[this_mapcenter[1], -this_mapcenter[0]]

; Creation of the matrix 'H' used in the EM algorithm
H = stx_map2pixelabcd_matrix(imsize, pixel, u, v, phase_corr, xyoffset = XYOFFSET, SUMCASE = 1)

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

;;;;;;;;;;;; After

em_map = make_map(x_im)
this_estring=strtrim(fix(energy_range[0]),2)+'-'+strtrim(fix(energy_range[1]),2)+' keV'
em_map.ID = 'STIX EM '+this_estring+': '
em_map.dx = pixel[0]
em_map.dy = pixel[1]


em_map.time = anytim((anytim(time_range[1])+anytim(time_range[0]))/2.,/vms)

em_map.DUR = anytim(time_range[1])-anytim(time_range[0])

;rotate map to heliocentric view
em__map=em_map
em__map.data=rotate(em_map.data,1)


em__map.xc = this_mapcenter[0] + stx_pointing[0]
em__map.yc = this_mapcenter[1] + stx_pointing[1]

em__map=rot_map(em__map,-aux_data.ROLL_ANGLE,rcenter=[0.,0.])
em__map.ROLL_ANGLE = 0.
add_prop,em__map,rsun = aux_data.RSUN
add_prop,em__map,B0   = aux_data.B0
add_prop,em__map,L0   = aux_data.L0

return,em__map

end