;+
; :description:
;   This function creates an uninitialized stx_telemetry_packet_structure_ql_calibration_spectrum structure.
;
; :categories:
;    flight software, structure definition, telemetry
;
; :returns:
;    an uninitialized stx_telemetry_packet_structure_ql_calibration_spectrum structure
;
; :examples:
;    See stx_demo_tmtc.pro
;
; :history:
;     21-Sep-2016, Simon Marcin (FHNW), updated according to STIX-ICD-0812-ESC_I3R1draft2_TMTC_ICD.pdf
;     08-Mar-2019, ECMD (Graz), changed fix() to uint() to avoid reading negative values from unsigned telemetry parameters 
;     
;-

function stx_telemetry_packet_structure_ql_calibration_spectrum, packet_word_width=packet_word_width
  packet_word_width = { $
    type                           : 'stx_tmtc_word_width', $
    packet                         : 'stx_tmtc_ql_calibration_spectrum', $
    header_pid                     : 7, $
    header_packet_category         : 4, $
    header_data_field_length       : 16, $ ; in bytes (total bytes -1)
    header_service_type            : 8, $
    header_service_subtype         : 8, $
    ssid                           : 8, $
    coarse_time                    : 32, $
    duration                       : 32, $
    quiet_time                     : 16, $
    live_time                      : 32, $
    average_temperature            : 16, $
    spare_c                        : 1, $
    compression_schema             : 7, $
    detector_mask                  : 32, $
    spare                          : 4, $
    pixel_mask                     : 12, $
    subspectrum_mask               : 8, $
  ;  spare2                         : 2, $
    s1_spare                       : 2, $
    s1_nbr_points                  : 10, $
    s1_nbr_channels                : 10, $
    s1_lowest_channel              : 10, $
    s2_spare                       : 2, $
    s2_nbr_points                  : 10, $
    s2_nbr_channels                : 10, $
    s2_lowest_channel              : 10, $
    s3_spare                       : 2, $
    s3_nbr_points                  : 10, $
    s3_nbr_channels                : 10, $
    s3_lowest_channel              : 10, $
    s4_spare                       : 2, $
    s4_nbr_points                  : 10, $
    s4_nbr_channels                : 10, $
    s4_lowest_channel              : 10, $
    s5_spare                       : 2, $
    s5_nbr_points                  : 10, $
    s5_nbr_channels                : 10, $
    s5_lowest_channel              : 10, $
    s6_spare                       : 2, $
    s6_nbr_points                  : 10, $
    s6_nbr_channels                : 10, $
    s6_lowest_channel              : 10, $
    s7_spare                       : 2, $
    s7_nbr_points                  : 10, $
    s7_nbr_channels                : 10, $
    s7_lowest_channel              : 10, $
    s8_spare                       : 2, $
    s8_nbr_points                  : 10, $
    s8_nbr_channels                : 10, $
    s8_lowest_channel              : 10, $
    number_of_structures           : 16, $
    dynamic_spare                  : 0UL, $ 
    dynamic_detector_id            : 0UL, $ 
    dynamic_pixel_id               : 0UL, $ 
    dynamic_subspectra_id          : 0UL, $ 
    dynamic_number_points          : 0UL, $ 
    dynamic_spectral_points        : 0UL, $ 
    pkg_total_bytes_fixed          : long(0) $
  } ; 472 bits fixed = 59 bytes

  tags = strlowcase(tag_names(packet_word_width))
  
  ignore = arr2str('^' + ['type', 'packet', 'header_.*', 'dynamic_*', 'pkg_.*'] + '$', delimiter='|')
  
  for i = 0L, n_tags(packet_word_width)-1 do begin
    if(stregex(tags[i], ignore , /boolean)) then continue $
    else packet_word_width.pkg_total_bytes_fixed += packet_word_width.(i)
  endfor
  
  ; transform bits to bytes
  if (packet_word_width.pkg_total_bytes_fixed MOD 8 gt 0) then message, 'bits are no multiple of 8'
  packet_word_width.pkg_total_bytes_fixed /= 8
  
  packet = { $
    type                           : 'stx_tmtc_ql_calibration_spectrum', $
    header_pid                     : uint(93),  $     ; fixed
    header_packet_category         : uint(12),  $     ; fixed
    header_data_field_length       : uint(0),   $
    header_service_type            : uint(21),  $     ; fixed
    header_service_subtype         : uint(6),   $      ; fixed
    ssid                           : uint(41),  $     ; fixed
    coarse_time                    : ulong(0),  $     ; in seconds
    duration                       : ulong(0),  $     ; in seconds
    quiet_time                     : uint(0),   $
    live_time                      : ulong(0),  $
    average_temperature            : uint(0),   $
    spare_c                        : byte(0),   $
    compression_schema             : uint(0),   $      ; s, kkk, mmm
    detector_mask                  : ulong(0),  $
    spare                          : byte(0),   $
    pixel_mask                     : uint(0),   $
    subspectrum_mask               : uint(0),   $
  ;  spare2                         : byte(0),   $
    s1_spare                       : byte(0),   $
    s1_nbr_points                  : uint(0),    $
    s1_nbr_channels                : uint(0),    $
    s1_lowest_channel              : uint(0),    $
    s2_spare                       : byte(0),   $
    s2_nbr_points                  : uint(0),    $
    s2_nbr_channels                : uint(0),    $
    s2_lowest_channel              : uint(0),    $
    s3_spare                       : byte(0),   $
    s3_nbr_points                  : uint(0),    $
    s3_nbr_channels                : uint(0),    $
    s3_lowest_channel              : uint(0),    $
    s4_spare                       : byte(0),   $
    s4_nbr_points                  : uint(0),    $
    s4_nbr_channels                : uint(0),    $
    s4_lowest_channel              : uint(0),    $
    s5_spare                       : byte(0),   $
    s5_nbr_points                  : uint(0),    $
    s5_nbr_channels                : uint(0),    $
    s5_lowest_channel              : uint(0),    $
    s6_spare                       : uint(0),   $
    s6_nbr_points                  : uint(0),    $
    s6_nbr_channels                : uint(0),    $
    s6_lowest_channel              : uint(0),    $
    s7_spare                       : byte(0),   $
    s7_nbr_points                  : uint(0),    $
    s7_nbr_channels                : uint(0),    $
    s7_lowest_channel              : uint(0),    $
    s8_spare                       : byte(0),   $
    s8_nbr_points                  : uint(0),    $
    s8_nbr_channels                : uint(0),    $
    s8_lowest_channel              : uint(0),    $
    number_of_structures           : uint(0),   $
    dynamic_spare                  : ptr_new(), $ 
    dynamic_detector_id            : ptr_new(), $ 
    dynamic_pixel_id               : ptr_new(), $ 
    dynamic_subspectra_id          : ptr_new(), $ 
    dynamic_number_points          : ptr_new(), $
    dynamic_spectral_points        : ptr_new(), $ 
    pkg_word_width                 : packet_word_width $
  }
  
  return, packet
end