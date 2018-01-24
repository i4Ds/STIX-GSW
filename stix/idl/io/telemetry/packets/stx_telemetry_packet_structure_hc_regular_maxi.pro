;+
; :description:
;   This function creates an uninitialized stx_telemetry_packet_structure_hc_regular_maxi.
;
; :categories:
;    flight software, structure definition, telemetry
;
; :returns:
;    an uninitialized stx_telemetry_packet_structure_hc_regular_maxi
;
; :examples:
;    ...
;
; :history:
;     03-Aug-2016, Simon Marcin (FHNW), initial release
;     12-Jun-2017, Laszlo I. Etesi (FHNW), updated structure according to TMTC
;
; :toDo:
;     03-Aug-2016, Simon Marcin (FHNW), split the value of FDIR_function_status according to table ???
;-
function stx_telemetry_packet_structure_hc_regular_maxi, packet_word_width=packet_word_width
  packet_word_width = { $
    type                             : 'stx_tmtc_word_width', $
    packet                           : 'stx_tmtc_hc_regular_maxi', $
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
    HK_ASP_REF_2V5A_V                : 12, $
    HK_ASP_REF_2V5B_V                : 12, $
    HK_ASP_TIM01_T                   : 12, $
    HK_ASP_TIM02_T                   : 12, $
    HK_ASP_TIM03_T                   : 12, $
    HK_ASP_TIM04_T                   : 12, $
    HK_ASP_TIM05_T                   : 12, $
    HK_ASP_TIM06_T                   : 12, $
    HK_ASP_TIM07_T                   : 12, $
    HK_ASP_TIM08_T                   : 12, $
    HK_ASP_VSENSA_V                  : 12, $
    HK_ASP_VSENSB_V                  : 12, $
    HK_ATT_V                         : 12, $
    ATT_T                            : 12, $
    HK_HV_01_16_V                    : 12, $
    HK_HV_17_32_V                    : 12, $
    DET_Q1_T                         : 12, $
    DET_Q2_T                         : 12, $
    DET_Q3_T                         : 12, $
    DET_Q4_T                         : 12, $
    HK_DPU_1V5_V                     : 12, $
    HK_REF_2V5_V                     : 12, $
    HK_DPU_2V9_V                     : 12, $
    HK_PSU_TEMP_T                    : 12, $
    
    ;   HW_SW_status_1                   : 32, $  HW_SW_status_1 is 32 bits (8+5+1+1+8+1+1+1+6)
    sw_version_number                : 8, $
    CPU_load                         : 5, $
    autonomous_ASW_booting_status    : 1, $
    memory_load_enable_flag          : 1, $
    archive_memory_usage             : 8, $
    identifier_IDPU                  : 1, $
    identifier_active_SpW_link       : 1, $
    watchdog_state                   : 1, $
    first_overrun_task               : 6, $

    ;   HW_SW_status_2                   : 32, $  HW_SW_status_2 is 32 bits (16+16)
    commands_received                : 16, $ ;
    commands_rejected                : 16, $ ;
     
    ;   HW_SW_status_3                   : ulong(0), $
    detector_status                  : 32, $
    
    ;   HW_SW_status_4                   : ulong(0), $
    sw_status_4_spare1               : 3, $
    power_status_spw1                : 1, $
    power_status_spw2                : 1, $
    power_status_q4                  : 1, $
    power_status_q3                  : 1, $
    power_status_q2                  : 1, $
    power_status_q1                  : 1, $
    power_aspect_b                   : 1, $
    power_aspect_a                   : 1, $
    attenuator_moving_2              : 1, $
    attenuator_moving_1              : 1, $
    power_status_hv_17_32            : 1, $
    power_status_hv_01_16            : 1, $
    power_status_lv                  : 1, $
    HV1_depolarization               : 1, $
    HV2_depolarization               : 1, $
    attenuator_AB_position_flag      : 1, $
    attenuator_BC_position_flag      : 1, $
    sw_status_4_spare2               : 12, $
    
    ; cont'd HK (outside HW/SW group)
    median_value_trigger_accs        : 24, $
    max_value_trigger_accs           : 24, $
    HV_regulators_mask               : 2, $
    sequence_count_last_TC           : 14, $
    total_attenuator_motions         : 16, $
    HK_ASP_PHOTOA0_V                 : 16, $
    HK_ASP_PHOTOA1_V                 : 16, $
    HK_ASP_PHOTOB0_V                 : 16, $
    HK_ASP_PHOTOB1_V                 : 16, $
    Attenuator_currents              : 16, $
    HK_ATT_C                         : 12, $
    HK_DET_C                         : 12, $
    FDIR_function_status             : 32, $
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
    type                             : 'stx_tmtc_hc_regular_maxi', $
    header_pid                       : uint(90),  $    ; fixed
    header_packet_category           : uint(4),  $     ; fixed
    header_data_field_length         : uint(0),   $
    header_service_type              : uint(3),  $     ; fixed
    header_service_subtype           : uint(25),   $   ; fixed
    ssid                             : uint(2),  $     ; fixed
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
    HK_ASP_REF_2V5A_V                : uint(0), $
    HK_ASP_REF_2V5B_V                : uint(0), $
    HK_ASP_TIM01_T                   : uint(0), $
    HK_ASP_TIM02_T                   : uint(0), $
    HK_ASP_TIM03_T                   : uint(0), $
    HK_ASP_TIM04_T                   : uint(0), $
    HK_ASP_TIM05_T                   : uint(0), $
    HK_ASP_TIM06_T                   : uint(0), $
    HK_ASP_TIM07_T                   : uint(0), $
    HK_ASP_TIM08_T                   : uint(0), $
    HK_ASP_VSENSA_V                  : uint(0), $
    HK_ASP_VSENSB_V                  : uint(0), $
    HK_ATT_V                         : uint(0), $
    ATT_T                            : uint(0), $
    HK_HV_01_16_V                    : uint(0), $
    HK_HV_17_32_V                    : uint(0), $
    DET_Q1_T                         : uint(0), $
    DET_Q2_T                         : uint(0), $
    DET_Q3_T                         : uint(0), $
    DET_Q4_T                         : uint(0), $
    HK_DPU_1V5_V                     : uint(0), $
    HK_REF_2V5_V                     : uint(0), $
    HK_DPU_2V9_V                     : uint(0), $
    HK_PSU_TEMP_T                    : uint(0), $
    
    ;   HW_SW_status_1                   : ulong(0), $
    sw_version_number                : uint(0), $
    CPU_load                         : byte(0), $
    autonomous_asw_booting_status    : byte(0), $
    memory_load_enable_flag          : byte(0), $
    archive_memory_usage             : uint(0), $
    identifier_IDPU                  : byte(0), $
    identifier_active_SpW_link       : byte(0), $
    watchdog_state                   : byte(0), $
    first_overrun_task               : byte(0), $
    
    ;   HW_SW_status_2                   : ulong(0), $
    commands_received                : uint(0), $
    commands_rejected                : uint(0), $
    
    ;   HW_SW_status_3                   : ulong(0), $
    detector_status                  : ulong(0), $
    
    ;   HW_SW_status_4                   : ulong(0), $
    sw_status_4_spare1               : byte(0), $
    power_status_spw1                : byte(0), $
    power_status_spw2                : byte(0), $
    power_status_q4                  : byte(0), $
    power_status_q3                  : byte(0), $
    power_status_q2                  : byte(0), $
    power_status_q1                  : byte(0), $
    power_aspect_b                   : byte(0), $
    power_aspect_a                   : byte(0), $
    attenuator_moving_2              : byte(0), $
    attenuator_moving_1              : byte(0), $
    power_status_hv_17_32            : byte(0), $
    power_status_hv_01_16            : byte(0), $
    power_status_lv                  : byte(0), $
    HV1_depolarization               : byte(0), $
    HV2_depolarization               : byte(0), $
    attenuator_AB_position_flag      : byte(0), $
    attenuator_BC_position_flag      : byte(0), $
    sw_status_4_spare2               : uint(0), $
    median_value_trigger_accs        : ulong(0), $
    max_value_trigger_accs           : ulong(0), $
    HV_regulators_mask               : byte(0), $
    sequence_count_last_TC           : uint(0), $
    total_attenuator_motions         : uint(0), $
    HK_ASP_PHOTOA0_V                 : uint(0), $
    HK_ASP_PHOTOA1_V                 : uint(0), $
    HK_ASP_PHOTOB0_V                 : uint(0), $
    HK_ASP_PHOTOB1_V                 : uint(0), $
    Attenuator_currents              : uint(0), $
    HK_ATT_C                         : uint(0), $
    HK_DET_C                         : uint(0), $
    FDIR_function_status             : ulong(0), $
    pkg_word_width                   : packet_word_width $
  }

  return, packet
end