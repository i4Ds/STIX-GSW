; Parses/checks SPICE telemetry packet
;
PRO stx_lldp_parse_packet, bitreader, tmtc_writer, monotony_reset=monotony_reset, obt=obt

  check_monotony, reset = monotony_reset

  ; Shorthand: br = bitreader
  ;
  br = bitreader

  version                = br->bits(3) 
  packet_type            = br->bits(1) 
  data_field_header_flag = br->bits(1)
  ;apid                   = br->bits(11)
  pid                    = br->bits(7)
  pid_cat                = br->bits(4)
  segflag                = br->bits(2)
  seqcount               = br->bits(14)
  packet_length          = br->word() + 1
  spare                  = br->bits(1)
  PUSvers                = br->bits(3) 
  spare                  = br->bits(4)
  type                   = br->byte()
  subtype                = br->byte()
  destid                 = br->byte()
  
  ; we only check for pid 93 - category 12 and type 21,6
  if pid ne 93 then return
  if pid_cat ne 12 then return
  if type ne 21 then return
  if subtype ne 6 then return


  ; Formula to convert OBT to TAI derivable from fits_tlm_compare - BUT we're not
  ; supposed to do time conversion in LL processing! The reason being that
  ; we're not supposed to make assumptions about the clock correlation.
  ;
  pktTime = br->bits(48)

  ; we use the SSID for an unique constrain and we only interested in lc and flare_flag
  ssid                  = br->byte()
  if ssid ne 30 AND ssid ne 34 then return
  check_monotony,ssid,ssc=seqcount, reset=reset

  
  
  ; Monotony check
  ;
  check_monotony, ssid, pktTime=pktTime

  ; Pring meaning of segflag, and sequence count
  ;
  CASE segflag OF
    '01'b: print, string(ssid) + " [" + string(seqcount)+"]", format='(A,$)'
    '00'b: print, '.', format='(A,$)'
    '10'b: print, " - done"
    '11'b: print, string(ssid) + " Only one packet - done"
    ELSE:  stop,"What?"
  END

  ; Remove 16 bit fine obt to get Coarse OBT
  ;
  obt = ishft(pktTime, -16)
  
  ;write binary data to the consolidated temeletry file
  br->reset
  tmtc_writer->write, br->blob(br->size()), bits=8, /extract

END
