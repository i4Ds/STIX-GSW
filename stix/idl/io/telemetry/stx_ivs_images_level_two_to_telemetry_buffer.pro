;+
; :description:
;    This function takes a compaction level 2 image data structure of one or more images and converts it to
;    the telemetry buffer format
;    
;    
;    Data is written "left to right"
;
; :categories:
;    simulation, converter, telemetry
;
; :params:
;    archive : in, TYPE            STRING    'stx_fsw_pixel_data_summed' 
;             The pixel data input contains  pixel data over
;             one time and multiple energies, detectors and pixels
;  IDL> help,stx_fsw_pixel_data_summed()
;  % Compiled module: STX_FSW_PIXEL_DATA_SUMMED.
;  ** Structure <c632930>, 5 tags, length=552, data length=547, refs=1:
;     TYPE            STRING    'stx_fsw_pixel_data_summed'
;     RELATIVE_TIME_RANGE
;                     DOUBLE    Array[2]
;     ENERGY_SCIENCE_CHANNEL_RANGE
;                     BYTE      Array[2]
;     COUNTS          ULONG     Array[4, 32]
;     SUMCASE         BYTE         0
;
; :returns:
;             a packed byte array ready for the telemetry stream writer
;
; :keywords:
;    LARGE_PIXEL_OCTETS - number of octets for large pixels, default is two
;    SMALL_PIXEL_OCTETS - number of octets for small pixels, default is one
; :examples:
;    buffer = stx_ivs_images_level_two_to_telemetry_buffer( archive, detector_mask = detector_mask )
;
; :history:
;    
;    12-sep-2014 - richard.schwartz@nasa.gov 
;    25-nov-2014 - richard.schwartz@nasa.gov - add 8 bit compression for all counters
;    04-dec-2014 - richard.schwartz@nasa.gov - removed extraneous def of out
;    05-dec-2014 - richard.schwartz@nasa.gov, added compress_class to 
;     stx_compress, changed to pixel, det in 'stx_fsw_pixel_data' type struct
;    11-feb-2015 - richard.schwartz@nasa.gov, m_det  = dim[1] ;how many detectors, dim[1] not dim[0]
;-
function stx_ivs_images_level_two_to_telemetry_buffer, $
  Archive, $
  PIXEL_OCTETS = pixel_octets, $
  DETECTOR_MASK = detector_mask
  COMPRESS_CLASS = compress_class
  
default, compress_class, 0  
default, pixel_octets, 1
mask = bytarr(32)
mask[stx_cfl_read_mask()] = 1 ;is this the only function that returns the fourier detector indices
default, detector_mask, mask 
octets_all =  4 * pixel_octets

default, archive_format_struct_out, 0 ;if set, dimension for input comparison
nimage = n_elements( archive ) 
det_sel= where( detector_mask, m_det )

default, archive_format_struct_out, 0 ;if set, dimension for input comparison

dim    = size( /dimension, archive.counts )
nimage = n_elements( archive ) ;can't use dim for the case of one image
m_det  = dim[1] ;how many detectors, dim[1] not dim[0], ras, 11-feb-2015
out    = bytarr( 2 + m_det * octets_all, nimage )
for ii = 0, nimage - 1 do begin

  out[0:1, ii] = byte( archive[ii].energy_science_channel_range )
  
  c_out = ( stx_compress( archive[ii].counts[*, det_sel], compress_class=compress_class ) )[*] ;use 8 bit compression schema, 25-nov-2014
  
  out[ 2, ii ] = c_out
  endfor

return, out
end

