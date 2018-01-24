;+
; :description:
;    The stx_telemetry_writer structure is a container for the TM data and
;    information for the TM data management. It does not write data to the disk
;    but keeps the TM packet in memory. Do not use directly, use stx_tmw.pro instead.
;
; :categories:
;    simulation, writer, telemetry
;
; :keywords:
;    id : in, optional, type="long", default="0L"
;             Assigns a unique id to this telemetry writer. The may id
;             will be used by stx_tmw
;    size : in, optional, type="long", default="4112L"
;             Defines the initial size of the telemetry buffer. By default
;             this is the maximum TM packet length
; :returns:
;    A telemetry writer struct is returned that contains a byte buffer and
;    according position pointers
;
; :examples:
;    tmw = stx_telemetry_writer()
;
; :history:
;    19-Mar-2013 - Laszlo I. Etesi (FHNW), initial release
;    03-Jun-2015 - Laszlo I. Etesi (FHNW), bufixing (flush to file routine)
;    22-Jul-2015 - Laszlo I. Etesi (FHNW), replaced close with free_lun
;    04-Aug-2015 - Laszlo I. Etesi (FHNW), writing big endian
;-

;+
; :description:
;    Cleanup of this class
;-

function stx_bitstream_writer::init, size=size, filename=filename
  ; default size is maximum length of tm packet
  default, size, 2L^25

  if keyword_set(filename) then begin
    openw, lun, filename, /get_lun
    self.lun = lun
  endif

  self.buffer = ptr_new(bytarr(size))
  self.size = size
  self.bitptr = 8
  self.dvalid = [[1, 2, 12, 3, 13, 14, 15], [8, 16, 16, 32, 32, 64, 64]]
  self.packet_boundary = LIST()
  
  ;static xml text
  newline = string(10B)
  str_header = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
  str_header += newline + '<ns2:ResponsePart xmlns:ns2="http://edds.egos.esa/model">'
  str_header += newline + '<Response>'+newline+'<PktRawResponse>'
  self.xml_header = ptr_new(str_header)
  
  str_footer = '</PktRawResponse>'+newline+'</Response>'+newline+'</ns2:ResponsePart>'
  self.xml_footer = ptr_new(str_footer)
  
  str_leaf_header = '<PktRawResponseElement  packetID="1">'+newline+'<Packet>'
  self.leaf_header = ptr_new(str_leaf_header)
  
  str_leaf_footer = newline+'</Packet>'+newline+'</PktRawResponseElement>'
  self.leaf_footer = ptr_new(str_leaf_footer)  
  
  self.scos_header = ptr_new('000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b')
  
  return, 1
end

; :history:
;   06-Jun-2015 - Laszlo I. Etesi (FHNW), - bugfix, cutting of at self.byteptr-1
;                                         - bugfix, not trying to write out when internal pointers at at zero
;   23-Nov-2016 - Simon Marcin (FHNW),    - added hex, newline and xml format
;   13-Jan-2016 - Laszlo I. Etesi (FHNW), - re-introducing bugfix from June 6 2015                                   
; :todo:
;   06-Jun-2015 - Laszlo I. Etesi (FHNW), - what to do with started bits?
pro stx_bitstream_writer::flushtofile, hex=hex, newline=newline, xml=xml
  default, hex, 0
  default, newline, 0
  default, xml, 0
  
  if(self.byteptr eq 0 && self.bitptr eq 8) then return
  if self.lun eq 0 then begin
    message, 'No lun to write a file.', /continue
    return
  endif
  
  ; we write a SOLO XML file
  if xml then begin
    
    PRINTF,self.lun,*self.xml_header
    
    start=0
    foreach boundary, self.packet_boundary do begin
      PRINTF,self.lun,*self.leaf_header
      PRINTF,self.lun, FORMAT='("000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b",$)'
      for i=start, boundary-1 do begin
        PRINTF,self.lun, FORMAT='(Z02,$)', (*self.buffer)[i]
      endfor
      PRINTF,self.lun,*self.leaf_footer
      start=boundary
    endforeach
    
    PRINTF,self.lun,*self.xml_footer
    
  endif else begin
  ; we write a regular file
    if hex then begin
      ;HEX format
      if newline then begin
        ;newline after each packet
        start=0
        foreach boundary, self.packet_boundary do begin
          for i=start, boundary-1 do begin
            PRINTF,self.lun, FORMAT='(Z02,$)', (*self.buffer)[i]
          endfor
          printf,self.lun,''
          start=boundary
        endforeach
      endif else begin
        ;no newline
        for i=0L, self.byteptr-1 do begin
          PRINTF,self.lun, FORMAT='(Z02,$)', (*self.buffer)[i]
        endfor
      endelse
    endif else begin
      ;BINARY format
      writeu, self.lun, (*self.buffer)[0:self.byteptr-1]
    endelse
    
  endelse
  
  
  *(self.buffer) = 0b
  self.byteptr = 0L
  self.bitptr = 8b
