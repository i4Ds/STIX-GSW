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
;     12-Jun-2017 - Laszlo I. Etesi (FHNW), updated with new TMTC HK spec
;
;-
function stx_asw_hc_regular_maxi, random=random
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
  HK_ASP_REF_2V5A_V                = uint(0)
  HK_ASP_REF_2V5B_V                = uint(0)
  HK_ASP_TIM01_T                   = uint(0)
  HK_ASP_TIM02_T                   = uint(0)
  HK_ASP_TIM03_T                   = uint(0)
  HK_ASP_TIM04_T                   = uint(0)
  HK_ASP_TIM05_T                   = uint(0)
  HK_ASP_TIM06_T                   = uint(0)
  HK_ASP_TIM07_T                   = uint(0)
  HK_ASP_TIM08_T                   = uint(0)
  HK_ASP_VSENSA_V                  = uint(0)
  HK_ASP_VSENSB_V                  = uint(0)
  HK_ATT_V                         = uint(0)
  ATT_T                            = uint(0)
  HK_HV_01_16_V                    = uint(0)
  HK_HV_17_32_V                    = uint(0)
  DET_Q1_T                         = uint(0)
  DET_Q2_T                         = uint(0)
  DET_Q3_T                         = uint(0)
  DET_Q4_T                         = uint(0)
  HK_DPU_1V5_V                     = uint(0)
  HK_REF_2V5_V                     = uint(0)
  HK_DPU_2V9_V                     = uint(0)
  HK_PSU_TEMP_T                    = uint(0)
  sw_version_number                = uint(0)
  CPU_load                         = byte(0)
  autonomous_asw_booting_status    = byte(0)
  memory_load_enable_flag          = byte(0)
  archive_memory_usage             = uint(0)
  identifier_IDPU                  = byte(0)
  identifier_active_SpW_link       = byte(0)
  watchdog_state                   = byte(0)
  first_overrun_task               = byte(0)
  commands_received                = uint(0)
  commands_rejected                = uint(0)
  detector_status                  = ulong(0)
  sw_status_4_spare1               = byte(0)
  power_status_spw1                = byte(0)
  power_status_spw2                = byte(0)
  power_status_q4                  = byte(0)
  power_status_q3                  = byte(0)
  power_status_q2                  = byte(0)
  power_status_q1                  = byte(0)
  power_aspect_b                   = byte(0)
  power_aspect_a                   = byte(0)
  attenuator_moving_2              = byte(0)
  attenuator_moving_1              = byte(0)
  power_status_hv_17_32            = byte(0)
  power_status_hv_01_16            = byte(0)
  power_status_lv                  = byte(0)
  HV1_depolarization               = byte(0)
  HV2_depolarization               = byte(0)
  attenuator_AB_position_flag      = byte(0)
  attenuator_BC_position_flag      = byte(0)
  sw_status_4_spare2               = uint(0)
  median_value_trigger_accs        = ulong(0)
  max_value_trigger_accs           = ulong(0)
  HV_regulators_mask               = byte(0)
  sequence_count_last_TC           = uint(0)
  total_attenuator_motions         = uint(0)
  HK_ASP_PHOTOA0_V                 = uint(0)
  HK_ASP_PHOTOA1_V                 = uint(0)
  HK_ASP_PHOTOB0_V                 = uint(0)
  HK_ASP_PHOTOB1_V                 = uint(0)
  Attenuator_currents              = uint(0)
  HK_ATT_C                         = uint(0)
  HK_DET_C                         = uint(0)
  FDIR_function_status             = ulong(0)

  ;random numbers
  if random then begin
    stxtime                     = stx_time_add(stx_time(),seconds=uint((2^14)*RANDOMU(Seed)))
    sw_running                  = uint(2 * RANDOMU(seed))
    instrument_mode             = uint(16 * RANDOMU(seed))
    HK_DPU_PCB_T                = uint(4096 * RANDOMU(seed))
    HK_DPU_FPGA_T               = uint(4096 * RANDOMU(seed))
    HK_DPU_3V3_C                = uint(4096 * RANDOMU(seed))
    HK_DPU_2V5_C                = uint(4096 * RANDOMU(seed))
    HK_DPU_1V5_C                = uint(4096 * RANDOMU(seed))
    HK_DPU_SPW_C                = uint(4096 * RANDOMU(seed))
    HK_DPU_SPW0_V               = uint(4096 * RANDOMU(seed))
    HK_DPU_SPW1_V               = uint(4096 * RANDOMU(seed))
    HK_ASP_REF_2V5A_V           = uint(4096 * RANDOMU(seed))
    HK_ASP_REF_2V5B_V           = uint(4096 * RANDOMU(seed))
    HK_ASP_TIM01_T              = uint(4096 * RANDOMU(seed))
    HK_ASP_TIM02_T              = uint(4096 * RANDOMU(seed))
    HK_ASP_TIM03_T              = uint(4096 * RANDOMU(seed))
    HK_ASP_TIM04_T              = uint(4096 * RANDOMU(seed))
    HK_ASP_TIM05_T              = uint(4096 * RANDOMU(seed))
    HK_ASP_TIM06_T              = uint(4096 * RANDOMU(seed))
    HK_ASP_TIM07_T              = uint(4096 * RANDOMU(seed))
    HK_ASP_TIM08_T              = uint(4096 * RANDOMU(seed))
    HK_ASP_VSENSA_V             = uint(4096 * RANDOMU(seed))
    HK_ASP_VSENSB_V             = uint(4096 * RANDOMU(seed))
    HK_ATT_V                    = uint(4096 * RANDOMU(seed))
    ATT_T                       = uint(4096 * RANDOMU(seed))
    HK_HV_01_16_V               = uint(4096 * RANDOMU(seed))
    HK_HV_17_32_V               = uint(4096 * RANDOMU(seed))
    DET_Q1_T                    = uint(4096 * RANDOMU(seed))
    DET_Q2_T                    = uint(4096 * RANDOMU(seed))
    DET_Q3_T                    = uint(4096 * RANDOMU(seed))
    DET_Q4_T                    = uint(4096 * RANDOMU(seed))
    HK_DPU_1V5_V                = uint(4096 * RANDOMU(seed))
    HK_REF_2V5_V                = uint(4096 * RANDOMU(seed))
    HK_DPU_2V9_V                = uint(4096 * RANDOMU(seed))
    HK_PSU_TEMP_T               = uint(4096 * RANDOMU(seed))
    sw_version_number           = uint(256 * RANDOMU(seed))
    CPU_load                    = uint(128 * RANDOMU(seed))
    autonomous_asw_booting_status= uint(2 * RANDOMU(seed))
    memory_load_enable_flag     = uint(2 * RANDOMU(seed))
    archive_memory_usage        = uint(256 * RANDOMU(seed))
    identifier_IDPU             = uint(2 * RANDOMU(seed))
    identifier_active_SpW_link  = uint(2 * RANDOMU(seed))
    watchdog_state              = uint(2 * RANDOMU(seed))
    first_overrun_task          = uint(2 * RANDOMU(seed))
    commands_received           = uint(65536 * RANDOMU(seed))
    commands_rejected           = uint(65536 * RANDOMU(seed))
    detector_status             = ulong(4294967296 * RANDOMU(seed))
    sw_status_4_spare1          = uint(65536 * RANDOMU(seed))
    power_status_spw1           = uint(2 * RANDOMU(seed))
    power_status_spw2           = uint(2 * RANDOMU(seed))
    power_status_q4             = uint(2 * RANDOMU(seed))
    power_status_q3             = uint(2 * RANDOMU(seed))
    power_status_q2             = uint(2 * RANDOMU(seed))
    power_status_q1             = uint(2 * RANDOMU(seed))
    power_aspect_b              = uint(2 * RANDOMU(seed))
    power_aspect_a              = uint(2 * RANDOMU(seed))
    attenuator_moving_2         = uint(2 * RANDOMU(seed))
    attenuator_moving_1         = uint(2 * RANDOMU(seed))
    power_status_hv_17_32       = uint(2 * RANDOMU(seed))
    power_status_hv_01_16       = uint(2 * RANDOMU(seed))
    power_status_lv             = uint(2 * RANDOMU(seed))
    HV1_depolarization          = uint(2 * RANDOMU(seed))
    HV2_depolarization          = uint(2 * RANDOMU(seed))
    attenuator_AB_position_flag = uint(2 * RANDOMU(seed))
    attenuator_BC_position_flag = uint(2 * RANDOMU(seed))
    sw_status_4_spare2          = uint(65536 * RANDOMU(seed))
    median_value_trigger_accs   = ulong(16777216 * RANDOMU(seed))
    max_value_trigger_accs      = ulong(16777216 * RANDOMU(seed))
    HV_regulators_mask          = uint(4 * RANDOMU(seed))
    sequence_count_last_TC      = uint(16384 * RANDOMU(seed))
    total_attenuator_motions    = uint(65536 * RANDOMU(seed))
    HK_ASP_PHOTOA0_V            = uint(65536 * RANDOMU(seed))
    HK_ASP_PHOTOA1_V            = uint(65536 * RANDOMU(seed))
    HK_ASP_PHOTOB0_V            = uint(65536 * RANDOMU(seed))
    HK_ASP_PHOTOB1_V            = uint(65536 * RANDOMU(seed))
    Attenuator_currents         = uint(4096 * RANDOMU(seed))
    HK_ATT_C                    = uint(4096 * RANDOMU(seed))
    HK_DET_C                    = uint(4096 * RANDOMU(seed))
    FDIR_function_status        = ulong(4294967296 * RANDOMU(seed))
  endif

  ;return struct
  return, { $
    type                             : 'stx_asw_hc_regular_maxi', $
    time                             : stxtime                     ,$
    sw_running                       : sw_running                  , $
    instrument_number                : instrument_number           , $
    instrument_mode                  : instrument_mode             , $
    HK_DPU_PCB_T                     : HK_DPU_PCB_T                , $
    HK_DPU_FPGA_T                    : HK_DPU_FPGA_T               , $
    HK_DPU_3V3_C                     : HK_DPU_3V3_C                , $
    HK_DPU_2V5_C                     : HK_DPU_2V5_C                , $
    HK_DPU_1V5_C                     : HK_DPU_1V5_C                , $
    HK_DPU_SPW_C                     : HK_DPU_SPW_C                , $
    HK_DPU_SPW0_V                    : HK_DPU_SPW0_V               , $
    HK_DPU_SPW1_V                    : HK_DPU_SPW1_V               , $
    HK_ASP_REF_2V5A_V                : HK_ASP_REF_2V5A_V           , $
    HK_ASP_REF_2V5B_V                : HK_ASP_REF_2V5B_V           , $
    HK_ASP_TIM01_T                   : HK_ASP_TIM01_T              , $
    HK_ASP_TIM02_T                   : HK_ASP_TIM02_T              , $
    HK_ASP_TIM03_T                   : HK_ASP_TIM03_T              , $
    HK_ASP_TIM04_T                   : HK_ASP_TIM04_T              , $
    HK_ASP_TIM05_T                   : HK_ASP_TIM05_T              , $
    HK_ASP_TIM06_T                   : HK_ASP_TIM06_T              , $
    HK_ASP_TIM07_T                   : HK_ASP_TIM07_T              , $
    HK_ASP_TIM08_T                   : HK_ASP_TIM08_T              , $
    HK_ASP_VSENSA_V                  : HK_ASP_VSENSA_V             , $
    HK_ASP_VSENSB_V                  : HK_ASP_VSENSB_V             , $
    HK_ATT_V                         : HK_ATT_V                    , $
    ATT_T                            : ATT_T                       , $
    HK_HV_01_16_V                    : HK_HV_01_16_V               , $
    HK_HV_17_32_V                    : HK_HV_17_32_V               , $
    DET_Q1_T                         : DET_Q1_T                    , $
    DET_Q2_T                         : DET_Q2_T                    , $
    DET_Q3_T                         : DET_Q3_T                    , $
    DET_Q4_T                         : DET_Q4_T                    , $
    HK_DPU_1V5_V                     : HK_DPU_1V5_V                , $
    HK_REF_2V5_V                     : HK_REF_2V5_V                , $
    HK_DPU_2V9_V                     : HK_DPU_2V9_V                , $
    HK_PSU_TEMP_T                    : HK_PSU_TEMP_T               , $
    sw_version_number                : sw_version_number           , $
    CPU_load                         : CPU_load                    , $
    autonomous_asw_booting_status    : autonomous_asw_booting_status, $
    memory_load_enable_flag          : memory_load_enable_flag     , $
    archive_memory_usage             : archive_memory_usage        , $
    identifier_IDPU                  : identifier_IDPU             , $
    identifier_active_SpW_link       : identifier_active_SpW_link  , $
    watchdog_state                   : watchdog_state              , $
    first_overrun_task               : first_overrun_task          , $
    commands_received                : commands_received           , $
    commands_rejected                : commands_rejected           , $
    detector_status                  : detector_status             , $
    sw_status_4_spare1               : sw_status_4_spare1          , $
    power_status_spw1                : power_status_spw1           , $
    power_status_spw2                : power_status_spw1           , $
    power_status_q4                  : power_status_q4             , $ 
    power_status_q3                  : power_status_q3             , $
    power_status_q2                  : power_status_q2             , $
    power_status_q1                  : power_status_q1             , $
    power_aspect_b                   : power_aspect_b              , $
    power_aspect_a                   : power_aspect_a              , $
    attenuator_moving_2              : attenuator_moving_2         , $
    attenuator_moving_1              : attenuator_moving_1         , $
    power_status_hv_17_32            : power_status_hv_17_32       , $
    power_status_hv_01_16            : power_status_hv_01_16       , $
    power_status_lv                  : power_status_lv             , $
    HV1_depolarization               : HV1_depolarization          , $
    HV2_depolarization               : HV2_depolarization          , $
    attenuator_AB_position_flag      : attenuator_AB_position_flag , $
    attenuator_BC_position_flag      : attenuator_BC_position_flag , $
    sw_status_4_spare2               : sw_status_4_spare2          , $
    median_value_trigger_accs        : median_value_trigger_accs   , $
    max_value_trigger_accs           : max_value_trigger_accs      , $
    HV_regulators_mask               : HV_regulators_mask          , $
    sequence_count_last_TC           : sequence_count_last_TC      , $
    total_attenuator_motions         : total_attenuator_motions    , $
    HK_ASP_PHOTOA0_V                 : HK_ASP_PHOTOA0_V            , $
    HK_ASP_PHOTOA1_V                 : HK_ASP_PHOTOA1_V            , $
    HK_ASP_PHOTOB0_V                 : HK_ASP_PHOTOB0_V            , $
    HK_ASP_PHOTOB1_V                 : HK_ASP_PHOTOB1_V            , $
    Attenuator_currents              : Attenuator_currents         , $
    HK_ATT_C                         : HK_ATT_C                    , $
    HK_DET_C                         : HK_DET_C                    , $
    FDIR_function_status             : FDIR_function_status        $
  }

end
