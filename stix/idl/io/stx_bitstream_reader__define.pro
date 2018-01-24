;+
; :description:
;    The stx_bitstream_reader object performs bit vise reading from disc or memory
;
; :categories:
;    simulation, reader, telemetry
;
; :keywords:
;    stream : in, type="byte array"
;             The data stream to read from memory
;    
;    buffersize : in, type="number", default='file size'
;             The initial size of the internal buffer in the filemode
;    
;    filename : in, type="string"
;             name and path of the file for reading the data from
;             
; :returns:
;    A bit reader object is returned that contains the byte buffer (stream from filsesystem or memory) and
;    according position pointers
;    
; :history:
;    11-Apr-2013 - Nicky Hochmuth (FHNW), initial release
;    10-Jun-2015 - Laszlo I. Etesi (FHNW), bugfix: cut-off one byte too many when reading in files
;    22-Jul-2015 - Laszlo I. Etesi (FHNW), replaced close with free_lun
;    04-Aug-2015 - Laszlo I. Etesi (FHNW), added big endian reading
;    26-Aug-2015 - Laszlo I. Etesi (FHNW), bugfix: default buffersize is equal to file size
;-
function stx_bitstream_reader::init, stream=stream, filename=filename, buffersize=buffersize
  if keyword_set(filename) then begin    
    openr, lun, filename, /get_lun
    
    self.lun = lun
    
    self.filesize = (FILE_INFO(filename)).size
    
    default, buffersize, self.filesize
    
    buffersize = max([512,buffersize])
    
    POINT_LUN, -self.lun, pos
    ; read the entire or in chunks filedata into the buffer

    self.buffer=PTR_NEW(read_binary(self.lun, data_type=1, data_dims = (pos + buffersize) lt self.filesize ? buffersize : self.filesize - pos))
    
  endif else begin
    if ~ppl_typeof(stream,COMPARETO='byte_array') then message, 'stream is not a byte array'
    self.buffer = PTR_NEW(stream)
  endelse
  
  self.buffersize = n_elements(*(self.buffer)) 
  self.dvalid = [[1, 2, 12, 3, 13, 15], [8, 16, 16, 32, 32, 64]]
  self.start_positions= LIST()
  return, 1
end

pro stx_bitstream_reader::shiftfilebuffer
  compile_opt idl2, hidden
  
  if eof(self.lun) then return
   
  rest = (*self.buffer)[self.byteptr:*]
  
  free_pointer, self.buffer
  
  POINT_LUN, -self.lun, pos
   
  self.buffer=PTR_NEW([rest, read_binary(self.lun, data_type=1, data_dims = (pos + self.buffersize) lt self.filesize ? self.buffersize : self.filesize - pos -1)])
  
  self.byteptr = 0
  
  self.buffersize = n_elements(*(self.buffer))
  
end

function stx_bitstream_reader::have_data
  return, self.byteptr lt self.buffersize-1
end
;+
; :description:
;    This routine prints out the current buffer and pointers
;-
pro stx_bitstream_reader::debuginfo
  message, '[DEBUG] TMR pointers: ' + arr2str(trim(string([self.byteptr, self.bitptr]))), /continue, /informational
  last_data_byte = max([max(where(*(self.buffer) ne 0)), self.byteptr])
  if(last_data_byte ne -1) then message, '[DEBUG] TMR buffer: [' + arr2str(trim(string(uint((*self.buffer)[0:last_data_byte[0]])))) + '], ' + trim(string(self.buffersize-last_data_byte[0]-1)) + ' bytes unused and hidden.', /continue, /informational
end

;+
; :description:
;   reads in data in 1 byte big endian formatted
;-
function stx_bitstream_reader::read_8bits_big_endian, debug=debug, silent=silent
  rd = self->read(1, bits=8, debug=debug, silent=silent)
  return, fix(swap_endian(rd, /swap_if_little_endian), type=1)
end

;+
; :description:
;   reads in data in 2 bytes big endian formatted
;-
function stx_bitstream_reader::read_16bits_big_endian, debug=debug, silent=silent
  rd = self->read(12, bits=16, debug=debug, silent=silent)
  return, fix(swap_endian(rd, /swap_if_little_endian), type=12)
end

;+
; :description:
;   reads in data in 3 bytes big endian formatted
;-
function stx_bitstream_reader::read_24bits_big_endian, debug=debug, silent=silent
  rd = self->read(13, bits=24, debug=debug, silent=silent)
  rd_shifted = ishft(rd, 8)
  return, fix(swap_endian(rd_shifted, /swap_if_little_endian), type=13)
end

;+
; :description:
;   reads in data in 4 bytes big endian formatted
;-
function stx_bitstream_reader::read_32bits_big_endian, debug=debug, silent=silent
  rd = self->read(13, bits=32, debug=debug, silent=silent)
  return, fix(swap_endian(rd, /swap_if_little_endian), type=13)
end

