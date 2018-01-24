;+
; :description:
;   This function creates an uninitialized stx_telemetry_packet_structure_hc_regular_mini.
;
; :categories:
;    flight software, structure definition, telemetry
;
; :returns:
;    an uninitialized stx_telemetry_packet_structure_hc_regular_mini
;
; :examples:
;    ...
;
; :history:
;     17-Feb-2016, Simon Marcin (FHNW), initial release
;
; :toDo:
;     03-Aug-2016, Simon Marcin (FHNW), split the value of FDIR_function_status according to table ???
;-
function stx_telemetry_packet_structure_hc_regular_mini, packet_word_width=packet_word_width
  packet_word_width = { $
    type                             : 'stx_tmtc_word_width', $
    packet                           : 'stx_tmtc_hc_regular_mini', $
    header_pid                       : 7, $
    header_packet_category           : 4, $
    header_data_field_length         : 16, $ ; in bytes (total bytes -1)
    header_service_type              : 8, $
    header_service_subtype           : 8, $
    ssid                             : 8, $
    sw_running                       : 1, $
    instrument_number                : 3, $
    instrument_mode                  : 4, $
    HK_DPU_PCB_T                     : 12, $
    HK_DPU_FPGA_T                    : 12, $
    HK_DPU_3V3_C                     : 12, $
    HK_DPU_2V5_C                     : 12, $
    HK_DPU_1V5_C                     : 12, $
    HK_DPU_SPW_C                     : 12, $
    HK_DPU_SPW0_V                    : 12, $
    HK_DPU_SPW1_V                    : 12, $
;   HW_SW_status_1                   : 32, $  HW_SW_status_1 is 32 bits (8+7+8+1+1+7)
    sw_version_number                : 8, $
    CPU_load                         : 7, $
    archive_memory_usage             : 8, $
    identifier_IDPU                  : 1, $
    identifier_active_SpW_link       : 1, $
    sw_status_1_spare                : 7, $  
;   HW_SW_status_2                   : 32, $  HW_SW_status_2 is 32 bits (16+16)
    commands_rejected                : 16, $
    commands_received                : 16, $
    HK_DPU_1V5_V                     : 12, $
    HK_REF_2V5_V                     : 12, $
    HK_DPU_2V9_V                     : 12, $
    HK_PSU_TEMP_T                    : 12, $
    FDIR_function_status             : 32, $
    FDIR_temp_status                 : 16, $
    FDIR_voltage_status              : 16, $
    spare                            : 2, $
    FDIR_current_status              : 6, $
    executed_tc_packets              : 16, $
    sent_tc_packets                  : 16, $
    failed_tm_generations            : 16, $
    pkg_total_bytes_fixed            : long(0) $
  } ; 320 bits fixed = 40 bytes

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
    type                             : 'stx_tmtc_hc_regular_mini', $
    header_pid                       : uint(90),  $    ; fixed
    header_packet_category           : uint(4),  $     ; fixed
    header_data_field_length         : uint(0),   $
    header_service_type              : uint(3),  $     ; fixed
    header_service_subtype           : uint(25),   $   ; fixed
    ssid                             : uint(1),  $     ; fixed
    sw_running                       : byte(0), $
    instrument_number                : byte(0), $
    instrument_mode                  : byte(0), $
    HK_DPU_PCB_T                     : uint(0), $
    HK_DPU_FPGA_T                    : uint(0), $
    HK_DPU_3V3_C                     : uint(0), $
    HK_DPU_2V5_C                     : uint(0), $
    HK_DPU_1V5_C                     : uint(0), $
    HK_DPU_SPW_C                     : uint(0), $
    HK_DPU_SPW0_V                    : uint(0), $
    HK_DPU_SPW1_V                    : uint(0), $
;   HW_SW_status_1                   : ulong(0), $
    sw_version_number                : uint(0), $
    CPU_load                         : byte(0), $
    archive_memory_usage             : uint(0), $
    identifier_IDPU                  : byte(0), $
    identifier_active_SpW_link       : byte(0), $
    sw_status_1_spare                : byte(0), $
;   HW_SW_status_2                   : ulong(0), $
    commands_rejected                : uint(0), $
    commands_received                : uint(0), $
    HK_DPU_1V5_V                     : uint(0), $
    HK_REF_2V5_V                     : uint(0), $
    HK_DPU_2V9_V                     : uint(0), $
    HK_PSU_TEMP_T                    : uint(0), $
    FDIR_function_status             : ulong(0), $
    FDIR_temp_status                 : uint(0), $
    FDIR_voltage_status              : uint(0), $
    spare                            : uint(0), $
    FDIR_current_status              : uint(0), $
    executed_tc_packets              : uint(0), $
    sent_tc_packets                  : uint(0), $
    failed_tm_generations            : uint(0), $
    pkg_word_width                   : packet_word_width $
  }

  return, packet
end