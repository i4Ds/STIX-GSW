function stx_fsw_rate_control
    
   rcr = {  $
      type : 'stx_fsw_rate_control', $
      RCR       : 0b, $
      BRCR      : 0b, $
      skip_RCR  : 0b $ 
   }
   return, rcr
end

