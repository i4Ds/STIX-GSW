;+
; :description:
;   this routine generates the x-ray level 0 packet
;
;   PARAMETER                               VALUE               WIDTH               NOTE
;   ----------------------------------------------------------------------------------------------
;   APID-PID                                93                                      STIX auxiliary science data processing application
;   Packet Category                         12                                      Science
;   Packet data field length - 1            variable


;ToDO: Packet description

; :categories:
;   simulation, writer, telemetry, science_data, level 0
;
; :params:
;
; :keywords:
;
; :history:
;    29-Mar-2016 - Simon Marcin (FHNW), initial release
;    03-Oct-20126 - Simon Marcin (FHNW), added read and write routine
;-
function prepare_packet_structure_sd_xray_0_write_fsw, L0_ARCHIVE_BUFFER=L0_ARCHIVE_BUFFER, $
  compression_param_k_acc=compression_param_k_acc, compression_param_m_acc=compression_param_m_acc, $
  compression_param_s_acc=compression_param_s_acc, compression_param_k_t=compression_param_k_t, $
  compression_param_m_t=compression_param_m_t, compression_param_s_t=compression_param_s_t, $
  _extra=extra

  ; type checking
  if ((size(L0_ARCHIVE_BUFFER))[2] ne 11) then message, 'L0_ARCHIVE_BUFFER has to be a list of stx_fsw_archive_buffer_time_group'
  ppl_require, in=L0_ARCHIVE_BUFFER[0], type='stx_fsw_archive_buffer_time_group'

  default, compression_param_k_t, 5
  default, compression_param_m_t, 3
  default, compression_param_s_t, 0
  default, compression_param_k_acc, 5
  default, compression_param_m_acc, 3
  default, compression_param_s_acc, 0

  ; generate empty x-ray header paket
  packet = stx_telemetry_packet_structure_sd_xray_header()
  science_data = list()

  ; fill in the header data
  packet.ssid = 20
  packet.compression_schema_acc = ishft(compression_param_s_acc, 6) or ishft(compression_param_k_acc, 3) or compression_param_m_acc
  packet.compression_schema_t = ishft(compression_param_s_acc, 6) or ishft(compression_param_k_acc, 3) or compression_param_m_acc
  packet.number_time_samples = (size(L0_ARCHIVE_BUFFER))[1]
  
  ; convert time to scet
  stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
    stx_time_obj=L0_ARCHIVE_BUFFER[0].START_TIME, reverse=reverse
  packet.coarse_time = coarse_time
  packet.fine_time = fine_time
  
  ; store start_time
  start_time = (L0_ARCHIVE_BUFFER[0].START_TIME)
  
  ; fill in the subheader data
  for time_idx = 0L, packet.number_time_samples -1 do begin
    
    ; copy time slice to get better performance (as list::get is too slow)
    buffer_slice = L0_ARCHIVE_BUFFER[time_idx]
    
    ; create a subheader packet
    sub_packet = stx_telemetry_packet_structure_sd_xray_0_subheader()
    
    ; fill in the subheader data
    sub_packet.starting_time = fix(round(stx_time_diff(buffer_slice.START_TIME,start_time)*10))
    sub_packet.rate_control_regime = buffer_slice.rcr
    sub_packet.duration = fix(round(stx_time_diff(buffer_slice.END_TIME,$
      buffer_slice.START_TIME)*10))
    
    sub_packet.number_science_data_samples = (size(buffer_slice.ARCHIVE_BUFFER))[1]
    sub_packet.detector_mask=stx_mask2bits(buffer_slice.detector_mask,mask_length=32)
    sub_packet.pixel_mask=stx_mask2bits(buffer_slice.pixel_mask,mask_length=12)
  
    sub_packet.trigger_acc_0 = buffer_slice.trigger[0]
    sub_packet.trigger_acc_1 = buffer_slice.trigger[1]
    sub_packet.trigger_acc_2 = buffer_slice.trigger[2]
    sub_packet.trigger_acc_3 = buffer_slice.trigger[3]
    sub_packet.trigger_acc_4 = buffer_slice.trigger[4]
    sub_packet.trigger_acc_5 = buffer_slice.trigger[5]
    sub_packet.trigger_acc_6 = buffer_slice.trigger[6]
    sub_packet.trigger_acc_7 = buffer_slice.trigger[7]
    sub_packet.trigger_acc_8 = buffer_slice.trigger[8]
    sub_packet.trigger_acc_9 = buffer_slice.trigger[9]
    sub_packet.trigger_acc_10 = buffer_slice.trigger[10]
    sub_packet.trigger_acc_11 = buffer_slice.trigger[11]
    sub_packet.trigger_acc_12 = buffer_slice.trigger[12]
    sub_packet.trigger_acc_13 = buffer_slice.trigger[13]
    sub_packet.trigger_acc_14 = buffer_slice.trigger[14]
    sub_packet.trigger_acc_15 = buffer_slice.trigger[15]
  
    ; initialize pointer and prepare arrays for dynamic content
    sub_packet.dynamic_continuation_bits = ptr_new(bytarr(sub_packet.number_science_data_samples))
    sub_packet.dynamic_detector_id = ptr_new(bytarr(sub_packet.number_science_data_samples))
    sub_packet.dynamic_pixel_id = ptr_new(bytarr(sub_packet.number_science_data_samples))
    sub_packet.dynamic_energy_id = ptr_new(bytarr(sub_packet.number_science_data_samples))
    sub_packet.dynamic_counts = ptr_new(uintarr(sub_packet.number_science_data_samples))
  
    ;Loop through all data samples    
    for sample_id = 0L, sub_packet.number_science_data_samples-1 do begin
      
      ; get and attach continuation_bit and count
      counts = uint(buffer_slice.ARCHIVE_BUFFER[sample_id].COUNTS)
      counts = stx_km_compress(counts, compression_param_k_acc, compression_param_m_acc, compression_param_s_acc)
      continuation_bit = byte(2)
      IF (counts<256) THEN continuation_bit = byte(1)
      IF (counts eq 1) THEN continuation_bit = byte(0)
      IF (counts eq 0) THEN message, "Counts == 0! This should not occure, the minimum is 1.", /Info
      (*sub_packet.dynamic_continuation_bits)[sample_id] = continuation_bit
      (*sub_packet.dynamic_counts )[sample_id] = counts
  
      ; attach IDs of the corresponding Counts
      (*sub_packet.dynamic_detector_id)[sample_id] = buffer_slice.ARCHIVE_BUFFER[sample_id].DETECTOR_INDEX
      (*sub_packet.dynamic_pixel_id)[sample_id] = buffer_slice.ARCHIVE_BUFFER[sample_id].PIXEL_INDEX
      (*sub_packet.dynamic_energy_id)[sample_id] = buffer_slice.ARCHIVE_BUFFER[sample_id].ENERGY_SCIENCE_CHANNEL
  
    endfor
    
    ; add science data
    science_data.add, sub_packet
    
  endfor
  
  ;assign science_data to packet
  packet.dynamic_subheaders = ptr_new(science_data)
  return, packet
  
