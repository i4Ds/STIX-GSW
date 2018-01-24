
;+
; :Description:
;    This function computes the complex visibility from the summed pixel (Caliste) columns
;
; :Params:
;    pixeldata - 4 x 30 or 30 x 4 pixel data derived from 12 x 30 count data, sum over columns to get four moire components

; :Keywords:
;    stx_vis - stix visibility structure
;    totflux - 30 returned sums from pxldata
;    insert_obsvis - logical, if set then set stx_vis obvis and totflux from pxldata
;
; :Author: rschwartz70@gmail.com
; :History: written 10-oct-2017

;-
function stx_pixel2obsvis, pixeldata, stx_vis = stx_vis, totflux = totflux, insert_obsvis = insert_obsvis

  if ~is_struct( stx_vis ) || ~(get_tag_value( stx_vis[0], /type) eq 'stx_visibility') then begin
    subc_str = stx_construct_subcollimator()
    stx_vis  = stx_construct_visibility( subc_str )
  endif
  
  dim = size( /dimension, pixeldata )
  pxldata =  dim[0]/dim[1] eq 0 ? pixeldata : transpose( pixeldata )
  ; calculate C - A, D - B, and total flux for each detector and save it to their proper array
  vis_cmina = reform( float( pxldata[ 2, * ] ) - float( pxldata[ 0, *] ) )
  vis_dminb = reform( float( pxldata[ 3, * ] ) - float( pxldata[ 1, * ] ) )
  totflux   = reform( total( pxldata, 1) )

  ; vis_cmina and vis_cminb are the real and imaginary part of the uncalibrated visibilities
  ; define uncalibrated visibilities
  viscomp = complex(vis_cmina, vis_dminb)
  ; now calibrate by correcting for phase-shift
  vphase_shift = !PI / 4.0
  ;   express phase shift as complex number in cartesian representation
  vphase_shift = complex( cos( vphase_shift ), sin( vphase_shift ))
  ;   vphase_shift is computed outside of the loop
  ; apply phase shift to uncalibrated visibilities
  obsvis = viscomp * vphase_shift

  ; apply grid phase sense correction (obsvis)
  obsvis = complex( real_part(obsvis), -stx_vis.phase_sense * imaginary(obsvis) )
  if keyword_set( insert_obsvis ) then begin
    stx_vis.obsvis = obsvis
    stx_vis.totflux = totflux
  endif

  return, obsvis
end