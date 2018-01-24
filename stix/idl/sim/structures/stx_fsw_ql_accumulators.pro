function stx_fsw_ql_accumulators
  
  ql_accumulators = { $
    type : 'stx_fsw_ql_accumulators' $
    ; lightcurve
    ; lightcurve_lt
    ; spectra
    ; spectra_lt
    ; bkgd_monitor
    ; bkgd_monitor_lt
    ; variance
    ; variance_lt
    ; flare_detection
    ; flare_detection_lt
    ; flare_location_1
    ; flare_location_1_lt
    ; flare_location_2
    ; flare_location_2_lt
    ; det_anomaly
    ; det_anomaly_lt
    }
    
    return, ql_accumulators
end