end


pro stx_telemetry_prepare_structure_sd_xray_0_write, L0_ARCHIVE_BUFFER_GROUPED=L0_ARCHIVE_BUFFER_GROUPED, $
  compression_param_k_acc=compression_param_k_acc, compression_param_m_acc=compression_param_m_acc, $
  compression_param_s_acc=compression_param_s_acc, compression_param_k_t=compression_param_k_t, $
  compression_param_m_t=compression_param_m_t, compression_param_s_t=compression_param_s_t, $
  solo_slices=solo_slices, _extra=extra


  solo_source_packet_header = stx_telemetry_packet_structure_solo_source_packet_header()

  ; read how many bits are left for the source data in bits
  max_packet_size = abs(solo_source_packet_header.pkg_word_width.source_data)

  ; generate spectra intermediate TM packet (based on the input type)
  source_data = prepare_packet_structure_sd_xray_0_write_fsw(L0_ARCHIVE_BUFFER = L0_ARCHIVE_BUFFER_GROUPED, _extra=extra)

  ; set the sc time of the solo_header packet
  solo_source_packet_header.coarse_time = source_data.coarse_time
  solo_source_packet_header.fine_time = source_data.fine_time

  ; copy all header information to solo packet
  tags = strlowcase(tag_names(source_data))

  for tag_idx = 0L, n_tags(source_data)-1 do begin
    tag = tags[tag_idx]

    if(~stregex(tag, 'header_.*', /bool)) then continue

    ; Copy the matching header information to solo_source_packet_header
    tag_val = source_data.(tag_idx)
    solo_source_packet_header.(tag_index(solo_source_packet_header, (stregex(tag, 'header_(.*)', /extract, /subexpr))[1])) = tag_val
  endfor

  ; get the number of time samples
  n_structures = source_data.number_time_samples
  structure_idx = 0

  ; set curr_packet_size = max_packet_size in order to create a new packet
  curr_packet_size = max_packet_size
  subheader_size = (*source_data.dynamic_subheaders)[0].pkg_word_width.pkg_total_bytes_fixed * 8

  ;Process ever subheader with its dynamic science data
  foreach subpacket, (*source_data.dynamic_subheaders) do begin

    science_idx = 0L
    while science_idx ne -1 do begin
  
      continuation_bit = (*subpacket.dynamic_continuation_bits)[science_idx]
      dynamic_size = (2+continuation_bit)*8 ;2B + 0B-2B
      if(science_idx eq 0) then dynamic_size+=subheader_size
      
      ; check if we have an overflow; if so -> start a new packet
      ; test for dynamic science part (and subheader if needed)
      if(curr_packet_size + dynamic_size gt max_packet_size) then begin
                
        ; finish the packet by assigning the lists before we create a new one
        if (structure_idx gt 0 OR science_idx gt 0) then begin
          slice_source_data = source_data
          slice_source_data.number_time_samples = n_elements(partial_source_data)
          slice_source_data.dynamic_subheaders  = ptr_new(partial_source_data)
          solo_slices[-1].source_data = ptr_new(slice_source_data)
        endif
                
        ; copy the 'SolO' packet
        solo_slice = solo_source_packet_header
  
        ; add 'SolO' slice to 'SolO' array
        if(isvalid(solo_slices)) then solo_slices = [solo_slices, solo_slice] $
        else solo_slices = solo_slice
  
        ; set the sequence count
        solo_slices[-1].source_sequence_count = n_elements(solo_slices) - 1

        ; initialize the current packet size to the fixed packet length
        curr_packet_size = source_data.pkg_word_width.pkg_total_bytes_fixed*8
        
        ; start a new list of subheaders
        partial_source_data = list()
        
        ; update all packet data field lengths
        solo_slices[-1].pkg_word_width.source_data = source_data.pkg_word_width.pkg_total_bytes_fixed * 8
        solo_slices[-1].data_field_length = source_data.pkg_word_width.pkg_total_bytes_fixed
        
        ; add 9 (not 10?) bytes for TM Packet Data Header that is otherwise not accounted for
        solo_slices[-1].data_field_length += 9
        
      endif
  
      ; run the following lines of code if we have to add a new subheader
      if(science_idx eq 0 OR n_elements(partial_source_data) eq 0) then begin
                
        ; copy the source data (prepare this 'partial' packet); copy it so that the fields are pre-initialized
        new_subpacket = subpacket
        
        ; adjust current packet size
        curr_packet_size += subpacket.pkg_word_width.pkg_total_bytes_fixed*8 ;add subheader size
        solo_slices[-1].data_field_length += subpacket.pkg_word_width.pkg_total_bytes_fixed
        
        ; calculate the amount of fitting science data samples
        fitting_samples = 0L
        dyn_size = 0L
        size_counts = 0L
        for i=science_idx, subpacket.number_science_data_samples-1 do begin
          dyn_size+=((*subpacket.dynamic_continuation_bits)[i]+2)*8
          if(curr_packet_size+dyn_size gt max_packet_size) then break
          fitting_samples+=1
          size_counts+=(*subpacket.dynamic_continuation_bits)[i]*8
        endfor
         
        ; copy the slices to new pointers
        max_science_idx = science_idx+fitting_samples-1
        continuation_bits_slice = (*subpacket.dynamic_continuation_bits)[science_idx:max_science_idx]
        detector_id_slice = (*subpacket.dynamic_detector_id)[science_idx:max_science_idx]
        pixel_id_slice = (*subpacket.dynamic_pixel_id)[science_idx:max_science_idx]
        energy_id_slice = (*subpacket.dynamic_energy_id)[science_idx:max_science_idx]
        counts_slice = (*subpacket.dynamic_counts)[science_idx:max_science_idx]
  
        ; initialize dynamic arrays
        new_subpacket.dynamic_continuation_bits = ptr_new(continuation_bits_slice)
        new_subpacket.dynamic_detector_id = ptr_new(detector_id_slice)
        new_subpacket.dynamic_pixel_id = ptr_new(pixel_id_slice)
        new_subpacket.dynamic_energy_id = ptr_new(energy_id_slice)
        new_subpacket.dynamic_counts = ptr_new(counts_slice)
  
        ; initialize number_of_structures
        new_subpacket.number_science_data_samples = fitting_samples
  
        ; update all packet data field lengths
        ; toDo
  
        ; set the dynamic lenght to 0
        new_subpacket.pkg_word_width.dynamic_continuation_bits = fitting_samples * 2
        new_subpacket.pkg_word_width.dynamic_detector_id = fitting_samples * 5
        new_subpacket.pkg_word_width.dynamic_pixel_id = fitting_samples * 4
        new_subpacket.pkg_word_width.dynamic_energy_id = fitting_samples * 5
        new_subpacket.pkg_word_width.dynamic_counts = size_counts
  
        ; adjust current packet size
        curr_packet_size += size_counts + (8*2*fitting_samples) ;add size of dynamic part
        solo_slices[-1].data_field_length += (size_counts/8 + (2*fitting_samples))
  
        ; if we reached the end of the subpacket, set idx to -1 to wtop the while loop
        science_idx += fitting_samples
        if (science_idx eq subpacket.number_science_data_samples) then science_idx =-1
        
        ; add created subheader to packet list
        partial_source_data.add, new_subpacket
  
      endif
  
    endwhile
    
    structure_idx++
    
  endforeach
  
  ; add last subheader list to last packet
  slice_source_data = source_data
  slice_source_data.number_time_samples = n_elements(partial_source_data)
  slice_source_data.dynamic_subheaders  = ptr_new(partial_source_data)
  solo_slices[-1].source_data = ptr_new(slice_source_data)
  
  ; update segementation flag
  if(n_elements(solo_slices) eq 1) then solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 3
  if(n_elements(solo_slices) gt 1) then begin
    solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 1
    solo_slices[-1].SEGMENTATION_GROUPING_FLAGS = 2
  endif

