; bits = obj_new('bitreader')
;
; bits->set_data, byte_array
;
; word = bits->word()
;
; byte = bits->byte()
;
; bits = bits->bits(7)
;
; bits->advance_cursor,[ bits=N | bytes=N | words=N ]
;

; Init - allocate ptr to store byte array
;
FUNCTION bitreader:: init
  self.data = ptr_new(/allocate)
  return, 1
END


; Cleanup - free pointer
;
PRO bitreader::cleanup
  
  ; Error if it's not valid, ok b/c it should never happen
  ; 
  ptr_free,self.data
  
END


; Set new blob of data - a byte array, and reset cursor
;
PRO bitreader:: set_data,data
  
  ; Data should be at least one byte!
  ;
  type = size(data,/tname)
  IF type NE 'BYTE' THEN message,"Data must be BYTEs"
  
  self.cursor = 0
  *self.data = data  
  
END 


; RESET cursor
;
PRO bitreader:: reset
  self.cursor = 0
END 


; Read and return N bits ( N <= 64 )
; 
FUNCTION bitreader:: bits, numbits_in
  
  IF numbits_in EQ 0 THEN message, "Can't read zero bits!"
  
  ; Preventing issues with pass-by-reference when recursing
  ;
  numbits = numbits_in
  
  ; Check for EOF
  ;
  have_bits = 8 * n_elements(*self.data)
  have_bits_left = have_bits - self.cursor
  IF numbits GT have_bits_left THEN $
     message, "Sorry, only have "+trim(have_bits_left)+" bits left"

  ; How many bits have already been "used" of the current byte?
  ;
  bits_used = self.cursor MOD 8
  
  ; And how many are left?
  ;
  bits_left_in_byte = 8 - bits_used
  
  ; Number of bits left to fetch after using those available in current byte
  ;
  bits_left_to_fetch = numbits - bits_left_in_byte
  
  ; If we have more bits to fetch after using up those in the current byte,
  ; we'll deal with that later. But first limit the "local" numbits so we keep
  ; within the current byte.
  ;
  IF bits_left_to_fetch GT 0 THEN numbits = bits_left_in_byte
  
  ; Ok, so we're left with intra-byte extraction here. First get hold of that
  ; byte:
  ;
  byte_offset = self.cursor / 8
  value = (*self.data)[byte_offset]
  
  ; To avoid issues when using trim() or string() on values, we always return
  ; at least ints
  value = uint(value)
  
  ; So, what to do first. Blank out the already-used bits?
  ;
  full = 'ff'xb
  mask = ishft(full, -bits_used)
  new_value = value AND mask
  
  ; Now, shift value down to bump out the remaining bits:
  ;
  remaining_bits = bits_left_in_byte - numbits
  
  final_value = ishft(new_value, -remaining_bits)
  
  ; Note that we must advance the cursor before dealing with any
  ; bits_left_to_fetch in a recursive call.
  ; 
  self.cursor += numbits
  
  IF bits_left_to_fetch GT 0 THEN BEGIN
     
     ; Convert to appropriate size, based on original numbits request.
     ;
     ; We already have a uint value, so there's no chance we need to do this
     ; unless we have bits_left_to_fetch.
     ; 
     IF numbits_in GT 16 THEN final_value = ulong(final_value)
     IF numbits_in GT 32 THEN final_value = ulong64(final_value)
     IF numbits_in GT 64 THEN message,"Can't return more than 48 bits at a time"
     
     ; What we have are the most significant bits - make room for the lesser ones:
     ;
     final_value = ishft(final_value, bits_left_to_fetch)
     
     remaining_value = self->bits(bits_left_to_fetch)
     
     final_value OR= remaining_value
     
  END
  
  return, final_value
END


