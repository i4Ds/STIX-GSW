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

pro read_rb_and_merge
  ; mapping between "straight-up" subcollimator numbering and "FPGA" order
  detector_mapping_old = [5,11,1,2,6,7,12,13,10,16,14,15,8,9,3,4,22,28,31,32,26,27,20,21,17,23,18,19,24,25,29,30] - 1
  detector_mapping = [1,2,6,7,5,11,12,13,14,15,10,16,8,9,3,4,31,32,26,27,22,28,20,21,18,19,17,23,24,25,29,30] - 1
  
  ; build transformation array
  sequence = lindgen(12 * 32 * 32)
  eacc_to_fsw_mapping = uintarr(32 * 12 * 32)
  for p_i = 0, 11 do begin
    for  d_i = 0, 31 do begin ; eacc_to_fsw_mapping[e_i + e_i * p_i + e_i * p_i + detector_mapping[d_i]] =
      for  e_i = 0, 31 do begin
        index_fpga = e_i + d_i * 32 + p_i * 32 * 32
        index_fsw = detector_mapping[d_i] + p_i * 32 + e_i * 32 * 12
        eacc_to_fsw_mapping[index_fsw] = index_fpga
      endfor
    endfor
  endfor
  
  base_url = 'C:\Users\LaszloIstvan\Dropbox (STIX)\FSW_Test_Data\v20161114_1012\T1b\'
  rb_files = find_file(concat_dir(base_url, '*_rotating_buffer.bin'))

  restore, 'C:\Temp\rotating_buffer_block_template.sav'
  restore, 'C:\Temp\rotating_buffer_last_block_template.sav'
  rb_increment = 10000
  rotating_buffers_space = rb_increment
  rotating_buffers = replicate({stx_fsw_rotating_buffer}, rotating_buffers_space)
  rotating_buffers_i = 0
  
  for rb_file_i = 0L, n_elements(rb_files)-1 do begin
    openr, lun, rb_files[rb_file_i], /get_lun
    tic
    while ~eof(lun) do begin
      rb_offset = 0
      rb_counts = uintarr(12 * 32 * 32)
      for block_i = 0L, 48 do begin
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
      
      if(rotating_buffers_i ge rotating_buffers_space - 1) then rotating_buffers = [rotating_buffers, replicate({stx_fsw_rotating_buffer}, rb_increment)]
      rotating_buffers[rotating_buffers_i++] = rotating_buffer
    endwhile
    
     
    free_lun, lun
    toc
  endfor
  rotating_buffers = rotating_buffers[0:rotating_buffers_i-1] 
  print, rotating_buffers_i
  stop
end