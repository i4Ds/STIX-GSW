pro stx_csv_export_hk_sid2, hk=hk

  openw, lun, 'c:\temp\hk_sid2_idl.txt', /get_lun
  printf, lun, '0:CoarseTime 1:SW_running 2:Instrument_No 3:Mode 4:DPU_PCB_T 5:DPU_FPGA_T 6:DPU_3V3_C 7:DPU_2V5_C 8:DPU_1V5_C 9:DPU_SPW_C 10:DPU_SPW0_V 11:DPU_SPW1_V 12:ASP_REF_2V5A_V 13:ASP_REF_2V5B_V 14:ASP_TIM01_T 15:ASP_TIM02_T 16:ASP_TIM03_T 17:ASP_TIM04_T 18:ASP_TIM05_T 19:ASP_TIM06_T 20:ASP_TIM07_T 21:ASP_TIM08_T 22:ASP_VSENSA_V 23:ASP_VSENSB_V 24:ATT_V 25:ATT_T 26:HV_01_16_V 27:HV_17_32_V 28:DET_Q1_T 29:DET_Q2_T 30:DET_Q3_T 31:DET_Q4_T 32:DPU_1V5_V 33:DPU_2V5_V 34:DPU_2V9_V 35:PSU_TEMP_T 36:Version 37:CPU_Load 38:Auto_ASW_Boot 39:Mem_Load_Enabled 40:Archive_Mem_Usage 41:IDPU_Ident 42:SpW_Ident 43:Watchdog_State 44:First_Task_Overrun 45:Num_Received_Packets 46:Num_Rejected_Packets 47:DetectorStatus 48:Spare 49:Pwr_State_SpW1 50:Pwr_State_SpW0 51:Pwr_State_Q4 52:Pwr_State_Q3 53:Pwr_State_Q2 54:Pwr_State_Q1 55:Pwr_State_AspB 56:Pwr_State_AspA 57:ATT_2_Moving 58:ATT_1_Moving 59:HV_17_32_Enabled 60:HV_01_16_Enabled 61:LV_Enabled 62:HV_17_32_Depol 63:HV_01_16_Depol 64:ATT_AB_Switch 65:ATT_BC_Switch 66:Spare 67:Median_Trigger 68:Max_Trigger 69:HV_Mask 70:Last_Seq_Count 71:Total_ATM_Moves 72:ASP_PHOTOA0_V 73:ASP_PHOTOA1_V 74:ASP_PHOTOB0_V 75:ASP_PHOTOB1_V 76:ATT_SUM_C 77:ATT_C 78:DET_C 79:FDIR_Status'
  
  for i = 0L, n_elements(hk)-1 do begin
    hk_i = hk[i]
    printf, lun, $
    ulong(stx_time2any(hk_i.time))                                     , $
      hk_i.sw_running                                                  , $
      hk_i.instrument_number                                           , $
      hk_i.instrument_mode                                             , $
      hk_i.hk_dpu_pcb_t                                                , $
      hk_i.hk_dpu_fpga_t                                               , $
      hk_i.hk_dpu_3v3_c                                                , $
      hk_i.hk_dpu_2v5_c                                                , $
      hk_i.hk_dpu_1v5_c                                                , $
      hk_i.hk_dpu_spw_c                                                , $
      hk_i.hk_dpu_spw0_v                                               , $
      hk_i.hk_dpu_spw1_v                                               , $
      hk_i.hk_asp_ref_2v5a_v                                           , $
      hk_i.hk_asp_ref_2v5b_v                                           , $
      hk_i.hk_asp_tim01_t                                              , $
      hk_i.hk_asp_tim02_t                                              , $
      hk_i.hk_asp_tim03_t                                              , $
      hk_i.hk_asp_tim04_t                                              , $
      hk_i.hk_asp_tim05_t                                              , $
      hk_i.hk_asp_tim06_t                                              , $
      hk_i.hk_asp_tim07_t                                              , $
      hk_i.hk_asp_tim08_t                                              , $
      hk_i.hk_asp_vsensa_v                                             , $
      hk_i.hk_asp_vsensb_v                                             , $
      hk_i.hk_att_v                                                    , $
      hk_i.att_t                                                       , $
      hk_i.hk_hv_01_16_v                                               , $
      hk_i.hk_hv_17_32_v                                               , $
      hk_i.det_q1_t                                                    , $
      hk_i.det_q2_t                                                    , $
      hk_i.det_q3_t                                                    , $
      hk_i.det_q4_t                                                    , $
      hk_i.hk_dpu_1v5_v                                                , $
      hk_i.hk_ref_2v5_v                                                , $
      hk_i.hk_dpu_2v9_v                                                , $
      hk_i.hk_psu_temp_t                                               , $
      hk_i.sw_version_number                                           , $
      hk_i.cpu_load                                                    , $
      hk_i.autonomous_asw_booting_status                               , $
      hk_i.memory_load_enable_flag                                     , $
      hk_i.archive_memory_usage                                        , $
      hk_i.identifier_idpu                                             , $
      hk_i.identifier_active_spw_link                                  , $
      hk_i.watchdog_state                                              , $
      hk_i.first_overrun_task                                          , $
      hk_i.commands_received                                           , $
      hk_i.commands_rejected                                           , $
      hk_i.detector_status                                             , $
      hk_i.sw_status_4_spare1                                          , $
      hk_i.power_status_spw1                                           , $
      hk_i.power_status_spw2                                           , $
      hk_i.power_status_q4                                             , $
      hk_i.power_status_q3                                             , $
      hk_i.power_status_q2                                             , $
      hk_i.power_status_q1                                             , $
      hk_i.power_aspect_b                                              , $
      hk_i.power_aspect_a                                              , $
      hk_i.attenuator_moving_2                                         , $
      hk_i.attenuator_moving_1                                         , $
      hk_i.power_status_hv_17_32                                       , $
      hk_i.power_status_hv_01_16                                       , $
      hk_i.power_status_lv                                             , $
      hk_i.hv1_depolarization                                          , $
      hk_i.hv2_depolarization                                          , $
      hk_i.attenuator_ab_position_flag                                 , $
      hk_i.attenuator_bc_position_flag                                 , $
      hk_i.sw_status_4_spare2                                          , $
      hk_i.median_value_trigger_accs                                   , $
      hk_i.max_value_trigger_accs                                      , $
      hk_i.hv_regulators_mask                                          , $
      hk_i.sequence_count_last_tc                                      , $
      hk_i.total_attenuator_motions                                    , $
      hk_i.hk_asp_photoa0_v                                            , $
      hk_i.hk_asp_photoa1_v                                            , $
      hk_i.hk_asp_photob0_v                                            , $
      hk_i.hk_asp_photob1_v                                            , $
      hk_i.attenuator_currents                                         , $
      hk_i.hk_att_c                                                    , $
      hk_i.hk_det_c                                                    , $
      hk_i.fdir_function_status                                        , $
      format='(I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10, I10)'
  endfor

  
  ;free_lun, lun

end