;+
; :description:
;    This routine reads data from the buffer.
;    The data bits are read from "left to right", meaning that
;    the byte array (stream) is scanned from msb to lsb.
; 
; :params:
;    dtype : in, required, type="type int"
;             The type number to read as the next data
;             "byte, int, uint, long, ulong"
;
; :keywords:
;    bits : in, optional, type="int", default="bit size of type"
;           This specifies the number of bits (with msb to lsb from
;           left to right) to be read from the telemetry buffer
;           
;    debug : in, optional, type="boolean", default="0"
;            If set to 0, no debug information is printed, otherwise
;            the telemetry struct's status is printed to the console
;            
;    silent : in, optional, type="boolean", default="0"
;             If set to 0, warning messages (informational) are printed
;             to the console, otherwise they are suppressed.
;             
;    peek : in, otpinal, type='boolean', default='0'
;      allows reading data without changing the internal data pointers
;             
; :examples:
;    data = tmr->read(1,tmr=tmr) ; reads a byte from the current position  
;    
; :history:
;    11-Apr-2013 - Nicky Hochmuth (FHNW), initial release
;    02-Jun-2015 - Laszlo I. Etesi (FHNW), added peek keyword
;-
function stx_bitstream_reader::read, dtype, bits=bits, debug=debug, silent=silent, peek=peek
  ; set default values
  default, debug, 0
  default, silent, ~debug
  default, peek, 0
  
  ; check if data type is a valid input type (i.e. NON-floating point type)
  
  
  if self.lun gt 90 && self.byteptr + 10 gt self.buffersize then self->shiftfilebuffer 
  
  ; little tweak to (hopefully) speedup the reading process
  if bits eq 8 and self.bitptr eq 0 and self.byteptr lt self.buffersize then begin
    if(~peek) then begin
      self.byteptr += 1
      return, (*self.buffer)[self.byteptr-1]
    endif
    return, (*self.buffer)[self.byteptr]
  endif
  
  ; set before reading pointer (save tmr pointers)
  before_ptr = [self.byteptr, self.bitptr]
  
  ; check if bits is present and set default values if necessary
  if(~isvalid(bits)) then begin
    
    dpos = where(dtype eq self.dvalid[*,0])
    if(dpos eq -1) then begin
      message, '[ERROR] Invalid data type for reading. Must be one of the following: BYTE, INT, UINT, LONG, ULONG. Exiting...', /continue, /informational
      return, -1
    endif
    
    if(~silent) then message, '[WARN] No number of bits defines, reading default data size.', /continue, /informational
    bits = self.dvalid[1,dpos]
  endif
  
  ; make a copy of the number of bits
  resbits = fix(bits)
  
  corse_data = ulong64(self.byteptr lt self.buffersize ? (*self.buffer)[self.byteptr] : 0)
  
  bytes_read = 1
  while resbits gt 0 do begin
    corse_data = ishft(corse_data, 8)
    corse_data += (self.byteptr+bytes_read) lt self.buffersize ? (*self.buffer)[self.byteptr+bytes_read] : 0
    bytes_read ++
    resbits-=8
  end
    
  shifted_data = ishft(corse_data, (64-(bytes_read*8))+self.bitptr)
  shifted_data = ishft(shifted_data, -64 + bits)
  
  skp_bytes = long((self.bitptr+bits)/8)
  skp_bits = (self.bitptr+bits) mod 8
  
  if(~peek) then begin
    self.byteptr += skp_bytes
    self.bitptr = skp_bits
    
    ; set after byte and bit pointer
    after_ptr = [self.byteptr, self.bitptr]
  endif else after_ptr = before_ptr
  
  ; print some debug information if requested
  if(debug) then begin
    self->debuginfo
    message, '[DEBUG] Pointer before: ' + arr2str(trim(string(before_ptr))), /continue, /informational
    message, '[DEBUG] Pointer after: ' + arr2str(trim(string(after_ptr))), /continue, /informational
    message, '[DEBUG] Bits read: ' + trim(bits), /continue, /informational
    message, '[DEBUG] Data read: ' + trim(shifted_data), /continue, /informational
    message, '[DEBUG] Data returned: ' + trim(fix(shifted_data, type=dtype)), /continue, /informational
  endif
  
  return, fix(shifted_data, type=dtype)
end

function stx_bitstream_reader::getPosition
  return, [self.byteptr, self.bitptr]
end


function stx_bitstream_reader::getbitposition
  return, self.byteptr * 8L + self.bitptr
end


;+
; :description:
;    Cleanup this object
;-
pro stx_bitstream_reader::cleanup
   if(self.lun gt 0) then begin
    if(self.lun lt 100) then close, self.lun else free_lun, self.lun
   endif
   free_pointer, self.buffer
end

pro stx_bitstream_reader__define
  compile_opt idl2, hidden
    
  ; create stx_telemetry_reader structure that contains all information
  ; for the tm data reading process
  void = { stx_bitstream_reader, $
          buffer : PTR_NEW(), $        ; store the actual data buffer
          byteptr : 0L, $              ; store a byte stream position pointer, goes from 0 to size-1, updated AFTER reading and pointing to the next readable byte
          bitptr : 0b, $               ; store a BIT position pointer to point inside buffer[byteptr], goes from 8 to 1 (N bits read of current byte)
          buffersize : 0L, $
          dvalid : make_array(6,2,/BYTE), $
          lun : 0L, $
          filesize : 0L, $
          start_positions: LIST() $
        }
end