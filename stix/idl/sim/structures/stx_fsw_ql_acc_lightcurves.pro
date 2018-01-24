function stx_fsw_ql_acc_lightcurves
  ql_acc_lightcurves = { $
    type : 'stx_fsw_ql_acc_lightcurves', $
    relative_time : 0d, $ ; last accumulation start time, 4s integration time
    accumulated_counts : ulonarr(5), $ ; 5 energy ranges, summed detectors and summed pixels
    live_time : ulong(0) $ ; live time counter, summed
    }
    
    return, ql_acc_lightcurves
end