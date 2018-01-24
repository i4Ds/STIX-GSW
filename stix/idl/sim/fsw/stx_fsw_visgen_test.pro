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
;      SIGAMP          LONG                 0
;
; :params:
;    pixel_data : in, required, type="stx_fsw_pixel_data"
;                   a scalar or array of pixel data structure
;                   The type, 'stx_fsw_pixel_data' is only used for the default level 0, all pixels input
;                   Level_1, Level_2, Level_3 all have new input formats consistent with the sd telemetry level compression level
;                   For all cases Level 0-3 the data may be raw or compressed-uncompressed
;                   For Level_1 and Level_2 compression, these data can simply replace the values in the first four
;                   pixels of pixel_data.counts[0:3,*] or pixel_data.counts[0:7] and setting the remaining pixels to zero
;                   If the rcr is 5 or greater, and you use the pixel_masks for that value, then pixels[8:11] must be populated
;                   according to the mask. For level 3, we only have three values for each energy,time,detector set and they 
;                   real_part, imag_part, and total_flux. Real_part and Imag_part may be positive or negative coming
;                   from the compression (decompression) scheme.  STX_FSW_PIXEL_DATA is unsigned. They may be inserted into
;                   pixel_data.counts if negative by inserting the absolute value into real_neg and imag_neg instead
;                   of imag_pos or imag_neg as the case may be.
;
;    total_flux_level_3:  Level_3 requires the total_flux to be passed as an array from the level 3 compression.  
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
;                 a mask which pixels to sum for the total flux used to compute the real_pos, real_neg, imag_pos, and imag_neg components

; :HISTORY:
;
;       01.09.2014 Nicky Hochmuth, initial creation
;       06.12.2016 Richard Schwartz, added real_part and imag_part to support telemetry
;       11.12.2016 Richard Schwartz, changed pixel mask defaults to all pixel defaults (rcr < 5)
;       pixel_data.counts can be loaded with the output of the uncompressed pixel values in accordance with the masks
;       so this module can now process the output of level 0, 1, 2, and 3.
;       Compatible with its current use but expanded so it can serve as the visibility component receptacle for level 0, 1, 2, 3 telemetry.
;       The output then is to be directed to stx_visgen along with other software that handles the RCR area
;       correction along with difference in attenuator. There may be exceptions that have to be coded for sigamp!
;
;
;-

function stx_fsw_visgen, pixel_data, total_flux_level_3, $
  real_pos=real_pos, real_neg=real_neg, imag_neg=imag_neg , imag_pos=imag_pos, total_flux=total_flux
  

  default, real_pos,   byte([ 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0]) ;C
  default, real_neg,   byte([ 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]) ;A
  default, imag_pos,   byte([ 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1]) ;D
  default, imag_neg,   byte([ 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0]) ;B
  default, total_flux, bytarr(12) + 1b

  real_pos_idx = where(real_pos ge 1)
  real_neg_idx = where(real_neg ge 1)
  imag_pos_idx = where(imag_pos ge 1)
  imag_neg_idx = where(imag_neg ge 1)
  total_flux_idx = where(total_flux ge 1)

  n_inputs = n_elements(pixel_data)
  ;Add some new fields to stx_fsw_visibility to support the telemetry output, richard.schwartz@nasa.gov, 6-dec-2016
  v   = stx_fsw_vis_image()
  ;Separate and use v.vis as vis. Add new tags to vis, then replace the 'vis' field in v
  vis = add_tag( v.vis, 0L, 'real_part' )
  vis = add_tag(   vis, 0L, 'imag_part' )
  vis = add_tag(   vis, 0L, 'sigamp'    )
  v   = rep_tag_value( v, vis, 'vis' ) ;new tags added, replace the old v.vis with the new vis
  vis = replicate( v, n_inputs)

  vis.relative_time_range = pixel_data.relative_time_range
  vis.energy_science_channel_range = pixel_data.energy_science_channel_range

  vis.vis.real_pos   = total(pixel_data.counts[real_pos_idx,*],1)
  vis.vis.real_neg   = total(pixel_data.counts[real_neg_idx,*],1)
  vis.vis.imag_pos   = total(pixel_data.counts[imag_pos_idx,*],1)
  vis.vis.imag_neg   = total(pixel_data.counts[imag_neg_idx,*],1)
  vis.vis.real_part = vis.vis.real_pos - vis.vis.real_neg
  vis.vis.imag_part = vis.vis.imag_pos - vis.vis.imag_neg
  vis.vis.total_flux = exist( total_flux_level_3 ) ? total_flux_level_3 : total(pixel_data.counts[total_flux_idx,*],1)
  ;vis.vis.total_flux is already computed if we are here
  ;This is the normal computation for sigamp, there may be exceptions that have to be coded, RAS, 11-dec-2016
  vis.vis.sigamp    = sqrt( vis.vis.total_flux )

  return, vis

end