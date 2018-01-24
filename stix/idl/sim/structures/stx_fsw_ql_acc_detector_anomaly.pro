function stx_fsw_ql_acc_detector_anomaly
  ql_detector_anomaly = { $
    type : 'stx_fsw_ql_acc_detector_anomaly', $
    relative_time : 0d, $ ; last accumulation start time, 8s integration time
    accumulated_counts : ulonarr(32), $ ; 1 energy range, individual detectors and summed pixels
    live_time : ulonarr(16) $ ; live time counter per one a/d group
    }
    
    return, ql_acc_detector_anomaly
end