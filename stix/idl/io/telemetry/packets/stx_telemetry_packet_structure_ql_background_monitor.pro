;+
; :description:
;   This function creates an uninitialized stx_telemetry_packet_structure_ql_background_monitor structure.
;
; :categories:
;    flight software, structure definition, telemetry
;
; :returns:
;    an uninitialized stx_telemetry_packet_structure_ql_background_monitor structure
;
; :examples:
;    See stx_demo_telemetry_ql_background_monitor
;
; :history:
;     10-Dec-2015, Simon Marcin (FHNW), initial release
;     19-Sep-2016, Simon Marcin (FHNW), updated according to STIX-ICD-0812-ESC_I3R1draft2_TMTC_ICD.pdf
;
;-
function stx_telemetry_packet_structure_ql_background_monitor, packet_word_width=packet_word_width
  packet_word_width = { $
    type                             : 'stx_tmtc_word_width', $
    packet                           : 'stx_tmtc_ql_background_monitor', $
    header_pid                       : 7, $
    header_packet_category           : 4, $
    header_data_field_length         : 16, $  ; in bytes (total bytes -1)
    header_service_type              : 8, $
    header_service_subtype           : 8, $
    ssid                             : 8, $
    coarse_time                      : 32, $
    fine_time                        : 16, $
    integration_time                 : 16, $
    compression_schema_background    : 7, $       ; s, kkk, mmm
    energy_bin_mask                  : 33, $  ; 32bit (lower boundaries) & 1bit (upper boundaries)
    spare                            : 1, $
    ;spare2                           : 24, $
    compression_schema_trigger       : 7, $       ; s, kkk, mmm
    number_of_energies               : 8, $
    dynamic_nbr_of_data_points       : 0UL, $
    dynamic_background               : 0UL, $
    number_of_triggers               : 16, $
    dynamic_trigger_accumulator      : 0UL, $ 
    pkg_total_bytes_fixed            : long(0) $      
  }

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
    type                             : 'stx_tmtc_ql_background_monitor', $
    header_pid                       : uint(93),  $     ; fixed
    header_packet_category           : uint(12),  $     ; fixed
    header_data_field_length         : uint(0),   $
    header_service_type              : uint(21),  $     ; fixed
    header_service_subtype           : uint(6),   $     ; fixed
    ssid                             : uint(31),  $     ; fixed
    coarse_time                      : ulong(0), $
    fine_time                        : uint(0), $
    integration_time                 : uint(0), $
    compression_schema_background    : uint(0), $       ; s, kkk, mmm
    energy_bin_mask                  : ulong64(0), $    ; 32bit (lower boundaries) & 1bit (upper boundaries)
    spare                            : byte(0), $
    ;spare2                           : ulong(0), $
    compression_schema_trigger       : uint(0), $       ; s, kkk, mmm
    number_of_energies               : uint(0), $
    dynamic_nbr_of_data_points       : uint(0), $
    dynamic_background               : ptr_new(), $
    number_of_triggers               : uint(0), $
    dynamic_trigger_accumulator      : ptr_new(), $ ;
    pkg_word_width                   : packet_word_width $
  }

  return, packet
end