;+
; :Description: Stx_time_axis is a time axis structure definition function
; :Params:
;   n_times 
;-
function stx_time_axis, n_times
  return,  { $
              type        : 'stx_time_axis', $
              mean        : replicate(stx_time(),n_times), $
              time_start  : replicate(stx_time(),n_times), $
              time_end    : replicate(stx_time(),n_times), $
              duration    : dblarr(n_times) $
           }
end