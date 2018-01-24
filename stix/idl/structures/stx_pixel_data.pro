function stx_pixel_data
  return, { $
    type                  : 'stx_pixel_data', $
    live_time             : fltarr(16), $ ; between zero and one
    time_range            : replicate(stx_time(),2), $
    energy_range          : fltarr(2), $
    counts                : ulon64arr(32,12), $ ; [detector,pixel]
    ;TODO: n.h. change order to [pixel,detector]
    rcr                   : byte(0), $
    datasource            : "?", $
    coarse_flare_location : [!VALUES.f_nan, !VALUES.f_nan] $ 
    ; maybe 'rate' later
    ; maybe 'numerical_accuray' later
  }
end