end

;+
; :description:
;   writes out the 'data' in 1 byte big endian formatted
;-
pro stx_bitstream_writer::write_8bits_big_endian, data, debug=debug, silent=silent
  self->write, swap_endian(fix(data, type=1), /swap_if_little_endian), bits=8, debug=debug, silent=silent
end

;+
; :description:
;   writes out the 'data' in 2 bytes big endian formatted
;-
pro stx_bitstream_writer::write_16bits_big_endian, data, debug=debug, silent=silent
  self->write, swap_endian(fix(data, type=12), /swap_if_little_endian), bits=16, debug=debug, silent=silent
end

;+
; :description:
;   writes out the 'data' in 3 bytes big endian formatted
;-
pro stx_bitstream_writer::write_24bits_big_endian, data, debug=debug, silent=silent
  big_e_data = swap_endian(fix(data, type=13), /swap_if_little_endian)
  big_e_data_shifted = ishft(big_e_data, -8)
  self->write, big_e_data_shifted, bits=24, debug=debug, silent=silent
end

;+
; :description:
;   writes out the 'data' in 4 bytes big endian formatted
;-
pro stx_bitstream_writer::write_32bits_big_endian, data, debug=debug, silent=silent
  self->write, swap_endian(fix(data, type=13), /swap_if_little_endian), bits=32, debug=debug, silent=silent
end

