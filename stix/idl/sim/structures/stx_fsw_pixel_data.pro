function stx_fsw_pixel_data, pixels=pixels, detectors=detectors
default, detectors, 32
default, pixels, 12
  return, { type                          : 'stx_fsw_pixel_data', $
            relative_time_range           : dblarr(2), $ ; relative start and end time of integration in seconds
            energy_science_channel_range  : bytarr(2), $ ; [0,31]
            ;trigger_count                 : ulonarr(16) $ ; the number of counted triggers integrated for each detector AD group
            counts                        : lon64arr(pixels,detectors) $ ; number of integrated counts per pixel per detector 
          }
end
