function stx_fsw_ql_acc_bkgd_monitor
  ql_acc_bkgd_monitor = { $
    type : 'stx_fsw_ql_acc_bkgd_monitor', $
    relative_time : 0d, $ ; last accumulation start time, 32s integration time
    accumulated_counts : ulonarr(5), $ ; 5 energy ranges, background detector, 2 pixels
    live_time : ulong(0) $ ; live time counter
    }
    
    return, ql_acc_bkgd_monitor
end