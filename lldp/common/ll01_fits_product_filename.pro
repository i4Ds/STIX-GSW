; From LLFITS ICD:
;
; solo_LL01_phi-fdt-magn_0000086399_V201810120000C.fits
; solo_LL02_stix-lc_0000086399-0000172797_V201810120000I.fits
;
; /incomplete means version-time ends in "I", otherwise "C"
; 
FUNCTION LL01_fits_product_filename, descr, obt_beg, create_time, $
                                     free_field, incomplete = incomplete
  
  ; Pad OBT_BEG to 10 digits:
  ; 
  obt_beg_10 = trim(obt_beg, '(I010)')
  
  ; Create-time may be given (anytim) or not
  ; 
  tt = time_tools()
  version_create_time = tt.time_yyyymmddhhmmss(create_time)
  
  complete = keyword_set(incomplete) ? "I" : "C"
  
  name = "solo_LL01_" $
         +descr+  "_"+ $
         obt_beg_10+"_" $
         +"V"+version_create_time+complete+"_"+ $
         free_field+".fits"
  
  return, name
END
