function stx_fsw_ql_acc_variance
  ql_acc_variance = { $
    type : 'stx_fsw_ql_acc_variance', $
    relative_time : 0d, $ ; last accumulation start time, 0.1s integration time
    accumulated_counts : ulong(0), $ ; ulong(0) or ulonarr(40)? 1 energy range, summed detectors and summed pixels
    live_time : ulong(0) $ ; live time counter summed, ulong(0) or ulonarr(40)?
    }
    
    return, ql_acc_variance
end