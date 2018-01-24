function stx_fsw_ql_acc_flare_location_cfl
  ql_acc_flare_location_cfl = { $
    type : 'stx_fsw_ql_acc_flare_location_cfl', $
    relative_time : 0d, $ ; last accumulation start time, 8s integration time
    accumulated_counts : ulonarr(16), $ ; 2 energy ranges, coarse flare locator detector and 8 pixels
    live_time : ulong(0) $ ; live time counter
    }
    
    return, ql_acc_flare_location_cfl
end