function stx_time_value_locate, Vector, Value, L64=L64
  return, value_locate(stx_time2any(Vector),stx_time2any(Value), L64=L64 )
end