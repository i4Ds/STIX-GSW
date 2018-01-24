;+
; :description:
;    This function takes a compaction level 3 image data structure of one or more images and converts it to
;    the telemetry buffer format
;
;
;    Data is written "left to right"
;
; :categories:
;    simulation, converter, telemetry
;
; :params:
;    archive : in, TYPE            STRING    'stx_fsw_vis_image'
;    IDL> archive = stx_fsw_vis_image()
;    IDL> help, archive
;    ** Structure <a4c8c40>, 4 tags, length=1320, data length=1186, refs=1:
;       TYPE            STRING    'stx_fsw_vis_image'
;       RELATIVE_TIME_RANGE
;                       DOUBLE    Array[2]
;       ENERGY_SCIENCE_CHANNEL_RANGE
;                       BYTE      Array[2]
;       VIS             STRUCT    -> <Anonymous> Array[32]
;    IDL> help, archive.vis
;    <Expression>    STRUCT    = -> <Anonymous> Array[32]
;    IDL> help, archive.vis,/st
;    ** Structure <c63db20>, 6 tags, length=40, data length=36, refs=2:
;       TYPE            STRING    'stx_fsw_visibility'
;       TOTAL_FLUX      ULONG                0
;       REAL_NEG        ULONG                0
;       REAL_POS        ULONG                0
;       IMAG_NEG        ULONG                0
;       IMAG_POS        ULONG                0

;
; :returns:
;             a packed byte array ready for the telemetry stream writer
;
; :keywords:
;
;    the direct comparison of input and output
;    VIS_OCTETS - number of octets for vis fields, default is one
;    DETECTOR_MASK - logical mask of the 32 detectors, should always be zeroes for non grid dets
;    COMPRESS_CLASS - compression class flag
;
; :examples:
;    ;    buffer = stx_ivs_images_level_three_to_telemetry_buffer( archive, detector_mask = detector_mask )

;
; :history:
;
;    12-sep-2014 - richard.schwartz@nasa.gov
;    25-nov-2014 - richard.schwartz@nasa.gov - add 8 bit compression for all counters
;    28-nov-2014 - richard.schwartz@nasa.gov - added visibility computation - confirm with GH
;    08-dec-2014 - richard.schwartz@nasa.gov - add DETECTOR_MASK, COMPRESS_CLASS
;    05-oct-2016 - richard.schwartz@nasa.gov - fixed typo and adopted standard idl formatting
;-
function stx_ivs_images_level_three_to_telemetry_buffer, $
  Archive, $
  VIS_OCTETS = vis_octets, $
  DETECTOR_MASK = detector_mask, $
  COMPRESS_CLASS = compress_class

  mask = bytarr(32)
  mask[stx_cfl_read_mask()] = 1 ;is this the only function that returns the fourier detector indices
  default, detector_mask, mask
  default, VIS_octets, 1

  octets_all = 3 * vis_octets + 2

  default, archive_format_struct_out, 0 ;if set, dimension for input comparison
  nimage = n_elements( archive ) ;can't use dim for the case of one image
  det_sel = where( detector_mask, m_det )
  out    = bytarr( 2 + m_det * octets_all, nimage )
  for ii = 0, nimage - 1 do begin

    out[0:1, ii] = byte( archive[ii].energy_science_channel_range )
    ;c_out  = byte( byteswap( transpose( uint( archive[ii].counts ) ) ), 0, 2, 12, m_det )
    vis = archive[ii].vis[mask]
    real = vis.real_pos - vis.real_neg
    ;imag = vis.imag_pos - vis.imag_pos - this expression is obviously wrong (always 0) fixed below, ras, 5-oct-2016
    imag = vis.imag_pos - vis.imag_neg
    comp_flux = stx_compress( vis.total_flux, compress_class=compress_class )
    real7     = stx_compress( abs( real * 2L ), compress_class=compress_class  ) / 2 < 127
    imag7     = stx_compress( abs( imag * 2L ), compress_class=compress_class  ) / 2 < 127
    real8     = real7
    signreal  = where( real lt 0, nsign)
    if nsign ge 1 then real8[ signreal ] += 128B
    signimag  = where( imag lt 0, nsign)
    if nsign ge 1 then imag8[ signimag ] += 128B
    vout      = transpose( [[comp_flux],[real8],[imag8]] )
    out[2, ii] = vout[ * ]

  endfor

  return, out
end

