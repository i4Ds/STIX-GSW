;+
; :description:
;    This function tests the telemetry routine for compaction level 1 which writes an
;    image data structure of one or more images and converts it to
;    the telemetry buffer format
;    
;    
;    
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
;       COUNTS          ULONG     Array[32, 12]
;       TRIGGER_COUNT   ULONG     Array[16]
; :Examples:
;    help, stx_ivs_images_level_one_to_telemetry_buffer_test( archive[0:9] )
;    Verify that one image is processed the same as the first of 10
;    First 10 in out, first in out0
;    pmm, out0 - out 
;         0.000000     0.000000 indicates success
;         0.000000     0.000000
;    Compare energy ranges in the input archive and output buffer
;    For energy bins   0  31
;    is this valid?    1
;    For energy bins   0   4
;    is this valid?    1
;    For energy bins   4   8
;    is this valid?    1
;    For energy bins   0   4
;    is this valid?    1
;    For energy bins   4   8
;    is this valid?    1
;    For energy bins   0   4
;    is this valid?    1
;    For energy bins   4   8
;    is this valid?    1
;    For energy bins   8  12
;    is this valid?    1
;    For energy bins   0   4
;    is this valid?    1
;    For energy bins   4   8
;    is this valid?    1
;    For image        1
;    For detector       4
;              19          49          55          15          27          48          55          24           2           3           9           3
;       0  19   0  49   0  55   0  15   0  27   0  48   0  55   0  24   2   3   9   3
;    convert bytes back to integers
;          19      49      55      15      27      48      55      24       2       3       9       3
;    Valid test?       1.00000
;    <Expression>    FLOAT     =       1.00000
; :returns:
;             a logical, 1 for success, 0 for failur
; :keywords:
;    ARCHIVE_FORMAT_STRUCT_OUT - if set, return the output in a format that facilitates
;    the direct comparison of input and output
;    LARGE_PIXEL_OCTETS - number of octets for large pixels, default is two
;    SMALL_PIXEL_OCTETS - number of octets for small pixels, default is one
;    IMAGE_CHOICE       - index of archive image for comparison of buffer with input, default is 1
;    DETECTOR_CHOICE    - index of detector in archive image for comparison test, default is 4
; :examples:
;    buffer = stx_archive_struct_to_teletry_buffer( archive )
;
; :history:
;    
;    12-sep-2014 - richard.schwartz@nasa.gov 
;    5-dec-2014 - richard.schwartz@nasa.gov, added pixel_mask and compress_class
;-
function stx_ivs_images_level_one_to_telemetry_buffer_test, archive, $
  LARGE_PIXEL_OCTETS = large_pixel_octets, $
  SMALL_PIXEL_OCTETS = small_pixel_octets, $
  IMAGE_CHOICE = image_choice, $
  DETECTOR_CHOICE   = detector_choice, $
  PIXEL_MASK = pixel_mask, $
  COMPRESS_CLASS = compress_class
  
default, image_choice, 1 ;select the image in archive
default, detector_choice, 4 ;select the detector index from the archive image
default, large_pixel_octets, 1
default, small_pixel_octets, 1
default, pixel_mask, bytarr(12) + 1b
default, compress_class, 0
pix_sel = where( pixel_mask, npix)
octets_all = 8 * large_pixel_octets + 4 * small_pixel_octets
data_out_start = 2 + octets_all * detector_choice
data_out_end   = data_out_start + octets_all - 1
narchive = n_elements( archive )
out = stx_ivs_images_level_one_to_telemetry_buffer( archive )

out0 = stx_ivs_images_level_one_to_telemetry_buffer( archive[0] )
print,'Verify that one image is processed the same as the first of 10
print,'First 10 in out, first in out0
print, 'pmm, out0 - out '
print, '     0.000000     0.000000 indicates success'
pmm, out0 - out

out_str = stx_ivs_images_level_one_to_telemetry_buffer( archive, /archive_format_struct_out )

print,'Compare energy ranges in the input archive and output buffer
for ii = 0, narchive -1 do begin
  v22 = reform( [ archive[ii].energy_science_channel_range, out_str[ii].ebin ], 2, 2 )
  print, 'For energy bins',v22[*,0],'is this valid? ', byte( 1-total( abs(v22[*,0] - v22[*,1]) ) )
  endfor

print, 'For image ', image_choice
print, 'For detector', detector_choice
print, archive[image_choice].counts[pix_sel, detector_choice] 
print, out[ data_out_start : data_out_end, image_choice ]
print, 'convert bytes back to integers'
recovered =  stx_compress( /decompress, compress_class = compress_class, $
    out[ data_out_start : data_out_end  , image_choice ] )
true_data = archive[image_choice].counts[pix_sel, detector_choice ]
test = f_div( abs( true_data - recovered ), true_data )
print, 'in and output absolute relative difference', test
print, 'max of in and output absolute relative difference',max( test )
print, 'avg of in and output absolute relative difference', avg( test )
valid = avg(test) le 0.05
print, 'Valid test? ', valid
return, valid
end

