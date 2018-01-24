function stx_fsw_flare_selection_result, flare_times, continue_time
  result_data = { $
    type : 'stx_fsw_flare_selection_result', $
    flare_times   : n_elements(flare_times) gt 0 ? flare_times : stx_time() ,$    ;stx_time(*,2)
    is_valid      : n_elements(flare_times) gt 0, $
    continue_time : continue_time $   ;stx_time
  }
    
  return, result_data
end