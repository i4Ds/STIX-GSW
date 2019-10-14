;+
; :Description:
;    Describe the procedure.
;
; :Params:
;    edg2  - energy array in keV, fltarr, 2xn, edg2 coming from continuum model on these bins
;     so normally need these to be unchanged internally
;    counts_per_day - counts per day in the cal lines, default is 9000 per day in a large pixel
;
; :Keywords:
;    per_sec - if set, normalize to per_day
;    per_kev - if set, normalize to per keV
;    gauss_line_param - cal line parameters, default: [  1, 31, 1., .15, 81, 1.5 ]
;     to be used with f_nline function
;    time_interval - data interval, default is ['1-jan-2019','2-jan-2019'], only a label
;    hecht_par - unused, reserved for later to describe non-Gaussian line shapes
;    spectrogram - returned spectrogram
;
; :Author: richard.schwartz@nasa.gov, 27-jun-2017
; 29-nov-2017, RAS, updated
; 03-may-2018, RAS, using f_line instead of mgauss, sourcing the default for the line
; parameters from stx_cal_lines_mdl()
;-

function stx_bkg_lines_mdl, edg2, counts_per_day, per_sec = per_sec, per_kev = per_kev, $
  time_interval = time_interval,$
  gauss_line_param = gauss_line_param, hecht_par = hecht_par, spectrogram = spectrogram 

  default, gain_str, { gain: 0.1, offset: 0.0 } ; unit keV / bin, offset is keV at 0 channel edge
  if n_elements( edg2 ) le 2 then begin
    edg2 = get_edges( /edges_2, findgen(1500) * gain_str.gain ) + gain_str.offset
    em  = get_edges( edg2, /mean)
  endif 
  edge_products, edg2, mean = em, width = de
  default, time_interval, ['1-jan-2019','2-jan-2019']
  default, counts_per_day, 9000 ;assumes 20 Bq source dots by cruise
  
  default, gauss_line_param, stx_cal_lines_mdl()
;  0.350000      30.6250     0.424661     0.650000      30.9730     0.424661    0.0600000      34.9200     0.424661     0.116000      34.9870     0.424661
;  0.0358000      35.8180     0.424661     0.250000      81.0000     0.636991
  
  ;add calibration lines
  lines = f_nline( em,  gauss_line_param)
   
  out = lines *  counts_per_day / total( lines )
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