;+
; :description:
;    This routine writes data to the stx_telemetry_writer structure.
;    The data bits are written from "left to right", meaning that
;    the byte array (stream) is filled from msb to lsb.
;    Example sequence with NUMBER (bits):
;    1b (1), 1b (3), 1b (4), 15l (4), 1l (8) ->
;    [128, 0, ...], [144, 0, ...], [145, 0, ...], [145, 240, 0, ...], [145, 240, 16, 0, ...]
;
; :categories:
;    simulation, writer, telemetry
;
; :keywords:
;
;    data : in, required, type="byte, int, uint, long, ulong"
;           This variable contains the data to be written to the
;           telemetry output buffer. Please be aware that
;           floating point types are not allowed.
;
;    bits : in, optional, type="int", default="bit size of data"
;           This specifies the number of bits (with msb to lsb from
;           left to right) to be written to the telemetry buffer
;           from the input data.
;
;    skip_bits : in, optional, type="long", default="0L"
;                This keyword will skip the specified number of bits
;                and move the telemetry struct byte and bit pointer.
;                This shift in pointer is permanent.
;
;    before_ptr : out, optional, type="longarr(2)"
;                This keyword returns the position of the byte (array 0) and bit
;                (array 1) pointer before any skipping, moving, or writing has occurred.
;                CAREFUL: The bit (array 1) position starts at 8 and goes through 1.
;
;    after_ptr : out, optional, type="longarr(2)"
;                This keyword returns the position of the byte (array 0)
;                and bit (array 1) pointer into the telemetry stream after skipping and/or writing.
;                CAREFUL: The bit (array 1) position starts at 8 and goes through 1.
;                CAREFUL: If a temporary writing position was specified, this
;                after_ptr will point to the position in the telemetry stream
;                after writing to that temporary position, i.e. it will disagree
;                with what the telemetry structure will say. Use this to
;                continue writing at that temporary position.
;
;    tmp_write_pos : in, optional, type="longarr(2)"
;                    Use this keyword to "jump" into an arbitrary position in the
;                    telemetry stream. Combined with skip_bits it can be used
;                    to "keep space" for fixed-length header data that contains
;                    fields that are dependent on some dynamic packet. The input array
;                    has the byte pointer at position 0 and the bit pointer at position 1.
;                    CAREFUL: The bit (array 1) position starts at 8 and goes through 1.
;                    CAREFUL: Currently, the data is added using logical OR and not
;                    AND, i.e. it is not possible at the moment to overwrite data,
;                    only to "add" information.
;
;    debug : in, optional, type="boolean", default="0"
;            If set to 0, no debug information is printed, otherwise
;            the telemetry struct's status is printed to the console
;
;    silent : in, optional, type="boolean", default="0"
;             If set to 0, warning messages (informational) are printed
;             to the console, otherwise they are suppressed.
;             
;    extact : in, optional, type="boolean", default="0"
;             Needs to be set to write an array, otherwise an error
;             will be thrown. Uses standard numbering of array[0,1,2,3,...]
;
; :examples:
;    stx_tmw, tmw=tmw, data=1L, bits=16 -> buffer: 0   1
;    stx_tmw, tmw=tmw, data=1L, bits=16 -> buffer: 0   1   0   1
;
; :history:
;    22-Mar-2013 - Laszlo I. Etesi (FHNW), initial release
;    26-Mar-2013 - Laszlo I. Etesi (FHNW), fixed an issue with delta time calculation
;    26-Mar-2013 - Laszlo I. Etesi (FHNW), added random access and bit-stream information
;    14-Apr-2013 - Nicky Hochmuth (FHNW), fixed overflow when passing bits as uint / replaced 2^X by 2L^X
;-
pro stx_bitstream_writer::write, data, bits=bits, skip_bits=skip_bits, before_ptr=before_ptr, after_ptr=after_ptr, tmp_write_pos=tmp_write_pos, debug=debug, silent=silent, extract=extract

  ; set default values
  default, debug, 0
  default, silent, ~debug

  ; check if data is present
  if(~isvalid(data)) then begin
    if(~silent) then message, '[WARN] Data variable is emtpy. No data to write. Returning...', /continue, /informational
    return
  endif

  ; set before writing pointer (save tmw pointers)
  before_ptr = [self.byteptr, self.bitptr]

  ; copy data to value to make sure it is not changed outside
  value = data

  if isa(data, /array) && keyword_set(extract) then begin
    if keyword_set(extract) then begin
      for array_i=0L, n_elements(value)-1 do self->write, value[array_i], bits=bits, debug=debug, silent=silent
    endif else begin
      message, '[ERROR] Please use stx_bitstream_writer::write /extract to write an array.'   
    endelse
  end else begin
    ; check if data is a valid input type (i.e. NON-floating point type)
    dtype = size(value, /type)
    dpos = where(dtype eq self.dvalid[*,0])
    if(dpos eq -1) then begin
      message, '[ERROR] Invalid data type for writing. Must be one of the following: BYTE, INT, UINT, LONG, ULONG, ULONG64. Exiting...', /continue, /informational
      return
    endif

    ; set temporary writing positions
    ; when writing to the temp position, the bits are OR "added" so they are complementary and not overwritten
    if(isvalid(tmp_write_pos)) then begin
      if(n_elements(tmp_write_pos) ne 2) then message, '[ERROR] Invalid temporary writing position information.'
      if(~silent or debug) then message, '[DEBUG] Setting temporary writing position from [' + trim(string(self.byteptr)) + ',' + trim(string(uint(self.bitptr))) + '] to [' + arr2str(trim(string(tmp_write_pos)), ',') + ']', /continue, /informational
      self.byteptr = tmp_write_pos[0]
      self.bitptr = tmp_write_pos[1]
    endif

    ; skip bits (shift + X bits)
    if(isvalid(skip_bits)) then begin
      skp_bytes = long(skip_bits/8)
      skp_bits = skip_bits mod 8

      if(debug) then message, '[DEBUG] Skipping ' + trim(string(skip_bits)) + ' bits', /continue, /informational ;, byte pointer ' + trim(string(self.byteptr)) + '->' + trim(string(skp_bytes)) + ', bit pointer ' + trim(string(uint(self.bitptr))) + '->' + trim(string(self.bitptr - skp_bits)), /continue, /informational

      self.byteptr += skp_bytes
      self.bitptr -= skp_bits
    endif

    ; check if bits is present and set default values if necessary
    if(~isvalid(bits)) then begin
      if(~silent) then message, '[WARN] No number of bits defines, writing all data.', /continue, /informational
      bits = self.dvalid[dpos+5]
    endif

    ; make a copy of the number of bits
    ; fix necessary to prevent passing of uint
    ; 13
    resbits = fix(bits)

    if(debug) then message, '[DEBUG] Writing data', /continue, /informational
    ; loop as long as we have bits left to copy
    while (resbits gt 0) do begin
      ; shift value so that the MSB fit into the current byte
      shft_value = ishft(value, -1 * (resbits - self.bitptr))

      ; "trim" the shifted value to fit the available bits in this byte
      trm_value = shft_value and 2L^(self.bitptr)-1

      ; add shifted and trimmed values to byte
      (*self.buffer)[self.byteptr] = (*self.buffer)[self.byteptr] or trm_value

      ; adjust residual bits and pointers
      new_bitptr = resbits - self.bitptr
      resbits -= self.bitptr
      self.bitptr = (new_bitptr ge 0) ? 8 : abs(new_bitptr)
      self.byteptr += (new_bitptr ge 0)
    endwhile


  endelse ; normal write data mode

  ; set after byte and bit pointer
  after_ptr = [self.byteptr, self.bitptr]

  ; restore original pointers
  if(isvalid(tmp_write_pos)) then begin
    if(~silent or debug) then message, '[DEBUG] Restoring pointer from [' + trim(string(self.byteptr)) + ',' + trim(string(uint(self.bitptr))) + '] to [' + arr2str(trim(string(before_ptr)), ',') + ']', /continue, /informational
    self.byteptr = before_ptr[0]
    self.bitptr = before_ptr[1]
  endif

  ; print some debug information if requested
  if(debug) then begin
    message, '[DEBUG] TMW pointers: ' + arr2str(trim(string([self.byteptr, self.bitptr]))), /continue, /informational
    last_data_byte = max([max(where((*self.buffer) ne 0)), self.byteptr])
    if(last_data_byte ne -1) then message, '[DEBUG] TMW buffer: [' + arr2str(trim(uint((self.getbuffer())[0:last_data_byte[0]]))) + '], ' + trim(string(self.size-last_data_byte[0]-1)) + ' bytes unused and hidden.', /continue, /informational
    message, '[DEBUG] Pointer before: ' + arr2str(trim(string(before_ptr))), /continue, /informational
    message, '[DEBUG] Pointer after: ' + arr2str(trim(string(after_ptr))), /continue, /informational
    if(isvalid(skip_bits)) then message, '[DEBUG] Skipped bits: ' + trim(string(skip_bits)), /continue, /informational
    if(isvalid(tmp_write_pos)) then message, '[DEBUG] Temporary writing position: ' + arr2str(trim(string(tmp_write_pos))), /continue, /informational
  endif
