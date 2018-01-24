; Check that the given number(s) increase (while taking ssc roll-over into
; account).
;
; Note that we accept arbitrarily big jumps!
;
PRO check_monotony, apid, ssc=ssc, pktTime=pktTime, reset=reset
  
  ; Yes, yes, a common block! Just a like static local variables. Alternative:
  ; make a class just for this stupid little thing, and make the customer have
  ; to drag an object pointer around.
  ;
  ; Hashes to keep track of last values of ssc and pktTime per APID:
  ;
  COMMON fits_tlm_compare_packet_details, last_ssc_hash, last_pktTime_hash
  
  ; Return to caller if assertion fails
  ;
  on_error,2
  
  do_reset = keyword_set(reset)
  IF NOT isa(last_ssc_hash,'HASH') OR do_reset THEN BEGIN
     last_ssc_hash = hash()
     last_pktTime_hash = hash()
     IF do_reset THEN message, /info, "Reset"
     IF do_reset THEN return
  END
  
  IF isa(/number, ssc) THEN BEGIN 
     
     ; Compare with previous if it exists, deal with wrap-around
     ;
     IF last_ssc_hash.haskey(apid) THEN BEGIN
        
        ; We account (in a narrow sense) for rollower by accepting ssc=0 or
        ; higher after a max value. And
        ;
        IF last_ssc_hash[apid] EQ 2^14-1 THEN last_ssc_hash[apid] = -1
        
        ; Must... make... ssc... signed! Otherwise, the comparison will be
        ; performed unsigned!
        ; 
        ssc = fix(ssc)
        
        assert, ssc GT last_ssc_hash[apid]
     END
     
     ; Always store current
     ;
     last_ssc_hash[apid] = ssc
     
  END
  
  IF isa(pktTime,/number) THEN BEGIN 
     
     ; Compare w/previous if exists
     ; 
     IF last_pktTime_hash.haskey(apid) THEN BEGIN
        assert, pktTime GT last_pktTime_hash[apid]
     END 
     
     ; Always store current
     ;
     last_pktTime_hash[apid] = pktTime
     
  END
  
END
