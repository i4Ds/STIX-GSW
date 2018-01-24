;+
; :description:
;    This function takes a compaction level 1 image data structure of one or more images and converts it to
;    the telemetry buffer format
;    
;    
;    Data is written "left to right"
;
; :categories:
;    simulation, converter, telemetry
;
; :params:
;    archive : in, TYPE            STRING    'stx_fsw_pixel_data' 
;             The pixel data input contains  pixel data over
;             one time and multiple energies, detectors and pixels
;    IDL> help, ivs.img_combined_archive_buffer,/st
;    ** Structure <9dd9880>, 5 tags, length=1640, data length=1634, refs=2:
;       TYPE            STRING    'stx_fsw_pixel_data'
;       RELATIVE_TIME_RANGE
;                       DOUBLE    Array[2]
;       ENERGY_SCIENCE_CHANNEL_RANGE
;                       BYTE      Array[2]
;       COUNTS          ULONG     Array[12, 32]
;       TRIGGER_COUNT   ULONG     Array[16]
;
; :returns:
;             a packed byte array ready for the telemetry stream writer
;
; :keywords:
;    LARGE_PIXEL_OCTETS - number of octets for large pixels, default is one
;    SMALL_PIXEL_OCTETS - number of octets for small pixels, default is one
;    DETECTOR_MASK - indices (0-31) of selected detectors to report, default is imaging 30 dets
; :examples:
;    ;buffer = stx_ivs_images_level_one_to_telemetry_buffer( archive, detector_mask = detector_mask )

;
; :history:
;    
;    12-sep-2014 - richard.schwartz@nasa.gov 
;    28-nov-2014 - richard.schwartz@nasa.gov, added detector mask
;    04-dec-2014 - richard.schwartz@nasa.gov, revised to 1 octet(byte) for all pixels
;    05-dec-2014 - richard.schwartz@nasa.gov, added pixel mask and compress_class to 
;     stx_compress, changed to pixel, det in 'stx_fsw_pixel_data' type struct
;    06-feb-2015 - richard.schwartz@nasa.gov, changed data extraction syntax to obtain c_out
;     archive[ii].counts[ pix_sel, det_sel] changed to (archive[ii].counts[ pix_sel, *])[*,det_sel]
;    10-feb-2015 - richard.schwartz@nasa.gov, fix two typos, change comma to plus to compute number of octets
;     and where must come before m_det is used because the where defines m_det
;-
function stx_ivs_images_level_one_to_telemetry_buffer, $
  Archive, $
  LARGE_PIXEL_OCTETS = large_pixel_octets, $
  SMALL_PIXEL_OCTETS = small_pixel_octets, $
  DETECTOR_MASK      = detector_mask, $
  PIXEL_MASK         = pixel_mask, $
  COMPRESS_CLASS  = compress_class
  
default, large_pixel_octets, 1 
default, compress_class, 'image_counts'
large_pixel_octet_array = [ bytarr(8) + byte(large_pixel_octets), bytarr(4)]
default, small_pixel_octets, 1 
small_pixel_octet_array =  [ bytarr(8), bytarr(4) + byte(small_pixel_octets) ]
default, pixel_mask, bytarr(12) + 1b
mask = bytarr(32)
mask[stx_cfl_read_mask()] = 1 ;is this the only function that returns the fourier detector indices
default, detector_mask, mask 
;octets_all = total(  pixel_mask * [ large_pixel_octet_array,  small_pixel_octet_array ] ) ;oops, change ',' to '+', ras 10-feb-2015
octets_all = total(  pixel_mask * [ large_pixel_octet_array +  small_pixel_octet_array ] )

default, archive_format_struct_out, 0 ;if set, dimension for input comparison
nimage = n_elements( archive ) 
det_sel= where( detector_mask, m_det ) ;oops, where has to come first to define m_det, ras 10-feb-2015



out    = bytarr( 2 + m_det * octets_all, nimage )

pix_sel= where( pixel_mask )
for ii = 0, nimage - 1 do begin

  out[0:1, ii] = byte( archive[ii].energy_science_channel_range )
  
   ;c_out  = stx_compress(  archive[ii].counts[ pix_sel, det_sel],  compress_class = compress_class ) 
  c_out  = stx_compress(  (archive[ii].counts[ pix_sel, *])[*,det_sel],  compress_class = compress_class ) 
  out[ 2, ii ] = c_out[*]
  endfor

return, out
end

