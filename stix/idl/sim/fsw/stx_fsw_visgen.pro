;---------------------------------------------------------------------------
; Document name: stx_fsw_visgen.pro
; Created by:    Nicky Hochmuth 1.09.2014
;---------------------------------------------------------------------------
;+
; PROJECT:    STIX
;
; NAME:       stx_fsw_visgen
;
; PURPOSE:    generated stix onboard visibilities (unsigned and uncallibrated)
;
; CATEGORY:   STIX FSW
;
; CALLING SEQUENCE:
;
;             STX_VIS = stx_pixel_sums(pixel_data)  optionaly lookups for pixel sumation
;
; HISTORY:
;
;       01.09.2014 Nicky Hochmuth, initial creation
;       06.12.2016 Richard Schwartz, added real_part and imag_part to support telemetry
;       07.12.2016 Richard Schwartz, changed pixel mask defaults to all pixel defaults (rcr < 5) and
;       added keywords specifying level_1, level_2, or level_3 for input.
; :description:
;    Sums each detector pixel columns to 4 virtual pixels and computes the visibility components
;    Returns:
;    ** Structure <4623ea70>, 4 tags, length=1576, data length=1442, refs=1:
;      TYPE            STRING    'stx_fsw_vis_image'
;      RELATIVE_TIME_RANGE
;      DOUBLE    Array[2]
;      ENERGY_SCIENCE_CHANNEL_RANGE
;      BYTE      Array[2]
;      VIS             STRUCT    -> <Anonymous> Array[32]
;      IDL> help, v.VIS,/st
;      ** Structure <1ef8dda0>, 8 tags, length=48, data length=44, refs=3:
;      TYPE            STRING    'stx_fsw_visibility'
;      TOTAL_FLUX      ULONG                0
;      REAL_NEG        ULONG                0
;      REAL_POS        ULONG                0
;      IMAG_NEG        ULONG                0
;      IMAG_POS        ULONG                0
;      REAL_PART       LONG                 0
;      IMAG_PART       LONG                 0
;
; :params:
;    pixel_data : in, required, type="stx_fsw_pixel_data"
;                   a scalar or array of pixel data
;
; :keywords:
;    real_pos :   in, optional, type="byte(12) mask"
;                 a mask which pixels to sum for the minuend of the real part
;
;    real_neg :   in, optional, type="byte(12) mask"
;                 a mask which pixels to sum for the subtrahend of the real part
;
;    imag_pos :   in, optional, type="byte(12) mask"
;                 a mask which pixels to sum for the minuend of the imaginary part
;
;    imag_neg :   in, optional, type="byte(12) mask"
;                 a mask which pixels to sum for the subtrahend of the imaginary part
;
;    total_flux : in, optional, type="byte(12) mask"
;                 a mask which pixels to sum for the total flux
;    level_1 : logical, default is unset,  if set then pixel_data is two ulong values each for real_pos, real_neg, imag_pos, imag_neg, 8 total,
;     may be reconstructed from telemetry, there may be three values, (the two large and small pixel for each Caliste column)
;    level_2 : logical, default is unset,  if set then pixel_data is five long differenced and summed values for real_pos, real_neg, imag_pos, imag_neg, and total_flux,
;     may be reconstructed from telemetry
;    level_3 : logical, default is unset,  if set then pixel_data is three long values, real_part, imag_part, and total_flux which may be reconstructed from telemetry

;
;-

function stx_fsw_visgen, pixel_data, $
  real_pos=real_pos, real_neg=real_neg, imag_neg=imag_neg , imag_pos=imag_pos, total_flux=total_flux, $
  level_1 = level_1, $; masks applied but no summation or differences, so two (maybe three) values each for real_pos, real_neg, imag_pos, imag_neg, 8(12) total
  level_2 = level_2, $; five unsigned values for real_pos, real_neg, imag_pos, imag_neg ( I think there should only be four )
  level_3 = level_3  ; just real_part, imag_part, and total_flux

  level = 0
  case 1 of
    keyword_set( level_1 ): level = 1
    keyword_set( level_2 ): level = 2
    keyword_set( level_3 ): level = 3
    else : level = 0
  endcase
  default, real_pos,   byte([ 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0]) ;C
  default, real_neg,   byte([ 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]) ;A
  default, imag_pos,   byte([ 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1]) ;D
  default, imag_neg,   byte([ 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0]) ;B
  default, total_flux, real_pos + real_neg + imag_pos + imag_neg

  real_pos_idx = where(real_pos ge 1)
  real_neg_idx = where(real_neg ge 1)
  imag_pos_idx = where(imag_pos ge 1)
  imag_neg_idx = where(imag_neg ge 1)
  total_flux_idx = where(total_flux ge 1)

  n_inputs = n_elements(pixel_data)
  ;Add some new fields to stx_fsw_visibility to support the telemetry output, richard.schwartz@nasa.gov, 6-dec-2016
  v   = stx_fsw_vis_image()
  ;vis = add_tag( v.vis, 0L, 'real_part' )
  ;vis = add_tag( vis, 0L, 'imag_part' )
  ;vis = add_tag( vis, 0L, 'sigamp' )
  ;v   = rep_tag_value( v, vis, 'vis' )
  vis = replicate( v, n_inputs)
  
  ;vis = replicate(stx_fsw_vis_image(),n_inputs)
  vis.relative_time_range = pixel_data.relative_time_range
  vis.energy_science_channel_range = pixel_data.energy_science_channel_range
  if level eq 0 then begin
    vis.vis.real_pos = total(pixel_data.counts[real_pos_idx,*],1)
    vis.vis.real_neg = total(pixel_data.counts[real_neg_idx,*],1)
    vis.vis.imag_pos = total(pixel_data.counts[imag_pos_idx,*],1)
    vis.vis.imag_neg = total(pixel_data.counts[imag_neg_idx,*],1)
  endif
  if level eq 1 then begin
    vis.vis.real_pos = total(pixel_data.real_pos_i,1)  ;there are two values for each detector, possibly there could be three but then no savings over 0
    vis.vis.real_neg = total(pixel_data.real_neg_i,1)
    vis.vis.imag_pos = total(pixel_data.imag_pos_i,1)
    vis.vis.imag_neg = total(pixel_data.imag_neg_i,1)
  endif
  if level eq 2 then begin
    vis.vis.real_pos = pixel_data.real_pos
    vis.vis.real_neg = pixel_data.real_neg
    vis.vis.imag_pos = pixel_data.imag_pos
    vis.vis.imag_neg = pixel_data.imag_neg
  endif
  vis.vis.total_flux = vis.vis.real_pos + vis.vis.real_neg + vis.vis.imag_pos + vis.vis.imag_neg
  if level eq 3 then begin
    vis.vis.real_part = pixel_data.real_part
    vis.vis.imag_part = pixel_data.imag_part
    vis.vis.total_flux = pixel_data.total_flux
  endif else begin
    vis.vis.real_part = vis.vis.real_pos - vis.vis.real_neg
    vis.vis.imag_part = vis.vis.imag_pos - vis.vis.imag_neg
    ;vis.vis.total_flux is already computed if we are here
  endelse
  vis.vis.sigamp    = sqrt( vis.vis.total_flux )

  return, vis

end