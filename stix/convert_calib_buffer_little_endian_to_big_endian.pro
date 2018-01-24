pro convert_calib_buffer_little_endian_to_big_endian
  openr, rlun, 'C:\Users\LaszloIstvan\Dropbox (STIX)\FSW_Test_Data\Data\Raw\v20170308\T5a\calib_spectrum.bin', /get_lun
  ;openw, wlun, 'C:\temp\calib_spectrum_bigendian.bin', /get_lun;'C:\Users\LaszloIstvan\Dropbox (STIX)\FSW_Test_Data\Data\Raw\v20170308\T5a\calib_spectrum_bigendian.bin', /get_lun

  seconds = ulong(0)
  subseconds = uint(0)
  pixel = byte(0)
  detector = byte(0)
  ad_channel = uint(0)
  
  last_seconds = 0

  while(~eof(rlun)) do begin
    readu, rlun, seconds
    readu, rlun, subseconds
    readu, rlun, pixel
    readu, rlun, detector
    readu, rlun, ad_channel
    
    le_seconds = swap_endian(seconds)
    le_subseconds = swap_endian(subseconds)
    le_pixel = swap_endian(pixel)
    le_detector = swap_endian(detector)
    le_ad_channel = swap_endian(ad_channel)
    
    if (le_seconds lt 0 || le_seconds gt 410) then stop
    if (le_subseconds lt 0 || le_subseconds gt 65535) then stop
    if (le_pixel lt 0 || le_pixel gt 11) then stop
    if (le_detector lt 0 || le_detector gt 31) then stop
    if (le_ad_channel lt 0 || le_ad_channel gt 4096) then stop
    
    if (le_seconds lt last_seconds) then stop
    
    last_seconds = le_seconds
    
    ;detector = (detector eq 255) ? byte(0) : byte(detector + 1)
    
    ;if (seconds lt 0 || seconds gt 410) then stop
    ;if (subseconds lt 0 || subseconds gt 65535) then stop
    ;if (pixel lt 0 || pixel gt 11) then stop
    ;if (detector lt 0 || detector gt 31) then stop
    ;if (ad_channel lt 0 || ad_channel gt 4096) then stop
    
    ;if (seconds lt last_seconds) then stop
    
    ;be_seconds = swap_endian(seconds, /swap_if_little_endian)
    ;be_subseconds = swap_endian(subseconds, /swap_if_little_endian)
    ;be_pixel = swap_endian(pixel, /swap_if_little_endian)
    ;be_detector = swap_endian(detector, /swap_if_little_endian)
    ;be_ad_channel = swap_endian(ad_channel, /swap_if_little_endian)

    ;writeu, wlun, be_seconds
    ;writeu, wlun, be_subseconds
    ;writeu, wlun, be_pixel 
    ;writeu, wlun, be_detector
    ;writeu, wlun, be_ad_channel
  endwhile

  free_lun, rlun
  ;free_lun, wlun
end