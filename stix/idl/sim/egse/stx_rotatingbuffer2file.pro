;+
; :file_comments:
;   This file contains the scripts for writing out rotating buffer in binary format
;   to disk (specified in STIX-TN-0041-SRC); no data are modified (no changing of
;   detector indeces; SC format is provided and is written to disk!)
;
; :categories:
;   Flight software simulation, data export, rotating buffer
;
; :examples:
;   stx_rotatingbuffer2file, rotating_buffer=rotating_buffer, filename='rotating_buffer.bin'
;
; :history:
;   01-Jul-2015 - Laszlo I. Etesi (FHNW), initial release
;   02-Jul-2015 - Laszlo I. Etesi (FHNW), switched seconds with subseconds
;   15-Jul-2015 - Laszlo I. Etesi (FHNW), added data dump option
;   22-Jul-2015 - Laszlo I. Etesi (FHNW), - fixed timestamp routine: using proper number of bits now
;                                         - renamed routine
;                                         - updated output format of rotating buffer ASCII
;                                         - replaced close by free_lun
;   03-Aug-2015 - Laszlo I. Etesi (FHNW), writing data big endian
;   05-Aug-2015 - Laszlo I. Etesi (FHNW), format change: block number starts at 0
;   13-Aug-2015 - Laszlo I. Etesi (FHNW), - fixed endianness
;                                         - fixed block number
;                                         - mapping detector to FPGA scheme
;   06-Mar-2017 - Laszlo I. Etesi (FHNW), increased file size
;   25-Jan-2017 - Laszlo I. Etesi (FHNW), added new (and corrected) FPGA-to-Subcollimator detector mapping
;-
;+
; :description:
;   this internal routine converts a timestamp (double precision in seconds) to
;   a subseconds (lsb) and seconds (msb) representation as used in the rotating buffer binary format
;
; :params:
;   timestamp : in, required, type='double'
;     the timestamp of a rotating buffer entry in seconds
;
;   seconds : out, type='long'
;     the seconds of the timestamp
;
;   subseconds : out, type='long'
;     the binary subseconds of the timestamp
;-
pro _extract_subseconds_seconds_from_timestamp, timestamp, seconds, subseconds
  seconds_bits = 32
  subseconds_bits = 16

  ; extract seconds first
  t_seconds = ulong(timestamp)
  seconds = t_seconds and 2L^(seconds_bits)-1

  ; extract subseconds
  t_subseconds = timestamp - ulong(timestamp)
  subseconds = 0UL

  ; loop over all the fraction bits
  ; and add them up
  for i = 1L, subseconds_bits do begin
    binary_val = 2d^(-i)

    div = t_subseconds / binary_val

    if(div ge 1.0) then begin
      subseconds += 2UL^(subseconds_bits - i)
      t_subseconds -= binary_val
    endif
  endfor
end

;+
; :description:
;   this internal routine writes the block headers to disk;
;   it is differentiating between the first and all other headers (different
;   specification)
;
; :keywords:
;   writer : in, required, type='stx_bitstream_writer'
;     the bitstream writer object used to write data to disk
;
;   bytes_left : in/out, required, type='int'
;     a byte counter used to count down the available bytes (for one block, i.e.
;     512 - 0)
;
;   block_number : in, required, type='int'
;     a block number counter used to identify which block is currently being written
;
;   timestamp : in, required, type='double'
;     the rotating buffer entry timestamp
;-
pro _write_block_header, writer=writer, bytes_left=bytes_left, block_number=block_number, timestamp=timestamp
  ; writing 2 bytes in one go (big endianness)
  
  ; descriptor: Data Type - 2 for Detectors
  writer->write, 2b, bits=2, debug=debug, silent=silent
  ;descriptor = uint(2)
  
  ; descriptor: Spares - 7 zero bits
  writer->write, 0b, bits=7, debug=debug, silent=silent
  ;descriptor = ishft(descriptor, 7)
  
  ; descriptor: Block number - 7 bits
  writer->write, block_number, bits=7, debug=debug, silent=silent
  ;descriptor = ishft(descriptor, 7) or (fix(block_number, type=1) and 2^7-1)
  
  ; write it to disk
  ;writer->write, descriptor, bits=16, debug=debug, silent=silent 
 
  ; two bytes used
  bytes_left -= 2

  ; handle first and other blocks differently
  if(block_number eq 0) then begin
    ; calculate subseconds and seconds from timestamp
    _extract_subseconds_seconds_from_timestamp, timestamp, seconds, subseconds

    ; timestamp: 32 seconds bits
    writer->write, seconds, bits=32, debug=debug, silent=silent
    
    ; timestamp: 16 subseconds bits
    writer->write, subseconds, bits=16, debug=debug, silent=silent
  endif else begin
    ; write 48 null bits
    writer->write, 0, bits=48, debug=debug, silent=silent
  endelse

  bytes_left -= 6