; Return blob (byte array) with nbytes elements
;
FUNCTION bitreader:: blob, nbytes
  
  ; Alignment check
  ;
  IF self.cursor MOD 8 NE 0 THEN message, "Cursor is not byte-aligned!"
  
  byte_offset = self.cursor / 8
  
  ; Check if there are enough remaining bytes:
  ; 
  bytes_remaining = n_elements(*self.data) - byte_offset
  IF bytes_remaining LT nbytes THEN $
     message, "Only "+trim(bytes_remaining)+" bytes left"
  
  ; Extract data and advance cursor
  ;
  blob = (*self.data)[byte_offset : byte_offset + nbytes - 1]
  self.cursor += 8 * nbytes
  
  return, blob
END


; Return single byte from cursor position
; 
FUNCTION bitreader:: byte
  
  ; Check alignment
  ;
  IF self.cursor MOD 8 NE 0 THEN message, "Cursor is not byte-aligned!"
  
  byte_offset = self.cursor / 8
  
  IF byte_offset GE n_elements(*self.data) THEN $
     message, "Sorry, no more bytes left"
  
  ; Extract byte & advance pointer
  ; 
  byte = (*self.data)[byte_offset]
  self.cursor += 8
  
  return, byte
END


FUNCTION bitreader:: word
  
  ; Check alignment
  IF self.cursor MOD 16 NE 0 THEN message, "Cursor is not word-aligned!"
  
  byte_offset = self.cursor / 8
  
  IF byte_offset GE n_elements(*self.data)-1 THEN $
     message, "Sorry, don't have a whole word left"
  
  ; We use the 2nd argument (OFFSET) to... offset within the byte array (no
  ; need to extract bytes first)
  ;
  word = fix(*self.data, byte_offset)
  
  self.cursor += 16
  
  ; We don't make assumptions about the endianness
  ; 
  swap_endian_inplace, word, /swap_if_little_endian
  
  return, word
END 


; Advance cursor by a number of bits, bytes, or words. Throws errors on
; alignment anomalies for bytes/words (an override mechanism, both global and
; on a per-case basis, could/should be created)
;
PRO bitreader:: advance_cursor, bytes=bytes, bits=bits, words=words
  
  ; First, check that only one input is given
  ;
  keywords = n_elements(bits)   GT  0  + $
             n_elements(bytes)  GT  0  + $
             n_elements(words)  GT  0
  
  IF keywords GT 1 THEN message, "Only one of BITS, BYTES, and WORDS can be set!"
  IF keywords LT 1 THEN message, "One of BITS, BYTES, and WORDS must be set!"
  
  
  ; Check for scalarity
  ;
  num_elems = n_elements(bits) + n_elements(bytes) + n_elements(words)
  IF num_elems GT 1 THEN message, "Input must be scalar"
  
  
  ; BITS:
  ; 
  IF n_elements(bits) GT 0 THEN BEGIN
     self.cursor += bits
     return
  END
  
  
  ; BYTES:
  ; 
  IF n_elements(bytes) GT 0 THEN BEGIN
     IF self.cursor MOD 8 NE 0 THEN message, "Cursor is not byte-aligned!"
     self.cursor += 8 * bytes
     return
  END
  
  IF n_elements(words) GT 0 THEN BEGIN
     IF self.cursor MOD 16 NE 0 THEN message, "Cursor is not word-aligned!"
     self.cursor += 16 * words
     return
  END
  
  message, "I should not end up here!"
END



FUNCTION bitreader:: size
  return, n_elements(*self.data)
END


