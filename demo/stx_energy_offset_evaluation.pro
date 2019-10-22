;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; :Description:
;    This procedure evaluates the changes in simple images due to rate dependent
;    adc offsets as well as how well a simple linear interpolation correction strategy performs
;
; :Params:
;    source_map - map structure with image data for evaluation
;    cspec - 32 science channel spectrum integrated over 100 adc offsets from
;    0.0 - 1.0 keV in 100 uniform steps, fltarr(  32, 100 )
;    rspec - cspec rebinned using linear interpolation on the science channels to
;     correct the offset shifts, fltarr( 32, 100 )
;
;    allvis - obsvis and totflux for 32 science channels for cspec perfect, offset, corrected
;        IDL> help, allvis,/st  structure( 32, 3)
;        ** Structure <207188d0>, 2 tags, length=360, data length=360, refs=1:
;        OBSVIS          COMPLEX   Array[30]
;        TOTFLUX         FLOAT     Array[30]
;
;    allsrc - results from allvis with vis_fwdfit for ellipse default. allvis copied into
;     stix visibilities,
;        IDL> help, allsrc,/st  structure( 32, 3)
;        ** Structure VIS_SRC_STRUCTURE, 10 tags, length=56, data length=52:
;        SRCTYPE         STRING    'ellipse'
;        SRCFLUX         FLOAT         0.0234737
;        SRCX            FLOAT           3.99996
;        SRCY            FLOAT           8.00015
;        SRCFWHM         FLOAT           6.01739
;        ECCEN           FLOAT          0.745063
;        SRCPA           FLOAT           89.9835
;        LOOP_ANGLE      FLOAT          0.000000
;        ALBEDO_RATIO    FLOAT          0.000000
;        SRCHEIGHT       FLOAT          0.000000
;
;
;
; :Author: raschwar,
; :History: 13-oct-2017
;-
pro stx_energy_offset_evaluation, source_map, cspec, rspec, allvis, allsrc
  pp = stx_map2pixelabcd( source_map)

  ov = stx_pixel2obsvis( pp, stx_vis = svm, totflux=tflux )
  ;max per 1 caliste 3000
  ;max per column 6000
  scale = 6000/max(pp)
  ppm = scale * pp
  kev_shift = stx_rate_shift( ppm/2., /kev)
  sc_diff_kev = fltarr(30)
  for i=0,29 do begin
    mm = minmax( kev_shift[*,i])
    sc_diff_kev[i] = mm[1]-mm[0]
  endfor
  ;Find the offset index for each Caliste
  index_kev_shift = fix( interpol( dindgen(100), findgen(100)*.01, kev_shift))<99
  allspectra = fltarr( 32, 4, 30, 3)
  ;cspec are count spectra for one spectrum for 32 science channels. The rebinned shifted counts are in the
  ;0-99 positions.  The base unshifted counts are in the 0th position.
  ;pp are for the four moire columns, j is for the 30 stix scs
  ;rspec are the corrected cspec using linear rebinning but on the coarser science channel scale
  for i = 0, 3 do for j = 0, 29 do allspectra[ 0, i, j, 0] = cspec[ *, 0 ] * pp[i,j]

  for i = 0, 3 do for j = 0, 29 do allspectra[ 0, i, j, 1] = cspec[ *, index_kev_shift[i,j] ] * pp[i,j]

  for i = 0, 3 do for j = 0, 29 do allspectra[ 0, i, j, 2] = rspec[ *, index_kev_shift[i,j] ] * pp[i,j]

  ;Now make visibility amp for both sets
  allvis = replicate( { obsvis: complexarr(30), totflux: fltarr(30) }, 32, 3)
  allsrc = replicate( { vis_src_structure }, 32, 3 )
  sv = svm
  for j= 0, 2 do begin ;j goes from perfect to offset to corrected
    for i = 0, 31 do begin ;i steps over science channels, 30 or 32 not critical
      ovi = stx_pixel2obsvis( reform( allspectra[ i, *, *, j]), stx_vis=svm, totflux = tfluxi )
      allvis[ i, j ].obsvis = ovi
      allvis[ i, j ].totflux = tfluxi
      sv.obsvis = ovi
      sv.totflux = tfluxi
      vis_fwdfit, sv, srcout = eclipse, /noplotfit,/quiet
      allsrc[i,j] = eclipse

    endfor
  endfor

end
