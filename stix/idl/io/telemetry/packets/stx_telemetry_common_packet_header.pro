function stx_telemetry_common_packet_header
  header = { $
    type              : 'stx_telemetry_common_packet_header', $
    pid               : uint(0), $
    packet_category   : uint(0), $
    service_type      : uint(0), $
    service_subtype   : uint(0), $
    sid               : uint(0), $
    ssid              : uint(0), $
    stx_tmtc_str       : '' $
    }
    
    return, header
end