end



pro stx_telemetry_prepare_structure_sd_xray_0_read, fsw_archive_buffer_time_group=fsw_archive_buffer_time_group, $
  solo_slices=solo_slices, _extra=extra

  ; init counter for number of structures
  total_number_of_structures=0
  fsw_archive_buffer_time_group = list()

  ; get compression params
  compression_param_k_acc = fix(ishft((*solo_slices[0].source_data).compression_schema_acc,-3) and 7)
  compression_param_m_acc = fix((*solo_slices[0].source_data).compression_schema_acc and 7)
  compression_param_s_acc = fix(ishft((*solo_slices[0].source_data).compression_schema_acc,-6) and 3)
  compression_param_k_t = fix(ishft((*solo_slices[0].source_data).compression_schema_t,-3) and 7)
  compression_param_m_t = fix((*solo_slices[0].source_data).compression_schema_t and 7)
  compression_param_s_t = fix(ishft((*solo_slices[0].source_data).compression_schema_t,-6) and 3)
  
  ; start time as stx_time
  stx_telemetry_util_time2scet,coarse_time=(*solo_slices[0].source_data).coarse_time, $
    fine_time=(*solo_slices[0].source_data).fine_time, stx_time_obj=t0, /reverse
  
  ; use starting time and duration as unique identifier per time bin
  starting_time = -1L
  duration = 0L
  not_first = 0
  
  ; prepare archive_buffer
  archive_buffer_list = list()
  
  archive_buffer_entry = { stx_fsw_archive_buffer, $
    relative_time_range     : dblarr(2), $ ; relative start and end time of integration in seconds
    detector_index          : 0b, $ ; 1 - 32 (see stx_subc_params in dbase)
    pixel_index             : 0b, $ ; 0 - 11 (see stx_pixel_data)
    energy_science_channel  : 0b, $ ; [0, 31]
    counts                  : ulong(0) $ ; number of integrated counts
  }
  
  ; loop through all solo_slices
  foreach solo_packet, solo_slices do begin
    
    ; loop through all subheaders
    foreach subheader, (*(*solo_packet.source_data).dynamic_subheaders) do begin
      
      ; create a new time bin
      if (starting_time ne subheader.starting_time or duration ne subheader.duration) then begin
        
        ; attach a new time bin
        if (not_first) then begin
          fsw_archive_buffer_time_group.add, { $
            type            : 'stx_fsw_archive_buffer_time_group', $
            archive_buffer  : archive_buffer_column, $
            start_time      : start_time, $
            end_time        : end_time, $
            rcr             : rcr, $
            pixel_mask      : pixel_mask, $
            detector_mask   : detector_mask, $
            trigger         : trigger $
            ;cfl             : cfl_groupe[i] $
          }
        endif 
        not_first = 1
        
        ; set starting_time and duration to defined unique time bin values
        duration = subheader.duration
        starting_time = subheader.starting_time
        
        ; convert numbers to masks
        stx_telemetry_util_encode_decode_structure, $
          input=subheader.pixel_mask, pixel_mask=pixel_mask
        stx_telemetry_util_encode_decode_structure, $
          input=subheader.detector_mask, detector_mask=detector_mask
        
        ; get subheader information  
        rcr = subheader.rate_control_regime