end

;+
; :description:
;   this internal routine writes out the block information and contents to an ASCI file
;
; :keyword:
;   lun : in, required, type='int'
;     a valid an open lun to write to
;     
;   rotating_buffer : in, optional, type='int'
;     must be set if block number is set; contains the current block id
;     
;   block_number : in, optional, type='int'
;     this keyword or 'counts' must be set; contains the block number
;     
;   timestamp : in, optional, type='double'
;     must be set if block number is set; the timestamp of a rotating buffer entry in seconds
;
;   type : in, optional, type='string'
;     must be set if 'block_number' is set; this is either 'COUNTS' or 'TRIGGERS'
;
;   counts : in, optional, type='long'
;     this keyword or 'block_number' must be set; contains the number of cout for current
;     detector, pixel, channel combination
;-
pro _write_logfile, lun=lun, rotating_buffer_id=rotating_buffer_id, block_number=block_number, timestamp=timestamp, type=type, counts=counts
  if(~keyword_set(lun)) then return

  if(keyword_set(block_number)) then begin
    _extract_subseconds_seconds_from_timestamp, timestamp, seconds, subseconds
    dec2hex, seconds, hex_sec, /upper, /quiet
    dec2hex, subseconds, hex_ssec, /quiet, /upper
    printf, lun, 'RID: ' + trim(string(fix(rotating_buffer_id))) + ', BLOCK#: ' + trim(string(fix(block_number))) + ', TYPE: ' + type +', SECONDS: 0x' + hex_sec + ', SUBSECONDS: 0x' + hex_ssec
  endif $
  else if (keyword_set(counts)) then begin
    printf, lun, counts
  endif
end