end

function stx_bitstream_writer::getbitposition
  return, self.byteptr * 8L + (8 - self.bitptr)
end

;+
; :description:
;    Convenience routine that prints out the telemetry packet and optionally a bit difference
;    between what was counted externally (bitctr) and recorded by the tmw struct
;
; :categories:
;    simulation, writer, telemetry, debugging, utils
;
; :params:
;    packet : in, required, type="string"
;             This is the packet name, e.g. SOURCE DATA
;
; :keywords:
;    tmw : in, optional, type="stx_pixel_data", default="new stx_pixel_data"
;          A telemetry writer struct that is used to store telemetry stream
;
;    bitctr : in, optional, type="long"
;             This is the bit count recorded in the outside routine and used to create a
;             delta bit count with tmw
;
;    state : in, optional, type="string", default="< or >"
;            The state is a string that is prepended to the debug message (after DEBUG).
;            It is < if the packet was opened or > if it was closed. For in-packet
;            bit differences for example, use -.
; :examples:
;    stx_telemetry_debug_message, 'SOURCE DATA', tmw=tmw, bitctr=bitctr, state='-'
;
; :history:
;    27-Mar-2013 - Laszlo I. Etesi (FHNW), initial release
;    20-Apr-2013 - Nicky Hochmuth (FHNW), integrate to object
;-
pro stx_bitstream_writer::debug_message, packet, bitctr=bitctr, state=state
  ; default is begin state (<) or end state (>)
  default, state, isvalid(bitctr) ? '>' : '<'

  ; if tmw and bitctr are present, print delta bits, otherwise only print state and packet
  if(isvalid(bitctr)) then begin
    total_bits = self.byteptr * 8L + (8 - self.bitptr) - bitctr
    no_bytes = trim(string(floor(total_bits/8)))
    no_bits = trim(string(total_bits mod 8))
    packet_info = trim(string(total_bits)) + '(' + no_bytes + 'B, ' + no_bits + 'b)'
    message, '[DEBUG] ' + state + packet + ' [' + packet_info + ']', /informational, /continue
  endif else begin
    message, '[DEBUG] ' + state + packet, /informational, /continue
  endelse
