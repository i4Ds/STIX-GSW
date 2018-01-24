function stx_fsw_ql_acc_flare_detection
  ql_acc_flare_detection = { $
    type : 'stx_fsw_ql_acc_flare_detection', $
    relative_time : 0d, $ ; last accumulation start time, 4s integration time 
    accumulated_counts : ulonarr(2), $ ; two energy ranges, individual detectors (?) and summed pixels
    live_time : ulonarr(16) $ ; live time counter per detector pair sharing an a/d unit
    }
    
    return, ql_acc_flare_detection
end