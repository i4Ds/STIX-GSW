;+
; :Description:
;    Describe the procedure.
;
; :Params:
;    source_map - optional image within a map__define structure, default map provided
;      IDL> help, source_map
;      ** Structure <102d9850>, 12 tags, length=409728, data length=409724, refs=1:
;      DATA            FLOAT     Array[320, 320]
;      XC              DOUBLE          0.00000000
;      YC              DOUBLE          0.00000000
;      DX              DOUBLE          0.20000000
;      DY              DOUBLE          0.20000000
;      TIME            STRING    '12-Feb-2002 00:00:00.000'
;      ID              STRING    ''
;      DUR             FLOAT          0.000000
;      XUNITS          STRING    'arcsec'
;      YUNITS          STRING    'arcsec'
;      ROLL_ANGLE      DOUBLE          0.00000000
;      ROLL_CENTER     DOUBLE    Array[2];
;
;
; :Author: rschwartz70@gmail.com
; :History: written 10-oct-2017

;-
function stx_map2pixelabcd, source_map, svm=svm

  subc_str = stx_construct_subcollimator()
  svis = stx_construct_visibility( subc_str )

  if ~exist( source_map ) then begin
    source = hsi_gauss_source_def()
    source.xysigma = [3., 2.]
    source.xyshift_asec = [4,8]
    source_map =  hsi_source_map( source, dpx=0.5, /str )
  endif

  svm = vis_map2vis( source_map, xy, svis)
  ;add the totflux which we take as the max of abs(obsvis)
  svm.totflux = total( source_map.data ) ;totflux relative to obsvis, independent of units of source_map, max( abs( svm.obsvis ))
  zphase_sense = where( svm.phase_sense eq 1 )

  svm.time_range.value = reform( reproduce( anytim(/mjd,'4-oct-2017'), 60), 2, 30)

  vphase_shift = !PI / 4.0

  ; Express phase shift as complex number in cartesian representation
  vphase_shift = complex( cos( vphase_shift ), sin( vphase_shift ))
  ipart  = imaginary( -svm.obsvis )
  ipart[zphase_sense] *= -1
  stheta = atan( ipart, real_part( svm.obsvis ) )+!pi
  ;istheta = interpol( dindgen( 1000), thetai, stheta )
  ;ristheta = round( istheta )
  ptheta = cos_sec( stheta ) ;These are the relative pixel values after subtracting the DC component
  cma = ptheta[2,*] - ptheta[0,*]
  dmb = ptheta[3,*] - ptheta[1,*]
  obsvis = complex( cma, dmb ) * vphase_shift
  obsvis[ zphase_sense ] = complex( real_part( obsvis[ zphase_sense ] ), -imaginary( obsvis[ zphase_sense ] ))
  ;Ratio of abs( obsvis ) /totflux
  ratio = abs( svm.obsvis ) / svm.totflux ;coarse grids closer to 1
  ;
  ;scale ptheta by ratio
  tptheta = total( ptheta, 1)
  ;normalize to 1
  ;ptheta /= rebin( reform(  tptheta, 1, 30), 4, 30 )
  ;scale to ratio
;  ptheta *= rebin( reform( ratio, 1, 30), 4, 30 )
  
;  max_p   = max( total( ptheta,1 ))
;  base    = (max_p - ratio)/4
;  ptheta  += rebin( reform( base, 1, 30), 4, 30)
  return, ptheta
end