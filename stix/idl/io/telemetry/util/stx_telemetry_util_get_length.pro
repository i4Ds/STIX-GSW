function stx_telemetry_util_get_length, blocks
  total_size = 0L
  foreach block, blocks do foreach packet, block do total_size += packet.data_field_length
  return, total_size
end