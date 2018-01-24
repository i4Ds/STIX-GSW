function stx_fsw_lt_acc_variance
  lt_acc_variance = { $
    type : 'stx_fsw_lt_acc_variance', $
    relative_time : 0d, $ ; last accumulation start time, 0.1s integration time
    accumulated_counts : ulonarr(16) $ ; 16 a/d groups, trigger-based
    }
    
    return, lt_acc_variance
end