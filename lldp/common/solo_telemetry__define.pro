; Use:
;
; tlm = solo_telemetry(request_dir, scratch_dir)
;
; start_of_nominal_day = tlm->start_of_nominal_day()
;
; while (1) do begin        ;; Use BREAK to get out
;
;   packet = tlm->packet()  ;; Get packet - returns !NULL on EOF
;
;   if n_elements(packet) eq 0 then BREAK
;
; end
;
; At a later stage, we might add some output keywords to the packet() method,
; in particular it might be useful to have the packet generation time?
;
; How does the pipeline determine the switch-over from one day to the other,
; when it's not supposed to speculate about the clock correlation?
;
; Presumably we must detect the *first* OBT of the "current day" input. This
; requires getting out the first_obt() from the xml_tlm_2_text. That requires
; "capturing on the fly" for each file, and it's up to the *user* of the
; xml_tlm_2_text to know which file is the "current day".
;
;
FUNCTION solo_telemetry:: init, request_dir, scratch_dir, reset=reset
  
  ; Need to keep the xml_tlm_2_text object around (IDL memory leak when
  ; creating/destroying XML objects), even if *we* get destroyed and
  ; recreated. Using a common block to make it never go out of scope solves
  ; that.
  ;
  ; THIS MAKES THE SOLO_TELEMETRY OBJECT NON-REENTRANT
  ;
  ; So to prevent having two of us using the same object at the same
  ; time, we insist that we only keep one copy of "ourselves":
  ;
  COMMON solo_telemetry__static_myself, myself
  
  IF obj_valid(myself) THEN $
     message,"There's an existing solo_telemetry object - delete it first!"
  
  myself = self
  
  ; This will be the sorted & uniquified file:
  ;
  output_file = self->output_file(scratch_dir)
  
  IF keyword_set(reset) THEN file_delete, output_file, /allow_nonexistent
  
  ; WARNING - GOTO!
  ;
  IF file_test(output_file) THEN GOTO,READ_BACK
  
  self.start_of_nominal_day = '0000'
  
  ; Trick learned from Euclid - give the processing object a stream
  ; instead of a file name!
  ;
  ; Unfortunately, this is not possible w.r.t. the input file, due to the
  ; interface of IDL's XML object.
  ;
  ; But using it for the output file is super - it's so easy to append more
  ; and more results to the same file, without specifying how the file is to
  ; be opened, or deleting it first, etc!  And it would be very easy to set
  ; temp_output_lun to STDOUT (LUN = -1) if we like:
  
  temp_output_file = output_file + ".tmp"
  openw, temp_output_lun, temp_output_file, /get_lun  ; Override output
  
  ; Go through "preceding day" first:
  ;
  self->read_request_subpart, temp_output_lun, request_dir + "/preceding"
  
  ; Setting the /nominal_day flag makes sure read_request_subpart stores the
  ; earliest OBT value from this file
  ; 
  self->read_request_subpart, temp_output_lun, request_dir + "", /nominal_day
  
  ; Done reading the input files. If output was to STDOUT (-1), we're done,
  ; since we can't sort & read back from STDOUT
  ; 
  IF temp_output_lun EQ -1 THEN BEGIN
     message,"Can't read packets back from STDOUT (LUN = -1)",/info
     return,1
  END
  
  ; Remember to close & free output file
  ;
  free_lun, temp_output_lun
  
  ; Sort and uniquify the consolidated file, using some linux sort magic:
  
  sort_options =  " -T "+scratch_dir      ; Use this temporary directory
  sort_options += " -u"                   ; Unique lines without pipe to uniq
  sort_options += " -o "+output_file      ; Output to file without redirection
  
  ; Execute it:
  ;
  ;spawn,"sort " + sort_options + " " + temp_output_file
  ; FHNW-fix
  output_file = temp_output_file
  
  ; Prepare for returning packets one by one - open the output file from
  ; previous step & store the lun:
  ;
  
READ_BACK:
  
  openr, lun, output_file, /get_lun
  self.lun = lun
  
  return,1
END


; Shorthand for use in init method (avoid clutter)
;
FUNCTION solo_telemetry:: output_file, scratch_dir
  
  self.consolidated_dir = scratch_dir + "/consolidated_telemetry"
  file_mkdir,self.consolidated_dir
  
  output_file = self.consolidated_dir + "/tlm.hex"
  
  return,output_file
END 


PRO solo_telemetry:: cleanup
  message,"Cleaning up",/info
  file_delete, self.consolidated_dir, /quiet, /verbose, /recursive
END


