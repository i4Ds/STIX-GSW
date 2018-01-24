;+
; :description:
;   structure that contains analysis software house keeping report data
;
; :categories:
;    analysis software, structure definition, house keeping data
;
; :returns:
;    an uninitialized structure
;
; :history:
;     27-Jul-2016 - Simon Marcin (FHNW), init
;     21-Dec-2016 - Simon Marcin (FHNW), added random keyword
;
;-
function stx_asw_hc_regular_mini, random=random
  default, random, 0
  
  ;init
  stxtime                          = stx_time()
  sw_running                       = byte(1)
  instrument_number                = byte(1)
  instrument_mode                  = byte(0)
  HK_DPU_PCB_T                     = uint(0)
  HK_DPU_FPGA_T                    = uint(0)
  HK_DPU_3V3_C                     = uint(0)
  HK_DPU_2V5_C                     = uint(0)
  HK_DPU_1V5_C                     = uint(0)
  HK_DPU_SPW_C                     = uint(0)
  HK_DPU_SPW0_V                    = uint(0)
  HK_DPU_SPW1_V                    = uint(0)
  sw_version_number                = uint(0)
  CPU_load                         = byte(0)
  archive_memory_usage             = uint(0)
  identifier_IDPU                  = byte(0)
  identifier_active_SpW_link       = byte(0)
  sw_status_1_spare                = byte(0)
  commands_rejected                = uint(0)
  commands_received                = uint(0)
  HK_DPU_1V5_V                     = uint(0)
  HK_REF_2V5_V                     = uint(0)
  HK_DPU_2V9_V                     = uint(0)
  HK_PSU_TEMP_T                    = uint(0)
  FDIR_function_status             = bytarr(32)
  FDIR_temp_status                 = uint(0)
  FDIR_voltage_status              = uint(0)
  spare                            = uint(0)
  FDIR_current_status              = uint(0)
  executed_tc_packets              = uint(0)
  sent_tc_packets                  = uint(0)
  failed_tm_generations            = uint(0)
  
  ;random numbers
  if random then begin
    stxtime                          = stx_time_add(stx_time(),seconds=uint((2^14)*RANDOMU(Seed)))
    sw_running                       = byte(1)
    instrument_mode                  = uint((2ULL^4) * RANDOMU(seed))
    HK_DPU_PCB_T                     = uint((2ULL^12) * RANDOMU(seed))
    HK_DPU_FPGA_T                    = uint((2ULL^12) * RANDOMU(seed))
    HK_DPU_3V3_C                     = uint((2ULL^12) * RANDOMU(seed))
    HK_DPU_2V5_C                     = uint((2ULL^12) * RANDOMU(seed))
    HK_DPU_1V5_C                     = uint((2ULL^12) * RANDOMU(seed))
    HK_DPU_SPW_C                     = uint((2ULL^12) * RANDOMU(seed))
    HK_DPU_SPW0_V                    = uint((2ULL^12) * RANDOMU(seed))
    HK_DPU_SPW1_V                    = uint((2ULL^12) * RANDOMU(seed))
    sw_version_number                = uint((2ULL^8) * RANDOMU(seed))
    CPU_load                         = uint((2ULL^7) * RANDOMU(seed))
    archive_memory_usage             = uint((2ULL^8) * RANDOMU(seed))
    identifier_IDPU                  = uint((2ULL^1) * RANDOMU(seed))
    identifier_active_SpW_link       = uint((2ULL^1) * RANDOMU(seed))
    commands_rejected                = uint((2ULL^16) * RANDOMU(seed))
    commands_received                = uint((2ULL^16) * RANDOMU(seed))
    HK_DPU_1V5_V                     = uint((2ULL^12) * RANDOMU(seed))
    HK_REF_2V5_V                     = uint((2ULL^12) * RANDOMU(seed))
    HK_DPU_2V9_V                     = uint((2ULL^12) * RANDOMU(seed))
    HK_PSU_TEMP_T                    = uint((2ULL^12) * RANDOMU(seed))
    FDIR_function_status             =  stx_mask2bits($
      (ulong((2ULL^32) * RANDOMU(seed,1)))[0] ,mask_length=32, /reverse)
    FDIR_temp_status                 = uint((2ULL^16) * RANDOMU(seed))
    FDIR_voltage_status              = uint((2ULL^16) * RANDOMU(seed))
    FDIR_current_status              = uint((2ULL^6) * RANDOMU(seed))
    executed_tc_packets              = uint((2ULL^16) * RANDOMU(seed))
    sent_tc_packets                  = uint((2ULL^16) * RANDOMU(seed))
    failed_tm_generations            = uint((2ULL^16) * RANDOMU(seed))       
  endif

  ;return structure
  return, { $
    type                             : 'stx_asw_hc_regular_mini', $
    time                             : stxtime                    ,$
    sw_running                       : sw_running                 ,$
    instrument_number                : instrument_number          ,$
    instrument_mode                  : instrument_mode            ,$
    HK_DPU_PCB_T                     : HK_DPU_PCB_T               ,$
    HK_DPU_FPGA_T                    : HK_DPU_FPGA_T              ,$
    HK_DPU_3V3_C                     : HK_DPU_3V3_C               ,$
    HK_DPU_2V5_C                     : HK_DPU_2V5_C               ,$
    HK_DPU_1V5_C                     : HK_DPU_1V5_C               ,$
    HK_DPU_SPW_C                     : HK_DPU_SPW_C               ,$
    HK_DPU_SPW0_V                    : HK_DPU_SPW0_V              ,$
    HK_DPU_SPW1_V                    : HK_DPU_SPW1_V              ,$
    sw_version_number                : sw_version_number          ,$
    CPU_load                         : CPU_load                   ,$
    archive_memory_usage             : archive_memory_usage       ,$
    identifier_IDPU                  : identifier_IDPU            ,$
    identifier_active_SpW_link       : identifier_active_SpW_link ,$
    sw_status_1_spare                : sw_status_1_spare          ,$
    commands_rejected                : commands_rejected          ,$
    commands_received                : commands_received          ,$
    HK_DPU_1V5_V                     : HK_DPU_1V5_V               ,$
    HK_REF_2V5_V                     : HK_REF_2V5_V               ,$
    HK_DPU_2V9_V                     : HK_DPU_2V9_V               ,$
    HK_PSU_TEMP_T                    : HK_PSU_TEMP_T              ,$
    FDIR_function_status             : FDIR_function_status       ,$
    FDIR_temp_status                 : FDIR_temp_status           ,$
    FDIR_voltage_status              : FDIR_voltage_status        ,$
    spare                            : spare                      ,$
    FDIR_current_status              : FDIR_current_status        ,$
    executed_tc_packets              : executed_tc_packets        ,$
    sent_tc_packets                  : sent_tc_packets            ,$
    failed_tm_generations            : failed_tm_generations      $
  }

end
