;+
; :description:
;   This function creates an uninitialized stx_telemetry_packet_structure_ql_variance.
;
; :categories:
;    flight software, structure definition, telemetry
;
; :returns:
;    an uninitialized stx_telemetry_packet_structure_ql_variance
;
; :examples:
;    ...
;
; :history:
;     08-Dez-2015, Simon Marcin (FHNW), initial release
;
;-
function stx_telemetry_packet_structure_ql_variance, packet_word_width=packet_word_width
  packet_word_width = { $
    type                             : 'stx_tmtc_word_width', $
    packet                           : 'stx_tmtc_ql_variance', $
    header_pid                       : 7, $
    header_packet_category           : 4, $
    header_data_field_length         : 16, $ ; in bytes (total bytes -1)
    header_service_type              : 8, $
    header_service_subtype           : 8, $
    ssid                             : 8, $
    coarse_time                      : 32, $
    fine_time                        : 16, $
    integration_time                 : 8, $
    samples_per_variance             : 8, $
    detector_mask                    : 32, $ 
    energy_mask                      : 32, $
    spare_block_pixel                : 4, $
    pixel_mask                       : 12, $
    compression_schema_accum         : 8, $  ; 1 spare + 7 
    ;energy_channel_lower_bound       : 5, $
    ;energy_channel_upper_bound       : 5, $
    ;spare_block                      : 6, $
    number_of_samples                : 16, $
    dynamic_variance                 : 0UL, $ ; dynamic, will be filled during execution with  N*1  octet
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
    type                             : 'stx_tmtc_ql_variance', $
    header_pid                       : uint(93),  $     ; fixed
    header_packet_category           : uint(12),  $     ; fixed
    header_data_field_length         : uint(0),   $
    header_service_type              : uint(21),  $     ; fixed
    header_service_subtype           : uint(6),   $     ; fixed
    ssid                             : uint(33),  $     ; fixed
    coarse_time                      : ulong(0), $
    fine_time                        : uint(0), $
    integration_time                 : uint(0), $
    samples_per_variance             : uint(0), $
    detector_mask                    : ulong(0), $
    energy_mask                      : ulong64(0), $
    spare_block_pixel                : uint(0), $
    pixel_mask                       : uint(0), $
    compression_schema_accum         : uint(0), $       ; 1 spare, s, kkk, mmm
    ;energy_channel_lower_bound       : uint(0), $ 
    ;energy_channel_upper_bound       : uint(0), $ 
    ;spare_block                      : uint(0), $
    number_of_samples                : uint(0), $
    dynamic_variance                 : ptr_new(), $
    pkg_word_width                   : packet_word_width $
  }

  return, packet
end