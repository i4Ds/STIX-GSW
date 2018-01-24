function stx_fsw_lt_acc_eventhandling
  lt_acc_eventhandling = { $
    type : 'stx_fsw_lt_acc_eventhandling', $
    relative_time : 0d, $ ; last accumulation start time, variable seconnds integration time
    accumulated_counts : ulonarr(16) $ ; 16 a/d groups, trigger-based
    }
    
    return, lt_acc_eventhandling
end