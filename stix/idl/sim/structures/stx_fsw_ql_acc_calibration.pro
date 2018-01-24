function stx_fsw_ql_acc_calibration
  ql_acc_calibration = { $
    type : 'stx_fsw_ql_acc_calibration', $
    relative_time : 0d, $ ; last accumulation start time, 1d integration time
    accumulated_counts : bytarr(32*12*1024), $ ; 1024 energy channels, individual detectors and individual pixels
    live_time : ulong(0) $ ; live time counter, summed
    }
    
    return, ql_acc_calibration
end