end

function stx_bitstream_writer::getPosition
  return, [self.byteptr, self.bitptr]
end

;+
; :description:
;    sets either the actual position or the one by boundary_bit as border of a packet.
;-
pro stx_bitstream_writer::setBoundary, boundary_bit=boundary_bit
  
  if n_elements(boundary_bit) eq 0 then boundary_bit = self.byteptr
  if boundary_bit gt self.size then message, 'boundary_bit is out of bounds'
  self.packet_boundary.add, boundary_bit
  
end

function stx_bitstream_writer::getBuffer, trim=trim
  return, ~keyword_set(trim) ? *self.buffer : (*self.buffer)[0:self.byteptr]
end

pro stx_bitstream_writer::cleanup
   self->flushtofile
   if(self.lun gt 0) then begin
    if(self.lun lt 100) then close, self.lun else free_lun, self.lun
   endif
end

pro stx_bitstream_writer__define
  compile_opt idl2, hidden
  ; create stx_telemetry_writer structure that contains all information
  ; on the tm data writing process
  void = { stx_bitstream_writer, $
    size : 0L, $              ; store the tm writer buffer size, can change (e.g. if n_elements(buffer) < max telemetry packet length
    buffer : ptr_new(), $     ; store the actual data buffer
    byteptr : 0L, $           ; store a byte stream position pointer, goes from 0 to size-1, updated AFTER writing and pointing to the next writable byte
    bitptr : 8b, $            ; store a BIT position pointer to point inside buffer[ptr], goes from 8 to 1 (where 8 is the
    ; MSB and 1 the LSB, update AFTER writing and pointing to the next writeable bit
    lun : 0L, $
    packet_boundary: LIST(), $; store the boundaries of packets
    xml_header : ptr_new(), $ ; some xml 
    xml_footer : ptr_new(), $
    leaf_header : ptr_new(), $
    leaf_footer : ptr_new(), $
    scos_header : ptr_new(), $
    dvalid : make_array(7,2,/BYTE) $
  }

end