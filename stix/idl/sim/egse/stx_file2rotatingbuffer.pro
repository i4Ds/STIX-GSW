;+
; :file_comments:
;   This file contains the scripts for reading back in rotating buffer from binary format (disk)
;   to the STIX rotating buffer format (specified in STIX-TN-0041-SRC)
;   please note that no extra transformations (e.g. detector schemes)
;   are done, i.e. the assumed scheme is SC.
;
; :categories:
;   Flight software simulation, data export, rotating buffer
;
; :examples:
;   stx_file2rotatingbuffer, rotating_buffer=rotating_buffer, filename='rotating_buffer.bin'
;
; :history:
;   22-Jul-2015 - Laszlo I. Etesi (FHNW), initial release
;   04-Aug-2015 - Laszlo I. Etesi (FHNW), support for big endian
;   13-Aug-2015 - Laszlo I. Etesi (FHNW), - fixed endianness
;                                         - fixed block number
;                                         - mapping detector to FPGA scheme
;   26-Aug-2015 - Laszlo I. Etesi (FHNW), bugfix: fixed auto resetting of timestamps
;   13-Jul-2016 - Laszlo I. Etesi (FHNW), added aspect block handling (data are ignored!)
;   06-Mar-2017 - Laszlo I. Etesi (FHNW), much improved reading using templating
;   20-Jan-2017 - Laszlo I. Etesi (FHNW), added new (and corrected) FPGA-to-Subcollimator detector mapping
;-
;+
; :description:
;   this internal routine converts fractional binary seconds and subseconds to
;   a timestam of format S.SS with S in 32 bits and SS in 16 bits
;
; :params:
;   seconds : in, required, type='long'
;     the seconds of the timestamp
;
;   subseconds : in, required, type='int'
;     the binary subseconds of the timestamp
;     
;   timestamp : out, type='double'
;     the timestamp of a rotating buffer entry in seconds
;-
pro _calculate_timestamp_from_subseconds_seconds, seconds, subseconds, timestamp
  ; define bits for subseconds
  bits_subsecond = 16
  
  ; add seconds to timestamp
  timestamp = seconds

  ; add subseconds
  ; first identify which exponents for binary fractions are used
  exp = (subseconds and 2UL^(bits_subsecond - indgen(bits_subsecond) - 1)) gt 0

  if(total(exp) eq 0) then return

  ; now use those exponents to calculate decimal numbers
  timestamp += total(1d/(2UL^(where(exp eq 1)+1)))
end

;+
; :description:
;   this routine reads a block header (data type, block number, timestamp,
;   etc.)
;
; :keywords:
;   reader : in, required, type='stx_bitstream_reader'
;     the configured bit stream reader pointing to the rotating buffer
;     binary file
;
;   data_type : out, type='byte'
;     the data type (2 for 'detectors', 1 for 'aspect')
;
;   spares : out, type='byte'
;     spares that should be all zero
;    
;   block_number : out, type='byte'
;     the current block number
;     
;   timestamp : out, type='double'
;     the timestamp of current rotating buffer sequence
;     
;   null_bits : out, type='ulong64'
;     this keyword will contain the timestamp bits (48) 
;     for block numbers > 1; they should be zero and/or ignored
;     
;   debug : in, optional, type='boolean', default='0'
;     set this to true to receive debug output
;     
;   silent : in, optional, type='boolean', default='1'
;     set this to true to receive some extra output
;-
pro _read_block_header, reader=reader, data_type=data_type, spares=spares, block_number=block_number, timestamp=timestamp, null_bits=null_bits, debug=debug, silent=silent
  ; descriptor: Data Type
  data_type = reader->read(1, bits=2, debug=debug, silent=silent)

  ; descriptor: Spares - 7 zero bits
  spares = reader->read(1, bits=7, debug=debug, silent=silent)

  ; descriptor: Block number - 7 bits
  block_number = reader->read(1, bits=7, debug=debug, silent=silent)

  ; handle first and other blocks differently
  if(block_number eq 0) then begin
    ; seconds
    seconds = reader->read(13, bits=32, debug=debug, silent=silent)

    ; subseconds
    subseconds = reader->read(12, bits=16, debug=debug, silent=silent)

    ; calculate subseconds and seconds from timestamp
    _calculate_timestamp_from_subseconds_seconds, seconds, subseconds, timestamp
  endif else begin
    ; read 48 null bits
    null_bits = reader->read(15, bits=48, debug=debug, silent=silent)
  endelse
end

;+
; :description:
;   use this routine to check if a new sequence is starting in the reader
;
; :keywords:
;   reader : in, required, type='stx_bitstream_reader'
;     the configured bit stream reader pointing to the rotating buffer
;     binary file
;
; :returns:
;   1 if a new sequence starts, 0 otherwise
;-
function _buffer_on_block_boundary, reader=reader
  ; get the current position into the byte buffer of the reader
  current_position = reader->getposition()
  return, current_position[1] eq 0 and current_position[0] mod 512 eq 0
end

