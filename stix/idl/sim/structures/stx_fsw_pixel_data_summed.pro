function stx_fsw_pixel_data_summed
  return, { type                          : 'stx_fsw_pixel_data_summed', $
            relative_time_range           : dblarr(2), $ ; relative start and end time of integration in seconds
            energy_science_channel_range  : bytarr(2), $ ; [0,31]
            counts                        : lon64arr(4,32), $ ; number of integrated counts, per pixel per detector
            sumcase                       : byte(0) $;suming method enumeration
          }
end