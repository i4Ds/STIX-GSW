function stx_fsw_spc_data
  return, { type                          : 'stx_fsw_spc_data', $
            relative_time_range           : dblarr(2), $ ; relative start and end time of integration in ms
            energy_science_channel_range  : bytarr(2), $ ; [0,31]
            counts                        : ulong(0) $ ; number of integrated counts
            ;todo: trigger necessary?
            ;trigger_count                 : ulonarr(12) $ ; the number of counted triggers integrated for each detector AD group
          }
end 