;+
; :description:
;   this routine writes a flat array of rotating buffer structures to disk
;   using the rotating buffer binary format specified in STIX-TN-0041-SRC
;
; :keywords:
;   rotating_buffer : in, required, type='stx_fsw_rotating_buffer*'
;     one rotating buffer structure or a flat array thereof to be written to disk
;
;   filename : in, required, type='string'
;     a file name and path to receive the binary data stream
;     
;   logfile : in, optional, type='string'
;     an optional file name and path to a logfile; if set that log file
;     will contain the block information and data in ASCII format
;-
pro stx_rotatingbuffer2file, rotating_buffer=rotating_buffer, filename=filename, logfile=logfile
  ppl_require, in=rotating_buffer, type='stx_fsw_rotating_buffer*'
  
  ; mapping between "straight-up" subcollimator numbering and "FPGA" order
  detector_mapping_old = [5,11,1,2,6,7,12,13,10,16,14,15,8,9,3,4,22,28,31,32,26,27,20,21,17,23,18,19,24,25,29,30] - 1
  detector_mapping = [1,2,6,7,5,11,12,13,14,15,10,16,8,9,3,4,31,32,26,27,22,28,20,21,18,19,17,23,24,25,29,30] - 1
  writer = stx_bitstream_writer(size=2L^30, filename=filename)

  if(keyword_set(logfile)) then openw, lun, logfile, /get_lun, width=32L*12*32

  ; loop over all rotating buffer elements, i.e. time
  for ridx = 0L, n_elements(rotating_buffer)-1 do begin
    ; block counter
    block_number = -1

    ; counter to keep track of bytes left
    bytes_left = 0

    ; read timestamp
    timestamp = stx_time2any(rotating_buffer[ridx].timestamp)

    ; start writing pixel data
    for pidx = 0L, 12-1 do begin
      for didx = 0L, 32-1 do begin
        for eidx = 0L, 32-1 do begin
          ; sanity checks
          if(bytes_left eq 1 or bytes_left lt 0) then message, 'The bytes counter should never be 1 or negative (zero is ok)'

          ; reset bytes left and increase block number
          if(bytes_left eq 0) then begin
            bytes_left = 512
            block_number++
          endif

          ; do this for the beginning of a new block
          if(bytes_left eq 512) then begin
            _write_block_header, writer=writer, bytes_left=bytes_left, block_number=block_number, timestamp=timestamp

            ; because we don't have data the first iteration, write the counts out BEFORE writing the block
            ; header
            if(keyword_set(lun)) then begin
              if(isvalid(counts)) then _write_logfile, lun=lun, counts=counts
              counts = []

              ; write header information
              _write_logfile, lun=lun, rotating_buffer_id=ridx, block_number=block_number, timestamp=timestamp, type='COUNTS'
            endif
          endif
          
          mapped_detector_idx = detector_mapping[didx]

          if(keyword_set(lun)) then counts = [counts, rotating_buffer[ridx].counts[eidx,pidx,mapped_detector_idx]]

          ; write pixel data
          writer->write, rotating_buffer[ridx].counts[eidx,pidx,mapped_detector_idx], bits=16, debug=debug, silent=silent

          ; adjust bytes left
          bytes_left -= 2
        endfor
      endfor
    endfor

    ; quick and dirty way to ensure we don't forget the last block
    if(keyword_set(lun)) then begin
      if(isvalid(counts)) then _write_logfile, lun=lun, counts=counts
      counts = []
      triggers = []

    ; enforce writing header info to indicate going over to triggers
      _write_logfile, lun=lun, rotating_buffer_id=ridx, block_number=block_number, timestamp=timestamp, type='TRIGGERS'
    endif

    ; start writing trigger accumulator data
    for tidx = 0L, 16-1 do begin
      ; sanity checks
      if(bytes_left lt 3 and bytes_left ne 0 or bytes_left lt 0) then message, 'The bytes counter should never be lower than 3 or negative (zero is ok)'

      ; reset bytes left and increase block number
      if(bytes_left eq 0) then begin
        bytes_left = 512
        block_number++
      endif

      if(bytes_left eq 512) then begin
        _write_block_header, writer=writer, bytes_left=bytes_left, block_number=block_number, timestamp=timestamp

        if(keyword_set(lun)) then begin
          if(isvalid(triggers)) then _write_logfile, lun=lun, counts=triggers
          triggers = []
          
          _write_logfile, lun=lun, rotating_buffer_id=ridx, block_number=block_number, timestamp=timestamp, type='TRIGGERS'
        endif
      endif

      ; write trigger counts (8 empty, 24 trigger data)
      writer->write, 0, bits=8, debug=debug, silent=silent
      writer->write, rotating_buffer[ridx].triggers[tidx], bits=24, debug=debug, silent=silent
      if(keyword_set(lun)) then triggers = [triggers, rotating_buffer[ridx].triggers[tidx]]

      ; adjust bytes left
      bytes_left -= 4
    endfor

    ; fill last block with zeros
    for bidx = 0L, bytes_left-1 do begin
      writer->write, 0b, bits=8, debug=debug, silent=silent
    endfor

    ; sanity checks
    if(block_number ne 48) then message, 'Incorrect final block number; should be 48'
    
    ; quick and dirty way to ensure we don't forget the last block
    if(keyword_set(lun)) then begin
      if(isvalid(triggers)) then _write_logfile, lun=lun, counts=triggers
      triggers = []
    endif
  endfor

  ; clean up
  writer->flushtofile
  destroy, writer
  if(keyword_set(logfile)) then free_lun, lun
end
