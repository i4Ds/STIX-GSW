;+
; :description:
;   This function creates an uninitialized stx_telemetry_packet_structure_ql_flare_list.
;
; :categories:
;    flight software, structure definition, telemetry
;
; :returns:
;    an uninitialized stx_telemetry_packet_structure_ql_flare_list
;
; :examples:
;    ...
;
; :history:
;     19-Dez-2016, Simon Marcin (FHNW), initial release
;
;-
function stx_telemetry_packet_structure_ql_flare_list, packet_word_width=packet_word_width
  packet_word_width = { $
    type                             : 'stx_tmtc_word_width', $
    packet                           : 'stx_tmtc_ql_flare_list', $
    header_pid                       : 7, $
    header_packet_category           : 4, $
    header_data_field_length         : 16, $ ; in bytes (total bytes -1)
    header_service_type              : 8, $
    header_service_subtype           : 8, $
    ssid                             : 8, $
    pointer_start                    : 48, $
    pointer_end                      : 48, $
    number_of_flares                 : 8, $
    dynamic_start_coarse             : 0UL, $ 
    dynamic_start_fine               : 0UL, $ 
    dynamic_end_coarse               : 0UL, $ 
    dynamic_end_fine                 : 0UL, $ 
    dynamic_high_flag                : 0UL, $ 
    dynamic_nbr_packets              : 0UL, $ 
    dynamic_spare                    : 0UL, $ 
    dynamic_processed                : 0UL, $ 
    dynamic_compression              : 0UL, $ 
    dynamic_transmitted              : 0UL, $ 
    pkg_total_bytes_fixed            : long(0) $
  } ; 160 bits fixed = 20 bytes

  tags = strlowcase(tag_names(packet_word_width))

  ; definition of ignored packets for size calculation
  ignore = arr2str('^' + ['type', 'packet', 'header_.*', 'dynamic_*', 'pkg_.*'] + '$', delimiter='|')

  ; compute pkg_total_bytes_fixed
  for i = 0L, n_tags(packet_word_width)-1 do begin
    if(stregex(tags[i], ignore , /boolean)) then continue $
    else packet_word_width.pkg_total_bytes_fixed += packet_word_width.(i)
  endfor

  ; transform bits to bytes
  if (packet_word_width.pkg_total_bytes_fixed MOD 8 gt 0) then message, 'bits are no multiple of 8'
  packet_word_width.pkg_total_bytes_fixed /= 8

  packet = { $
    type                             : 'stx_tmtc_ql_flare_list', $
    header_pid                       : uint(93),  $     ; fixed
    header_packet_category           : uint(12),  $     ; fixed
    header_data_field_length         : uint(0),   $
    header_service_type              : uint(21),  $     ; fixed
    header_service_subtype           : uint(6),   $     ; fixed
    ssid                             : uint(40),  $     ; fixed
    pointer_start                    : ulong64(0), $
    pointer_end                      : ulong64(0), $
    number_of_flares                 : uint(0), $
    dynamic_start_coarse             : ptr_new(), $
    dynamic_start_fine               : ptr_new(), $
    dynamic_end_coarse               : ptr_new(), $
    dynamic_end_fine                 : ptr_new(), $
    dynamic_high_flag                : ptr_new(), $
    dynamic_nbr_packets              : ptr_new(), $
    dynamic_spare                    : ptr_new(), $
    dynamic_processed                : ptr_new(), $
    dynamic_compression              : ptr_new(), $
    dynamic_transmitted              : ptr_new(), $
    pkg_word_width                   : packet_word_width $
  }

  return, packet
end