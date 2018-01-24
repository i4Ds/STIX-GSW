;+
; :description:
;   This function creates an uninitialized stx_telemetry_packet_structure_hc_heartbeat structure.
;
; :categories:
;    flight software, structure definition, telemetry
;
; :returns:
;    an uninitialized stx_telemetry_packet_structure_hc_heartbeat
;
; :examples:
;    ...
;
; :history:
;     01-Dez-2015, Simon Marcin (FHNW), initial release
;     23-Aug-2016, Simon Marcin (FHNW), added attenuator_motion
;
;-
function stx_telemetry_packet_structure_hc_heartbeat, packet_word_width=packet_word_width
  packet_word_width = { $
    type                             : 'stx_tmtc_word_width', $
    packet                           : 'stx_tmtc_hc_heartbeat', $
    header_pid                       : 7, $
    header_packet_category           : 4, $
    header_data_field_length         : 16, $ ; in bytes (total bytes -1)
    header_service_type              : 8, $
    header_service_subtype           : 8, $
    ssid                             : 8, $
    obt_coarse_time                  : 32, $
    flare_message                    : 8, $
    x_location                       : 8, $
    y_location                       : 8, $
    flare_duration                   : 32, $ 
    attenuator_motion                : 1, $
    spare_block                      : 23, $
    pkg_total_bytes_fixed            : long(0) $
  } ; 120 bits fixed = 15 bytes

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
    type                             : 'stx_tmtc_hc_heartbeat', $
    header_pid                       : uint(94),  $    ; fixed
    header_packet_category           : uint(5),  $     ; fixed
    header_data_field_length         : uint(0),   $
    header_service_type              : uint(3),  $     ; fixed
    header_service_subtype           : uint(25),   $   ; fixed
    ssid                             : uint(4),  $     ; fixed
    obt_coarse_time                  : ulong(0), $
    flare_message                    : byte(0), $      ; bitmask
    x_location                       : fix(0), $
    y_location                       : fix(0), $
    flare_duration                   : ulong(0), $ 
    attenuator_motion                : byte(0), $
    spare_block                      : ulong(0), $     ; only 23 bits
    pkg_word_width                   : packet_word_width $
  }

  return, packet
end