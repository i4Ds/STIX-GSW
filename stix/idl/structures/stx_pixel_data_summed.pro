;    sumcase        : integration method
;                      0: 'Pixel sum over two big pixels'
;                      1: 'Pixel sum over two big pixels and small pixel'
;                      2: 'Only upper row pixels'
;                      3: 'Only lower row pixels'
;                      4: 'Only small pixels'
function stx_pixel_data_summed, pixels=pixels, detectors=dtectors
  default, detectors, 32
  default, pixels, 4
  return, { $
    type                  : 'stx_pixel_data_summed', $
    live_time             : fltarr(16), $ ; between zero and one
    time_range            : replicate(stx_time(),2), $
    energy_range          : fltarr(2), $
    counts                : ulonarr(detectors,pixels), $ ; no pixels
    sumcase               : 0 ,$ ; see stx_pixel_sums, create sumcase enumeration
    coarse_flare_location : [!VALUES.f_nan, !VALUES.f_nan], $ 
    background            : stx_background(), $
    rcr                   : byte(0), $
    datasource            : "?" $  
  }
end

;;********************* PAOLO: add unit