; Report number of *whole* bits/bytes/words remaining to be read
;
FUNCTION bitreader::remaining, bits = bits, words = words, bytes = bytes
  
  IF keyword_set(bits) THEN BEGIN
     
     bits_total = 8 * n_elements(*self.data)
     bits_remaining = bits_total - self.cursor
     
     return, bits_remaining
  END
     
  IF keyword_set(bytes) THEN BEGIN
     
     ; bytes_started=0 if cursor=0
     ; bytes_started=1 if cursor=1
     ;
     bytes_started = ceil(self.cursor / 8.0)
     
     bytes_total   = n_elements(*self.data)
     bytes_remaining = bytes_total - bytes_started
     
     return, bytes_remaining
  END
     
  IF keyword_set(words) THEN BEGIN
     
     ; words_started=0 if cursor=0
     ; words_started=1 if cursor=1
     ;
     words_started = ceil(self.cursor/16.0)
     
     words_total   = n_elements(*self.data) / 2
     words_remaining = words_total - words_started
          
     return, words_remaining
  END
  
  message, "Must set one of /bits, /bytes, or /words"
END


FUNCTION bitreader:: eof
  return, self.cursor EQ 8 * n_elements(*self.data)  
END


PRO bitreader__define
  patcher = {bitreader,         $
             data : ptr_new(),  $ Pointer to byte array (binary packet)
             cursor : 0LL       $ Cursor/Index/Pointer to next *BIT*
            }
END



PRO bitreader:: unit_test, bytes_of_data
  ;
  ; Generate random array of bytes
  ; Convert to binary string
  ; 
  ; Read bits using random lengths, accumulate new string
  ;
  ; Compare!
  
  ; Generate & set data *if* bytes_of_data is given, otherwise just reset &
  ; use existing data (there had better be some...)
  ; 
  IF n_elements(bytes_of_data) EQ 1 THEN BEGIN
     data = byte(round(255*randomu(seed, bytes_of_data)))
     self->set_data, data
  END ELSE BEGIN
     bytes_of_data = n_elements(*self.data)
  END 
  
  
  ; Generate bit text in a "safe way", byte after byte
  ;
  tx_true = ''
  FOR i=0, bytes_of_data-1 DO BEGIN
     t = string((*self.data)[i], format='(b08)')
     tx_true += t
  END
  
  self->reset
  
  ; Now, go through a random number of bits at a time, constructing
  ; (hopefully) the same string
  ; 
  bits_to_go = 8L * bytes_of_data
  tx_bits = ''
  WHILE bits_to_go GT 0 DO BEGIN
     
     ; Random number of bits up to 64 - but not zero, and not more than we've
     ; got left
     ;
     bits = round(64 * randomu(seed)) > 1
     bits <= bits_to_go
     
     value = self->bits(bits)
     
     ; Convert to string in the right format/length
     ; 
     format = '(b0'+trim(bits)+')'
     t = string(value, format=format)

     ; Add to result
     tx_bits += t
     
     bits_to_go -= bits
  END
  
  IF tx_bits EQ tx_true THEN print, "Bit-reading success!" $
  ELSE BEGIN 
     print, tx_true
     print, tx_bits
     message, "Bit-reading FAILURE!"
  END 
  
  self->reset
  
  tx_bytes = ''
  FOR i=0, bytes_of_data-1 DO BEGIN
     
     ; Get one byte, convert to text
     ;
     value = self->byte()
     t = string(value, '(b08)')
     
     tx_bytes += t
  END
  
  IF tx_bytes EQ tx_true THEN print, "Byte-reading success!" $
  ELSE BEGIN 
     print, tx_true
     print, tx_bits
     message, "Byte-reading FAILURE!"
  END 
  
  self->reset
  
  IF bytes_of_data MOD 2 NE 0 THEN BEGIN
     print, "Can't test word reading - odd number of bytes"
     return
  END 
  
  words_of_data = bytes_of_data / 2
  tx_words = ''
  FOR i=0, words_of_data-1 DO BEGIN
     
     ; Get one word, convert to text
     ;
     value = self->word()
     t = string(value, '(b016)')
     
     tx_words += t
  END
  
  IF tx_words EQ tx_true THEN print, "Word-reading success!" $
  ELSE BEGIN 
     print, tx_true
     print, tx_words
     message, "Word-reading FAILURE!"
  END 
  
  self->reset
  
  print, "Unit test succeeded"
  print
END
