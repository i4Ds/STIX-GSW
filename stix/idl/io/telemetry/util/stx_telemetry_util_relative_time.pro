; a function which returns the rlative part of stx_time (only the seconds of the time).

function stx_telemetry_util_relative_time, in_time
  
  ppl_require, in=in_time, type='STX_TIME'

  return, in_time.value.time/1000.0d
  
end