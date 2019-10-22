function stx_l1_hk_maxi_structure


  data = {SW_running: boolean(0), $ ; 1 bit
    Instrument_number:  1, $ ;3 bits fixed value 1
    Instrument_mode:    0, $ ;4 bits 
    HK_DPU_PCB_T:       0U, $ ; 12 bits
    HK_DPU_FPGA_T:      0U, $ ; 12 bits
    HK_DPU_3V3_C:       0U, $ ; 12 bits
    HK_DPU_2V5_C:       0U, $ ; 12 bits
    HK_DPU_1V5_C:       0U, $ ; 12 bits
    HK_DPU_SPW_C:       0U, $ ; 12 bits
    HK_DPU_SPW0_V:      0U, $ ; 12 bits
    HK_DPU_SPW1_V:      0U, $ ; 12 bits
    HK_ASP_REF_2V5A_V:  0U, $ ; 12 bits
    HK_ASP_REF_2V5B_V:  0U, $ ; 12 bits
    HK_ASP_TIM01_T:     0U, $ ; 12 bits
    HK_ASP_TIM02_T:     0U, $ ; 12 bits
    HK_ASP_TIM03_T:     0U, $ ; 12 bits
    HK_ASP_TIM04_T:     0U, $ ; 12 bits
    HK_ASP_TIM05_T:     0U, $ ; 12 bits
    HK_ASP_TIM06_T:     0U, $ ; 12 bits
    HK_ASP_VSENSA_V:    0U, $ ; 12 bits
    HK_ASP_VSENSB_V:    0U, $ ; 12 bits
    HK_ATT_V:           0U, $ ; 12 bits
    HK_ATT_T:           0U, $ ; 12 bits
    HK_HV_01_16_V:      0U, $ ; 12 bits
    HK_HV_07_32_V:      0U, $ ; 12 bits
    DET_Q1_T:           0U, $ ; 12 bits
    DET_Q2_T:           0U, $ ; 12 bits
    DET_Q3_T:           0U, $ ; 12 bits
    DET_Q4_T:           0U, $ ; 12 bits
    HK_DPU_1V5_V:       0U, $ ; 12 bits
    HK_REF_2V5_V:       0U, $ ; 12 bits
    HK_DPU_2V9_V:       0U, $ ; 12 bits
    HK_PSU_TEMP_T:      0U, $ ; 12 bits
    HW_SW_status1:      0UL, $ ; 32 bits
    HW_SW_status2:      0UL, $ ; 32 bits
    HW_SW_status3:      0UL, $ ; 32 bits
    HW_SW_status4:      0UL, $ ; 32 bits
    Median_triggers:    0UL, $ ; 24 bits
    Max_triggers:       0UL, $ ; 24 bits
    HV_regulators:      boolean([0,0]), $ ; 2 bits mask
    TC_last_seq_count:  0U, $ ; 14 bits
    Total_atten_moves:   0U, $ ; 16 bits
    HK_ASP_PHOTOA0_V:   0U, $ ; 16 bits 
    HK_ASP_PHOTOA1_V:   0U, $ ; 16 bits 
    HK_ASP_PHOTOB0_V:   0U, $ ; 16 bits 
    HK_ASP_PHOTOB1_V:   0U, $ ; 16 bits 
    Atten_currents:     0U, $ ; 16 bits 
    HK_ATT_C:           0U, $ ; 12 bits 
    HK_DET_C:           0U, $ ; 12 bits 
    FDIR_status:        0UL} ; 32 bits

    return, data

end
