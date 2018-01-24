function stx_construct_fsw_rate_control, RCR=RCR, BRCR=BRCR, skip_RCR=skip_RCR
   
   rcr_struct = stx_fsw_m_rate_control_regime()
    
   if isa(RCR) then      rcr_struct.RCR = byte(RCR)
   if isa(BRCR) then     rcr_struct.BRCR = byte(BRCR)
   if isa(skip_RCR) then rcr_struct.skip_RCR = byte(skip_RCR)  
    
   return, rcr_struct
end