; Process single file of telemetry from either current day or preceding day
; within the request
;
PRO solo_telemetry:: read_request_subpart, output_lun, request_subpart_dir, $
   nominal_day = nominal_day
  
  ; We must keep this object alive, using a static common block:
  ; 
  COMMON solo_telemetry__static_xml_tlm_2_text,xml_tlm_2_text
  
  IF NOT obj_valid(xml_tlm_2_text) THEN $
     xml_tlm_2_text = obj_new('xml_tlm_2_text')
  
  ; Look for input TLM files in current request subpart ("" or "/preceding")
  ;
  input_dir = request_subpart_dir + "/telemetry"
  file_pattern = "*" ; No info given on TLM file name rules
  
  tlm_file = file_search(input_dir+"/"+file_pattern,count=count)
  
  IF count GT 1 THEN $
     message,"Seems to be more than one telemetry file in "+input_dir
  
  IF count EQ 0 THEN $
     message,"Couldn't find any files in "+input_dir
  
  ; Now do the processing, capturing the first obt as we go:
  ;
  xml_tlm_2_text->process, tlm_file[0], output_lun, first_obt, num_packets_out=npackets
  
  IF keyword_set(nominal_day) THEN self.start_of_nominal_day = first_obt
  
  message,tlm_file[0]+":",/info
  message,"Registered packets: "+trim(npackets),/info
END


; Just return the start of nominal day (first OBT in current-day file)
;
FUNCTION solo_telemetry:: start_of_nominal_day
  return, self.start_of_nominal_day
END

; Return next packet from file as hex (no translation)
;
FUNCTION solo_telemetry:: hex_packet
  
  ; Handle end-of-file - return null result
  ;
  IF eof(self.lun) THEN BEGIN
     free_lun,self.lun
     return,!null
  END
  
  ; Read (sequential) packet from input file as text
  ;
  tx = ''
  readf,self.lun,tx
  
  ; The initial copy of OBT is 48 bits, written in hex, then there's the
  ; separating space - we clip it off.
  ;
  packet = strmid(tx,48/8*2+1)
  
  return,packet
END


; Convert hex string to array of bytes. For internal use by packet() function,
; thus function name starts with two underscores.
;
FUNCTION solo_telemetry:: __hex_to_bytes, hex
  
  ; Convert each char to a byte (ASCII value) after ensuring all digits are
  ; lower case
  ;
  lowercase_hex = strlowcase(hex)
  chars_as_bytes = byte(lowercase_hex)
  
  ascii_nine = (byte('9'))[0] ; Handy constants
  ascii_zero = (byte('0'))[0]
  ascii_a =    (byte('a'))[0]
  
  ; Find indices of '0'..'9' and 'a'-'f'. Using /NULL for simplicity.
  ;
  numeric_ix = where(chars_as_bytes LE ascii_nine, count_numeric, $
                     complement=alpha_ix, ncomplement=count_alpha, /NULL)
 
  chars_as_bytes[numeric_ix] -= ascii_zero
  
  ; FHNW-fix
  if(alpha_ix ne !NULL) then begin
    chars_as_bytes[alpha_ix  ] -= ascii_a
    chars_as_bytes[alpha_ix  ] += 10
  endif
  
  num_chars = n_elements(chars_as_bytes)
  
  ; Note: First dimension is minor, thus a[0,0] and a[1,0] are adjacent in
  ;       memory - like the characters of a single byte. So it's the first
  ;       dimension we must use to "traverse" the two hex digits of byte.
  ;
  chars_as_bytes = reform(chars_as_bytes, 2, num_chars/2)
  
  ; First char is most significant, multiply by 16; Remove degenerate
  ; dimension.
  ;
  tlm_as_bytes = 16b * chars_as_bytes[0, *] + chars_as_bytes[1, *]
  tlm_as_bytes = reform(tlm_as_bytes)
  
  IF (0) THEN BEGIN 
     nbytes = n_elements(tlm_as_bytes)
     format = '('+trim(nbytes)+'z02)'
     
     print, tlm_as_bytes, format=format
  END
  
  return, tlm_as_bytes
END


; Returns hex packet converted to binary form (array of bytes).
;
; If no hex_packet is supplied, a packet is read using ::hex_packet().
;
FUNCTION solo_telemetry:: bin_packet, hex_packet, consolidated=consolidated
  
  IF keyword_set(consolidated) THEN $
     message,"Consolidation of packages not yet supported"
  
  ; If no packet has been supplied, read one:
  ;
  IF n_elements(hex_packet) NE 1 THEN hex_packet = self->hex_packet()
  
  ; self->hex_packet() returns !NULL on EOF, and so shall we:
  ;
  IF n_elements(hex_packet) EQ 0 THEN return, !NULL
  
  bin_packet = self->__hex_to_bytes(hex_packet)
  
  return, bin_packet
END


PRO solo_telemetry__define
  patcher = {solo_telemetry, $
             consolidated_dir : "", $
             start_of_nominal_day : "", $
             lun:0                $ ; Logical unit
            }
END
