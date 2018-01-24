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
;-
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
function stx_file2qlbuffer, filename=filename, buffer_type=buffer_type  
  ; restore template
  restore, concat_dir(concat_dir(getenv('STX_FSW'), 'binary'), buffer_type + '_template.sav')
  
  ; read file provided to the end
  ptr_i = 0
  openr, lun, filename, /get_lun
  while(~eof(lun)) do begin
    buffer_str = read_binary(lun, template=qlbuffer_template)
    
    if(ptr_i eq 0) then buffer_str_set = replicate(buffer_str, 1000)

    buffer_str_set[ptr_i++] = buffer_str
  endwhile
  free_lun, lun
  
  ; cutoff extra
  buffer_str_set = buffer_str_set[0:ptr_i-1]
  
  switch (buffer_type) of
    'qlacc': begin
      ; mapping between "straight-up" subcollimator numbering and "FPGA" order
      detector_mapping_old = [5,11,1,2,6,7,12,13,10,16,14,15,8,9,3,4,22,28,31,32,26,27,20,21,17,23,18,19,24,25,29,30] - 1
	  detector_mapping = [1,2,6,7,5,11,12,13,14,15,10,16,8,9,3,4,31,32,26,27,22,28,20,21,18,19,17,23,24,25,29,30] - 1
	  
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

      qlacc_set = ulonarr(ptr_i, 32, 12, 32)
      
      for qlacc_i = 0L, ptr_i-1 do begin
        qlacc_set[qlacc_i, *, *, *] = transpose(reform(buffer_str_set[qlacc_i].data[eacc_to_fsw_mapping], 32, 12, 32))
      endfor
      
      return, qlacc_set
      break
    end
    'qlvar': begin      
      return, transpose(buffer_str_set.data)
      break
    end
    'qltrg': begin
      return, transpose(buffer_str_set.data)
      break
    end
    else: begin
      message, 'Unsupported type'
    end
  endswitch
end