;        start_time = t0
;        start_time.value.time += subheader.starting_time*100
        start_time = stx_time_add(t0, seconds=(subheader.starting_time)/10.0d)
        end_time = stx_time_add(t0, seconds=(subheader.duration+subheader.starting_time)/10.0d)
;        end_time = t0
;        end_time.value.time+= (subheader.duration+subheader.starting_time)*100
        
        trigger = ULON64ARR(16)
        trigger[0] = subheader.trigger_acc_0
        trigger[1] = subheader.trigger_acc_1
        trigger[2] = subheader.trigger_acc_2
        trigger[3] = subheader.trigger_acc_3
        trigger[4] = subheader.trigger_acc_4
        trigger[5] = subheader.trigger_acc_5
        trigger[6] = subheader.trigger_acc_6
        trigger[7] = subheader.trigger_acc_7
        trigger[8] = subheader.trigger_acc_8
        trigger[9] = subheader.trigger_acc_9
        trigger[10] = subheader.trigger_acc_10
        trigger[11] = subheader.trigger_acc_11
        trigger[12] = subheader.trigger_acc_12
        trigger[13] = subheader.trigger_acc_13
        trigger[14] = subheader.trigger_acc_14
        trigger[15] = subheader.trigger_acc_15
        
        archive_buffer_column = []
        
      endif
      
      ; create a an archive buffer entry for each count
      tmp_archive_buff = replicate(archive_buffer_entry, subheader.number_science_data_samples)
      relative_time = dblarr(2)
      relative_time[0] = stx_telemetry_util_relative_time(start_time)
      relative_time[1] = stx_telemetry_util_relative_time(end_time)
      
      ; loop through all data samples
      for i=0L,   subheader.number_science_data_samples-1 do begin
        tmp_archive_buff[i].detector_index = (*subheader.dynamic_detector_id)[i]
        tmp_archive_buff[i].pixel_index = (*subheader.dynamic_pixel_id)[i]
        tmp_archive_buff[i].energy_science_channel = (*subheader.dynamic_energy_id)[i]
        tmp_archive_buff[i].counts = (*subheader.dynamic_counts)[i]
        tmp_archive_buff[i].relative_time_range = relative_time
      endfor
        
      if(n_elements(archive_buffer_column) eq 0) then archive_buffer_column = [tmp_archive_buff] $
        else archive_buffer_column = [archive_buffer_column,tmp_archive_buff]
      
    endforeach
    
  endforeach
  
  ; add last buffer_entry to list
  fsw_archive_buffer_time_group.add, { $
    type            : 'stx_fsw_archive_buffer_time_group', $
    archive_buffer  : archive_buffer_column, $
    start_time      : start_time, $
    end_time        : end_time, $
    rcr             : rcr, $
    pixel_mask      : pixel_mask, $
    detector_mask   : detector_mask, $
    trigger         : trigger $
    }
  
end



pro stx_telemetry_prepare_structure_sd_xray_0, solo_slices=solo_slices, $
  L0_ARCHIVE_BUFFER_GROUPED=L0_ARCHIVE_BUFFER_GROUPED, $
  fsw_archive_buffer_time_group=fsw_archive_buffer_time_group, $
  _extra=extra

  ; if solo_slices is empty we write telemetry
  if n_elements(solo_slices) eq 0 then begin
    stx_telemetry_prepare_structure_sd_xray_0_write, solo_slices=solo_slices, $
      L0_ARCHIVE_BUFFER_GROUPED=L0_ARCHIVE_BUFFER_GROUPED, _extra=extra

    ; if solo_slices contains data, we are reading telemetry
  endif else begin
    stx_telemetry_prepare_structure_sd_xray_0_read, solo_slices=solo_slices, $
      fsw_archive_buffer_time_group=fsw_archive_buffer_time_group
  endelse
end

