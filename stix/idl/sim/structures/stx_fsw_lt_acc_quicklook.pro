function stx_fsw_lt_acc_quicklook
  lt_acc_quicklook = { $
    type : 'stx_fsw_lt_acc_quicklook', $
    relative_time : 0d, $ ; last accumulation start time, 4s integration time
    accumulated_counts : ulonarr(16) $ ; 16 a/d groups, trigger-based
    }
    
    return, lt_acc_quicklook
end