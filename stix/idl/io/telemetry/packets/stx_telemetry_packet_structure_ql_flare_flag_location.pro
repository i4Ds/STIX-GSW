;+
; :description:
;   This function creates an uninitialized stx_telemetry_packet_structure_ql_flare_flag_location.
;
; :categories:
;    flight software, structure definition, telemetry
;
; :returns:
;    an uninitialized stx_telemetry_packet_structure_ql_flare_flag_location structure
;
; :examples:
;    ...
;
; :history:
;     27-Jan-2016, Simon Marcin (FHNW), initial release
;
;-
function stx_telemetry_packet_structure_ql_flare_flag_location, packet_word_width=packet_word_width
  packet_word_width = { $
    type                             : 'stx_tmtc_word_width', $
    packet                           : 'stx_tmtc_ql_flare_flag_location', $
    header_pid                       : 7, $
    header_packet_category           : 4, $
    header_data_field_length         : 16, $ ; in bytes (total bytes -1)
    header_service_type              : 8, $
    header_service_subtype           : 8, $
    ssid                             : 8, $
    coarse_time                      : 32, $
    fine_time                        : 16, $
    integration_time                 : 16, $
    number_of_samples                : 16, $ ; = N
    dynamic_flare_flag               : 0U, $ ; dynamic, will be filled during execution with  N*1  octet
    dynamic_flare_location_z         : 0, $ ; dynamic, will be filled during execution with  N*1 octet
    dynamic_flare_location_y         : 0, $ ; dynamic, will be filled during execution with  N*1  octet
    pkg_total_bytes_fixed            : long(0) $
  } ; 80 bits fixed = 10 bytes

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
    type                             : 'stx_tmtc_ql_flare_flag_location', $
    header_pid                       : uint(93),  $     ; fixed
    header_packet_category           : uint(12),  $     ; fixed
    header_data_field_length         : uint(0),   $
    header_service_type              : uint(21),  $     ; fixed
    header_service_subtype           : uint(6),   $     ; fixed
    ssid                             : uint(34),  $     ; fixed
    coarse_time                      : ulong(0), $
    fine_time                        : uint(0), $
    integration_time                 : uint(0), $
    number_of_samples                : uint(0), $
    dynamic_flare_flag               : ptr_new(), $ 
    dynamic_flare_location_z         : ptr_new(), $
    dynamic_flare_location_y         : ptr_new(), $ 
    pkg_word_width                   : packet_word_width $
  }

  return, packet
end