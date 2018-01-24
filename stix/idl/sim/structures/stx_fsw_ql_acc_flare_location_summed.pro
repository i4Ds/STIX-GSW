function stx_fsw_ql_acc_flare_location_summed
  ql_acc_flare_location_cfl = { $
    type : 'stx_fsw_ql_acc_flare_location_summed', $
    relative_time : 0d, $ ; last accumulation start time, 4s integration time
    accumulated_counts : ulonarr(8), $ ; 2 energy ranges, summed detectors and 4 differently masked sets of pixels
    live_time : ulong(0) $ ; live time counter, summed
    }
    
    return, ql_acc_flare_location_summed
end