;+
; :description:
;   this routine checks if the reader is at the beginning of a new
;   sequence; if so it executes the header reading routine, otherwise
;   it returns; also adds some debug features
;   In case of aspect data, the rotating_buffer input structure is not updated!
;
; :keywords:
;   rotating_buffer : in, required, type='stx_fsw_rotating_buffer'
;     the currently processed rotating buffer structure
;
;   reader : in, required, type='stx_bitstream_reader'
;    the bit stream reader that has access to the rotating buffer
;    binary file
;
;   debug : in, optional, type='boolean', default='0'
;     set this to true to receive debug output
;
;   silent : in, optional, type='boolean', default='1'
;     set this to true to receive some extra output
;     
;   data_type : out, optional, type='byte'
;     returns the data type of the packet: 1 = aspect (1 block total), 2 = rotating buffer entry (49 blocks total)
;-
pro _handle_header_reading, rotating_buffer=rotating_buffer, reader=reader, debug=debug, silent=silent, data_type=data_type
  ; start a new header whenever we read a new block
  if(_buffer_on_block_boundary(reader=reader)) then begin
    _read_block_header, reader=reader, data_type=data_type, spares=spares, block_number=block_number, timestamp=timestamp, null_bits=null_bits, debug=debug, silent=silent
    
    if(~keyword_set(silent)) then begin
      if(data_type eq 1) then print, 'Found ASPECT data'
      if(data_type eq 2) then print, 'Found rotating buffer data' 
      print, block_number, format='("Reading block Number: ", I)'
    endif
    
    ; do not continue if aspect data was found
    if(data_type eq 1) then return

    ; the first block will contain timing information
    if(block_number eq 0 && rotating_buffer.timestamp eq 0) then begin
      rotating_buffer.timestamp = timestamp
      if(~keyword_set(silent)) then begin
        print, timestamp, format='("Timestamp: ", D)'
      endif
    endif

    ; ignore all other values
    ; NOOP
  endif
end

;+
; :description:
;   this is the actual reader routine to read a rotating buffer
;   binary file to an IDL rotating buffer structure;
;   please note that no extra transformations (e.g. detector schemes)
;   are done! Aspect data blocks are ignored
;
; :keywords:
;   filename : in, required, type='string'
;     filename and path to the rotating buffer binary file
;
;   debug : in, optional, type='boolean', default='0'
;     set this to true to receive debug output
;
;   silent : in, optional, type='boolean', default='0'
;     set this to true to receive some extra output
;-
function stx_file2rotatingbuffer, filename=filename
  ; mapping between "straight-up" subcollimator numbering and "FPGA" order
  detector_mapping_old = [5,11,1,2,6,7,12,13,10,16,14,15,8,9,3,4,22,28,31,32,26,27,20,21,17,23,18,19,24,25,29,30] - 1
  detector_mapping = [1,2,6,7,5,11,12,13,14,15,10,16,8,9,3,4,31,32,26,27,22,28,20,21,18,19,17,23,24,25,29,30] - 1
  
  ; new and optimized reading

  ; build transformation array
  eacc_to_fsw_mapping = uintarr(32 * 12 * 32)
  for p_i = 0, 11 do begin
    for  d_i = 0, 31 do begin
      for  e_i = 0, 31 do begin
        index_fpga = e_i + d_i * 32 + p_i * 32 * 32
        index_fsw = detector_mapping[d_i] + p_i * 32 + e_i * 32 * 12
        eacc_to_fsw_mapping[index_fsw] = index_fpga
      endfor
    endfor
  endfor

  ; restore templates
  restore, concat_dir(concat_dir(getenv('STX_FSW'), 'binary'), 'rotating_buffer_block_template.sav')
  restore, concat_dir(concat_dir(getenv('STX_FSW'), 'binary'), 'rotating_buffer_last_block_template.sav')
  
  ; set some default structure array increment size
  rb_increment = 1000
  rotating_buffers_space = rb_increment
  rotating_buffers = replicate({stx_fsw_rotating_buffer}, rotating_buffers_space)
  rotating_buffers_i = 0
  
  ; read file provided to the end
  openr, lun, filename, /get_lun
  while ~eof(lun) do begin
    rb_offset = 0
    rb_counts = uintarr(12 * 32 * 32)
        
    ; every rotating buffer consists of 49 blocks
    for block_i = 0L, 48 do begin
      ; select the proper template
      if(block_i lt 48) then rb_block = read_binary(lun, template=rb_block_template) $
      else rb_block = read_binary(lun, template=rb_last_block_template)

      block_id = rb_block.descriptor and 127
      
      if(block_id eq 0) then begin
        _calculate_timestamp_from_subseconds_seconds, rb_block.timestamp_seconds, rb_block.timestamp_milliseconds, timestamp
      endif

      rb_counts[rb_offset] = rb_block.counts
      if(block_id eq 48) then rb_triggers = rb_block.triggers

      rb_offset += 252
    endfor
    
    ; create rotating buffer structure
    rotating_buffer = {stx_fsw_rotating_buffer}
    rotating_buffer.timestamp = timestamp
    rotating_buffer.counts = transpose(reform(rb_counts[eacc_to_fsw_mapping], 32, 12, 32))
    rotating_buffer.triggers = rb_triggers

    ; grow if needed
    if(rotating_buffers_i ge rotating_buffers_space - 1) then rotating_buffers = [rotating_buffers, replicate({stx_fsw_rotating_buffer}, rb_increment)]
    
    ; add rotating buffer to array
    rotating_buffers[rotating_buffers_i++] = rotating_buffer
  endwhile
  
  free_lun, lun

  ; cut off where needed and return
  return, rotating_buffers[0:rotating_buffers_i-1]
end