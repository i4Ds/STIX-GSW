function stx_fsw_ql_acc_pectra
  ql_acc_spectra = { $
    type : 'stx_fsw_ql_acc_spectra', $
    relative_time : 0d, $ ; last accumulation start time, 32s integration time
    accumulated_counts : ulonarr(32), $ ; 32 energy channels, multiplexed detectors (cycling through) and summed pixels
    live_time : ulonarr(32) $ ; 32? live time counter, multiplexed
    }
    
    return, ql_acc_spectra
end