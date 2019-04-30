function stx_l1_hk_mini_structure

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
    HW_SW_status1:      0UL, $ ; 32 bits
    HW_SW_status2:      0UL, $ ; 32 bits
    HK_DPU_1V5_V:       0U, $ ; 12 bits
    HK_REF_2V5_V:       0U, $ ; 12 bits
    HK_DPU_2V9_V:       0U, $ ; 12 bits
    HK_PSU_TEMP_T:      0U, $ ; 12 bits
    FDIR_status:        0UL, $ ; 32 bits
    FDIR_status_mask_of_HK_temperature: 0U, $ ; 16 bits
    FDIR_status_mask_of_HK_voltage: 0U, $ ; 16 bits
    HK_selftest_status_flag: boolean(0), $ ; 1 bit
    Memory_status_flag: boolean(0), $ ; 1 bit
    FDIR_status_mask_of_HK_current: 0U, $ ; 6 bits
    Number_executed_TC: 0U, $ ; 16 bits
    Number_sent_TM: 0U, $ ; 16 bits
    Number_failed_TM_gen: 0U} ; 16 bits
    
    return, data
    
end

