;+
; :description:
;   This function creates an uninitialized stx_telemetry_packet_structure_ql_spectra structure.
;
; :categories:
;    flight software, structure definition, telemetry
;
; :returns:
;    an uninitialized stx_telemetry_packet_structure_ql_spectra structure
;
; :examples:
;    ...
;
; :history:
;     01-Dez-2015, Simon Marcin (FHNW), initial release
;
;-
function stx_telemetry_packet_structure_ql_spectra, packet_word_width=packet_word_width
  packet_word_width = { $
    type                             : 'stx_tmtc_word_width', $
    packet                           : 'stx_tmtc_ql_spectra', $
    header_pid                       : 7, $
    header_packet_category           : 4, $
    header_data_field_length         : 16, $ ; in bytes (total bytes -1)
    header_service_type              : 8, $
    header_service_subtype           : 8, $
    ssid                             : 8, $
    coarse_time                      : 32, $
    fine_time                        : 16, $
    integration_time                 : 16, $
    compression_schema_spectrum      : 8, $  ; 1 spare + 7 
    compression_schema_trigger       : 8, $  ; 1 spare + 7
    spare_block                      : 4, $
    pixel_mask                       : 12, $
    number_of_structures             : 16, $
    dynamic_detector_index           : 0UL, $ ; dynamic, will be filled during execution with  N*1  octet
    dynamic_spectrum                 : 0UL, $ ; dynamic, will be filled during execution with  N*32 octets    
    dynamic_trigger_accumulator      : 0UL, $ ; dynamic, will be filled during execution with  N*1  octet
    dynamic_nbr_samples              : 0UL, $ ; dynamic, will be filled during execution with  N*1  octets
    pkg_total_bytes_fixed            : long(0) $
  } ; 112 bits fixed = 14 bytes

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
    type                             : 'stx_tmtc_ql_spectra', $
    header_pid                       : uint(93),  $     ; fixed
    header_packet_category           : uint(12),  $     ; fixed
    header_data_field_length         : uint(0),   $
    header_service_type              : uint(21),  $     ; fixed
    header_service_subtype           : uint(6),   $     ; fixed
    ssid                             : uint(32),  $     ; fixed
    coarse_time                      : ulong(0), $
    fine_time                        : uint(0), $
    integration_time                 : uint(0), $
    compression_schema_spectrum      : uint(0), $       ; 1 spare, s, kkk, mmm
    compression_schema_trigger       : uint(0), $       ; 1 spare, s, kkk, mmm
    spare_block                      : uint(0), $       ; only 4 bits
    pixel_mask                       : uint(0), $
    number_of_structures             : uint(0), $
    dynamic_detector_index           : ptr_new(), $
    dynamic_spectrum                 : ptr_new(), $
    dynamic_trigger_accumulator      : ptr_new(), $
    dynamic_nbr_samples              : ptr_new(), $
    pkg_word_width                   : packet_word_width $
  }

  return, packet
end