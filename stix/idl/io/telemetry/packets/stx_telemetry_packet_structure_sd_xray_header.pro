;+
; :description:
;   This function creates an uninitialized stx_telemetry_packet_structure_sd_x-rayx structure.
;   NB: The current structure is only valid for SSID=20,21,22,23
;
; :categories:
;    flight software, structure definition, telemetry, xray
;
; :returns:
;    an uninitialized stx_telemetry_packet_structure_sd_xrayx structure
;
; :examples:
;    ...
;
; :history:
;     22-Mar-2016, Simon Marcin (FHNW), initial release
;     21-Sep-2016, Simon Marcin (FHNW), added compression schmeas
;     01-May-2018, Laszlo I. Etesi (FHNW), updated structure in accordance with ICD
;
;-
function stx_telemetry_packet_structure_sd_xray_header, packet_word_width=packet_word_width
  packet_word_width = { $
    type                             : 'stx_tmtc_word_width', $
    packet                           : 'stx_tmtc_sd_xray', $
    header_pid                       : 7, $
    header_packet_category           : 4, $
    header_data_field_length         : 16, $       ; in bytes (total bytes -1)
    header_service_type              : 8, $
    header_service_subtype           : 8, $
    ssid                             : 8, $
    reference_tc_packet_id           : 16, $
    reference_tc_packet_sequence     : 16, $
    unique_request_number            : 32, $
    compression_schema_acc           : 8, $        ; +1 spare bit
    compression_schema_t             : 8, $        ; +1 spare bit
    ;measurement_time_stamp          : 48, $
    coarse_time                      : 32, $       ; split of measurement_time_stamp
    fine_time                        : 16, $       ; split of measurement_time_stamp
    number_time_samples              : 16, $
    dynamic_subheaders               : 0UL, $ ; dynamic, will be filled during execution with
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
  if (packet_word_width.pkg_total_bytes_fixed MOD 8 gt 0) then message, 'bits are no multiple of 8'
  packet_word_width.pkg_total_bytes_fixed /= 8

  packet = { $
    type                             : 'stx_tmtc_sd_xray', $
    header_pid                       : uint(91),  $     ; fixed
    header_packet_category           : uint(12),  $     ; fixed
    header_data_field_length         : uint(0),   $
    header_service_type              : uint(21),  $     ; fixed
    header_service_subtype           : uint(6),   $     ; fixed
    ssid                             : uint(0),   $
    reference_tc_packet_id           : uint(0),   $
    reference_tc_packet_sequence     : uint(0),   $
    unique_request_number            : uint(0),   $
    compression_schema_acc           : uint(0),   $     ; +1 spare bit
    compression_schema_t             : uint(0),   $     ; +1 spare bit
    ;    measurement_time_stamp      : ulong64(0) $     ;
    coarse_time                      : ulong(0),  $     ; split of measurement_time_stamp
    fine_time                        : long(0),   $     ; split of measurement_time_stamp
    number_time_samples              : uint(0),   $     ; defines N
    dynamic_subheaders               : ptr_new(), $     
    pkg_word_width                   : packet_word_width $
  }

  return, packet
end