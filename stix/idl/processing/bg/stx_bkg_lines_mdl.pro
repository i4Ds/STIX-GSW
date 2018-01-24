;+
; :Description:
;    Describe the procedure.
;
; :Params:
;    edg2  - energy array in keV, fltarr, 2xn
;    counts_per_day - counts per day in the cal lines, default is 9000 per day in a large pixel
;
; :Keywords:
;    per_sec - if set, normalize to per_day
;    per_kev - if set, normalize to per keV
;    gauss_line_param - cal line parameters, default: [  1, 31, 1., .15, 81, 1.5 ]
;
; :Author: richard.schwartz@nasa.gov, 27-jun-2017
; 29-nov-2017, RAS, updated
;-

function stx_bkg_lines_mdl, edg2, counts_per_day, per_sec = per_sec, per_kev = per_kev, $
  time_interval = time_interval, $
  gauss_line_param = gauss_line_param, hecht_par = hecht_par, spectrogram = spectrogram 

  if n_elements( edg2 ) le 2 then begin
    edg2 = get_edges( /edges_2, findgen(1500) * 0.1 )
    em  = get_edges( edg2, /mean)
  endif 
  edge_products, edg2, mean = em, width = de
  default, time_interval, ['1-jan-2019','2-jan-2019']
  default, counts_per_day, 12000 ;assumes 20 Bq source dots by cruise
  kev35 = transpose( [[0.06, .116, 0.0358], [34.92, 34.987, 35.818],  [1,1,1]  ])
  kev31 = [[  0.35, 30.625, 1.], [0.65, 30.973, 1]] 
  kev81 = [.25, 81, 1.5]
  default, gauss_line_param, [ kev31[*], kev35[*], kev81[*] ]
  ;add calibration lines
  lines = mgauss( em, [fltarr(3), gauss_line_param])
  out = lines *  counts_per_day / 21.71256
  out = keyword_set(  per_sec ) ? out / 86400. : out
  out = keyword_set(  per_kev ) ? out / de : out
  edg1 = get_edges( /edges_1, edg2 )
  if keyword_set( per_kev ) then out /= (edg2[1,3]-edg2[0,3])
  if keyword_set( per_sec ) then out /= 86400.0
  time_axis = stx_construct_time_axis( time_interval )
  energy_axis = stx_construct_energy_axis( energy = edg1, $
    sele = lindgen( n_elements( edg1 ) ) )
  data = reform( out, n_elements(out), 1 )
  livetime = reform( data*0.0+1., n_elements(out), 1 )
  sp = stx_spectrogram( data, time_axis, energy_axis, livetime )
  spectrogram = rep_tag_value( sp, double(sp.data),'data')
  ;spectrogram = stx_spectrg

  return, out >0
end

