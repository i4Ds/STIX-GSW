;+
; :description:
;   This function creates an uninitialized stx_telemetry_packet_structure_ql_light_curves structure.
;
; :categories:
;    flight software, structure definition, telemetry
;
; :returns:
;    an uninitialized stx_telemetry_packet_structure_ql_light_curves structure
;
; :examples:
;    ...
;
; :history:
;     29-Oct-2015, Simon Marcin (FHNW), initial release
;
;-
function stx_telemetry_packet_structure_ql_light_curves, packet_word_width=packet_word_width
  packet_word_width = { $
    type                             : 'stx_tmtc_word_width', $
    packet                           : 'stx_tmtc_ql_light_curves', $
    header_pid                       : 7, $
    header_packet_category           : 4, $
    header_data_field_length         : 16, $ ; in bytes (total bytes -1)
    header_service_type              : 8, $
    header_service_subtype           : 8, $
    ssid                             : 8, $
    coarse_time                      : 32, $
    fine_time                        : 16, $
    integration_time                 : 16, $
    detector_mask                    : 32, $   
    spare_1                          : 4, $
    pixel_mask                       : 12, $
    spare_2                          : 1, $
    compression_schema_light_curves  : 7, $  
    compression_schema_trigger       : 7, $ 
    energy_bin_mask                  : 33, $  
    number_of_energies               : 8, $
    dynamic_nbr_of_data_points       : 0UL, $
    dynamic_lightcurves              : 0UL, $
    number_of_triggers               : 16, $
    dynamic_trigger_accumulator      : 0UL, $ ;
    number_of_rcrs                   : 16, $
    dynamic_rcr_values               : 0, $ ;
    pkg_total_bytes_fixed            : long(0) $
  } ; 176 bits fixed = 22 bytes

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
    type                             : 'stx_tmtc_ql_light_curves', $
    header_pid                       : uint(93),  $     ; fixed
    header_packet_category           : uint(12),  $     ; fixed
    header_data_field_length         : uint(0),   $
    header_service_type              : uint(21),  $     ; fixed
    header_service_subtype           : uint(6),   $     ; fixed
    ssid                             : uint(30),  $     ; fixed
    coarse_time                      : ulong(0), $
    fine_time                        : uint(0), $
    integration_time                 : uint(0), $
    detector_mask                    : ulong(0), $
    spare_1                          : byte(0), $
    pixel_mask                       : uint(0), $
    spare_2                          : uint(0), $
    compression_schema_light_curves  : uint(0), $       ; 1 spare, s, kkk, mmm
    compression_schema_trigger       : uint(0), $       ; 1 spare, s, kkk, mmm        
    energy_bin_mask                  : ulong64(0), $    ; 33 
    number_of_energies               : uint(0), $
    dynamic_nbr_of_data_points       : uint(0), $
    dynamic_lightcurves              : ptr_new(), $
    number_of_triggers               : uint(0), $
    dynamic_trigger_accumulator      : ptr_new(), $ ;
    number_of_rcrs                   : uint(0), $
    dynamic_rcr_values               : ptr_new(), $ ; 
    pkg_word_width                   : packet_word_width $
  }

  return, packet
end