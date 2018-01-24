; obj = obj_new('xml_tlm_2_text')
;
; Note that this object does NOT handle file opening/closing - this is to
; make sure you can pass e.g. the STDOUT/STDERR LUNs, or to concatenate the
; results of two separate source files. Plus, it simplifies the code.
;
; openw, output_lun, output_file_name, /get_lun
;
; obj->process, input_file1, output_lun [,first_obt_out] [,num_packets_out=var]
;
; obj->process, input_file2, output_lun  ; Appends results
;
; free_lun,output_lun  ;; Closes & frees
;
FUNCTION xml_tlm_2_text:: init
  
  ; Init parent class:
  ;
  retval = self->simple_xml:: init()
  
  ; Report/crash if any errors:
  ;
  IF retval EQ 0 THEN message, "IDLffXMLSAX::init returned "+trim(retval)
  
  ; Initialisations of some values:
  ;
  SCOS_HEADER_SIZE = 76
  self.chars_to_trim = 2 * SCOS_HEADER_SIZE
  
  OBT_START_POSITION = 10 ;; I.e. SKIP 10 bytes
  OBT_LENGTH = 48/8       ;; 48 bits
  
  self.chars_to_sort = 2*[OBT_START_POSITION, OBT_LENGTH ]
  
  ; All OK:
  ;
  return,retval
END


PRO xml_tlm_2_text::cleanup
  message,"Cleaning up",/info
  message,"NOTE: I should not be destroyed & recreated all te time!",/info
  
  ; If output is to file, remind about close & free LUN:
  ;
  IF self.lun NE -1 THEN BEGIN
     message,"Remember to close and free LUN "+trim(self.lun),/info
  END
  
  self->simple_xml::cleanup
END



; If output_lun is not present, output goes to STDIO (LUN = -1)
;
PRO xml_tlm_2_text:: process, input_xml_file, output_lun, first_obt_out, $
                     num_packets_out=num_packets_out
  
  lun = ( STDOUT =  -1 )  
  
  IF n_elements(output_lun) GT 0 THEN lun = output_lun
  
  
  self.lun = lun
  
  ; Do the job - note we don't close the file!!
  ;
  message,"Calling ParseFile on "+input_xml_file,/info
  
  ; ParseFile changes first_obt and packet_counter
  ;
  self.packet_counter = 0
  self.first_obt = 'zzzzzzzz'
  
  self->ParseFile,input_xml_file  
  
  ; Send out-parameter values:
  ;
  first_obt_out   = self.first_obt
  num_packets_out = self.packet_counter
END



; Fatal error - hopefully, we won't get here! But if we do... check system
; variable for error status
;
PRO xml_tlm_2_text:: FatalError,systemid,linenumber,columnnumber,message
  print
  print,"SystemId:     "+systemid
  print,"Linenumber:   "+trim(linenumber)
  print,"Columnnumber: "+trim(columnnumber)
  print,"Message:      "+message
  print
  message,"Fatal error?"
END


;; HandleLeafElementData is called whenever the data inside a leaf element are
;; ready to be processed, upon reaching the end of the element - with the
;; complete data inside the leaf element
;;
;;
PRO xml_tlm_2_text:: HandleLeafElementData,data,elementName,elementPath
  
  IF elementName NE 'Packet' THEN BEGIN
     message,elementName+ " => '" +data+"'",/info
     return
  END
  
  self.packet_counter += 1
  
  ;
  ; For debugging, only a few lines:
  ;
  ; IF self.packet_counter GT 20 THEN stop,"Enough lines done"
  ;
  
  ; First chop off SCOS header:
  ;
  data = strmid(data,self.chars_to_trim)
  
  ;; Now, highlight OBT:
  
  obt_offset = self.chars_to_sort[0]
  obt_length = self.chars_to_sort[1]
  
  prefix  = strmid(data,0,obt_offset)
  obt     = strmid(data,obt_offset,obt_length)
  postfix = strmid(data,obt_offset+obt_length)
  
  ;; data = prefix+" * "+obt+" * "+postfix
  data = obt + " " + data
  
  IF obt LT self.first_obt THEN self.first_obt = obt
  printf,self.lun,data
  
END 


; 
;
PRO xml_tlm_2_text:: EndDocument
  message,"Packets parsed: "+trim(self.packet_counter),/info
END   
  

; Return current number of packets in current/most recently parsed file.
;
FUNCTION xml_tlm_2_text:: packet_counter
  return, self.packet_counter
END 


PRO xml_tlm_2_text__define
  patcher = {xml_tlm_2_text, inherits simple_xml, $
             chars_to_trim:76*2,                  $; SCOS header to trim
             chars_to_sort:[0,-1],                $; OBT pos. after trimming
             packet_counter:0LL,                  $; Debugging: limit n_lines
             first_obt:'',                        $; The lowest OBT in the file
             lun:'' $
            }
END
