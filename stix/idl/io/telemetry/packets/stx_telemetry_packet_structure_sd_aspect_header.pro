;+
; :DESCRIPTION:
;   This function creates an uninitialized stx_telemetry_packet_structure_sd_aspect structure.
;
; :CATEGORIES:
;    flight software, structure definition, telemetry, aspect
;
; :RETURNS:
;    an uninitialized stx_telemetry_packet_structure_sd_aspect structure
;
; :EXAMPLES:
;    ...
;
; :HISTORY:
;     6-Mar-2017, Nicky hochmuth (FHNW), initial release
;
;-
function stx_telemetry_packet_structure_sd_aspect_header, packet_word_width=packet_word_width

  packet_word_width = { $
    type                             : 'stx_tmtc_word_width', $
    packet                           : 'stx_tmtc_sd_aspect', $
    header_pid                       : 7, $
    header_packet_category           : 4, $
    header_data_field_length         : 16, $       ; in bytes (total bytes -1)
    header_service_type              : 8, $
    header_service_subtype           : 8, $
    ssid                             : 8, $
    coarse_time                      : 32, $       ; split of measurement_time_step
    fine_time                        : 16, $       ; split of measurement_time_step
    summing                          : 8, $
    number_samples                   : 16, $  ; N
    dynamic_cha1                     : 0UL, $ ; dynamic, will be filled during execution with  N*2  octet
    dynamic_cha2                     : 0UL, $ ; dynamic, will be filled during execution with  N*2  octet
    dynamic_chb1                     : 0UL, $ ; dynamic, will be filled during execution with  N*2  octet
    dynamic_chb2                     : 0UL, $ ; dynamic, will be filled during execution with  N*2  octet
    pkg_total_bytes_fixed            : long(0) $
  } ; 704 bits fixed = 88 bytes

  tags = strlowcase(tag_names(packet_word_width))

  ; definition of ignored packets for size calculation
  ignore = arr2str('^' + ['type', 'packet', 'header_.*', 'dynamic_*', 'pkg_.*', 'helper_.*'] + '$', delimiter='|')

  ; compute pkg_total_bytes_fixed
  for i = 0L, n_tags(packet_word_width)-1 do begin
    if(stregex(tags[i], ignore , /boolean)) then continue $
    else packet_word_width.pkg_total_bytes_fixed += packet_word_width.(i)
  endfor

  ; transform bits to bytes
  if (packet_word_width.pkg_total_bytes_fixed mod 8 gt 0) then message, 'bits are no multiple of 8'
  packet_word_width.pkg_total_bytes_fixed /= 8

  packet = { $
    type                             : 'stx_tmtc_sd_aspect', $
    header_pid                       : uint(91),  $     ; fixed
    header_packet_category           : uint(12),  $     ; fixed
    header_data_field_length         : uint(0),   $
    header_service_type              : uint(21),  $     ; fixed
    header_service_subtype           : uint(6),   $     ; fixed
    ssid                             : uint(42),  $     ; fixed
    coarse_time                      : ulong(0), $      ; split of measurement_time_step
    fine_time                        : long(0), $       ; split of measurement_time_step
    summing                          : uint(0), $
    number_samples                   : uint(0), $
    dynamic_cha1                     : ptr_new(), $
    dynamic_cha2                     : ptr_new(), $
    dynamic_chb1                     : ptr_new(), $
    dynamic_chb2                     : ptr_new(), $
    pkg_total_bytes_fixed            : long(0), $
    pkg_word_width                   : packet_word_width $
  }

  return, packet
end