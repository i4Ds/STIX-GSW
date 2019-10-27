; :history:
;    ? - (FHNW), initial release
;    23-Oct-2019 - ECMD (Graz), added telecommand keyword to read telecommand packet headers : 1 if packet is telecommand, 0 if packet is telemetry 
;    
;-
function stx_telemetry_packet_structure_solo_source_packet_header, packet_word_width=packet_word_width, telecommand = telecommand 
default, telecommand, 0 
  packet_word_width = { $
    type                           : 'stx_tmtc_word_width', $
    packet                         : 'stx_tmtc_solo_source_packet_header', $
    version_number                 : 3, $
    packet_type                    : 1, $
    data_field_header_flag         : 1, $
    pid                            : 7, $
    packet_category                : 4, $
    segmentation_grouping_flags    : 2, $
    source_sequence_count          : 14, $
    data_field_length              : 16, $  ; in bytes (total bytes -1)
    spare_1                        : 1, $ ; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
    pus_version                    : 3, $ ; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
    spare_2                        : 4, $ ; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
    service_type                   : 8, $ ; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
    service_subtype                : 8, $ ; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
    destination_id                 : 8, $ ; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
    ;sc_time                        : 48, $ ; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
    coarse_time                    : 32*(1 - telecommand), $; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
    fine_time                      : 16*(1 - telecommand), $; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
    pkg_total_bytes_data_field_header : 10 - 4*telecommand, $ ; Used to keep length of Data Field Header
    source_data                    : -32848L $
  } ; 128 bit fixed = 16 bytes

  tc_packet_word_width = { $
  type                           : 'stx_tmtc_word_width', $
  packet                         : 'stx_tmtc_solo_source_packet_header', $
  version_number                 : 3, $
  packet_type                    : 1, $
  data_field_header_flag         : 1, $
  pid                            : 7, $
  packet_category                : 4, $
  segmentation_grouping_flags    : 2, $
  source_sequence_count          : 14, $
  data_field_length              : 16, $  ; in bytes (total bytes -1)
  spare_1                        : 1, $ ; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
  pus_version                    : 3, $ ; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
  spare_2                        : 4, $ ; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
  service_type                   : 8, $ ; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
  service_subtype                : 8, $ ; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
  destination_id                 : 8, $ ; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
  ;sc_time                        : 48, $ ; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
  coarse_time                    : 32, $; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
  fine_time                      : 16, $; TM Data Field Header <- is technically not in TM Source Packet Header but in Packet Data Field
  pkg_total_bytes_data_field_header : 6, $ ; Used to keep length of Data Field Header
  source_data                    : -32848L $
} ; 128 bit fixed = 16 bytes

  packet = { $
    type                           : 'stx_tmtc_solo_source_packet_header', $
    version_number                 : uint(0), $     ; fixed (0b)
    packet_type                    : uint(0), $     ; fixed (0b)
    data_field_header_flag         : uint(1), $     ; fixed (1b)
    pid                            : uint(0), $
    packet_category                : uint(0), $
    segmentation_grouping_flags    : uint(0), $
    source_sequence_count          : uint(0), $
    data_field_length              : uint(0), $
    spare_1                        : uint(0), $     ; fixed (0b)
    pus_version                    : uint(1), $     ; fixed (1b)
    spare_2                        : uint(0), $     ; fixed (1b)
    service_type                   : uint(0), $
    service_subtype                : uint(0), $
    destination_id                 : uint(0), $
    ;sc_time                        : ulong64(0), $
    coarse_time                    : ulong(0), $
    fine_time                      : uint(0), $
    source_data                    : ptr_new(), $
    pkg_word_width                 : packet_word_width $
  }
  
  return, packet
end