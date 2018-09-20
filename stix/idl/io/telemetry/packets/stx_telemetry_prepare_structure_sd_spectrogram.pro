;+
; :description:
;   this routine generates the spectrogram packet
;
;   PARAMETER                               VALUE               WIDTH               NOTE
;   ----------------------------------------------------------------------------------------------
;   APID-PID                                93                                      STIX auxiliary science data processing application
;   Packet Category                         12                                      Science
;   Packet data field length - 1            variable


;ToDO: Packet description

; :categories:
;   simulation, writer, telemetry, science_data, spectrogram
;
; :params:
;
; :keywords:
;
; :history:
;    06-Oct-2016 - Simon Marcin (FHNW), initial release
;-
function prepare_packet_structure_sd_spectrogram_write_fsw, $
  L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED=L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED, $
  compression_param_k_acc=compression_param_k_acc, compression_param_m_acc=compression_param_m_acc, $
  compression_param_s_acc=compression_param_s_acc, compression_param_k_t=compression_param_k_t, $
  compression_param_m_t=compression_param_m_t, compression_param_s_t=compression_param_s_t, $
  _extra=extra

  ; type checking
  if ((size(L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED))[2] ne 11) then message, 'L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED has to be a list of stx_fsw_spc_data_time_group'
  ppl_require, in=L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED[0], type='stx_fsw_spc_data_time_group'

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
  packet.ssid = 24
  packet.compression_schema_acc = ishft(compression_param_s_acc, 6) or ishft(compression_param_k_acc, 3) or compression_param_m_acc
  packet.compression_schema_t = ishft(compression_param_s_acc, 6) or ishft(compression_param_k_acc, 3) or compression_param_m_acc
  packet.number_time_samples = 1 ; this would only be dynamic if the energy bin mask would change within a single packet

  ; convert time to scet
  stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
    stx_time_obj=L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED[0].START_TIME, reverse=reverse
  packet.coarse_time = coarse_time
  packet.fine_time = fine_time

  ; store start_time
  start_time = (L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED[0].START_TIME)

  ; there is no outer loop as we only have one subpack/subheader

    ; create a subheader packet
    sub_packet = stx_telemetry_packet_structure_sd_spectrogram_subheader()

    ; fill in the subheader data
    sub_packet.pixel_set_index = 0
    message, 'INFO: no pixelset lookup table yet.', /INFO
    sub_packet.number_samples = (size(L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED))[1]
    ;sub_packet.detector_mask=stx_mask2bits(L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED[0].detector_mask,mask_length=32)
    energy_bin_mask=bytarr(33)
    energy_bin_mask[*]= 1b
    sub_packet.energy_bin_mask=stx_mask2bits(energy_bin_mask,mask_length=33)
    message, 'INFO: no energy_bin_mask out of stx_fsw_spc_data_time_group yet.', /INFO
    sub_packet.closing_time_offset = fix(round(stx_time_diff(L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED[-1].END_TIME, start_time)*10))
    
    ; get number of energy bins
    loop_E = fix(total(energy_bin_mask)-1)

    ; initialize pointer and prepare arrays for dynamic content
    sub_packet.dynamic_delta_time = ptr_new(uintarr(sub_packet.number_samples))
    sub_packet.dynamic_trigger = ptr_new(uintarr(sub_packet.number_samples))
    sub_packet.dynamic_counts = ptr_new(uintarr(loop_E,sub_packet.number_samples))
    
    ; fill dynamic part
    time_idx = 0L
    foreach time_bin, L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED do begin
      
      time_delta = stx_time_diff(time_bin.START_TIME, start_time)*10
      (*sub_packet.dynamic_delta_time)[time_idx] = fix(round(time_delta))
      
      (*sub_packet.dynamic_trigger)[time_idx] = stx_km_compress(total(time_bin.trigger,/PRESERVE),$
        compression_param_k_t, compression_param_m_t, compression_param_s_t)
      
      for idx_E=0L, loop_E-1 do begin
        (*sub_packet.dynamic_counts)[idx_E,time_idx]=stx_km_compress(time_bin.intervals[idx_E].counts,$
          compression_param_k_acc, compression_param_m_acc, compression_param_s_acc)        
      endfor
      
      ; increment time_idx
      time_idx ++
      
    endforeach
    
    ; add science data
    science_data.add, sub_packet

  ;assign science_data to packet
  packet.dynamic_subheaders = ptr_new(science_data)
  return, packet

end


pro stx_telemetry_prepare_structure_sd_spectrogram_write, $
  L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED=L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED, $
  compression_param_k_acc=compression_param_k_acc, compression_param_m_acc=compression_param_m_acc, $
  compression_param_s_acc=compression_param_s_acc, compression_param_k_t=compression_param_k_t, $
  compression_param_m_t=compression_param_m_t, compression_param_s_t=compression_param_s_t, $
  solo_slices=solo_slices, _extra=extra


  solo_source_packet_header = stx_telemetry_packet_structure_solo_source_packet_header()

  ; read how many bits are left for the source data in bits
  max_packet_size = abs(solo_source_packet_header.pkg_word_width.source_data)

  ; generate spectra intermediate TM packet (based on the input type)
  source_data = prepare_packet_structure_sd_spectrogram_write_fsw(L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED = L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED, _extra=extra)

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


  ; set curr_packet_size = max_packet_size in order to create a new packet
  curr_packet_size = max_packet_size
  subheader_size = (*source_data.dynamic_subheaders)[0].pkg_word_width.pkg_total_bytes_fixed * 8
  first_run = 1

  ;Process every subheader with its dynamic science data
  foreach subpacket, (*source_data.dynamic_subheaders) do begin

    ; get dynamic params
    loop_E = fix(total(stx_mask2bits(subpacket.energy_bin_mask,mask_length=33, /reverse)))-1

    ; define dynamic size
    dynamic_size = (3+loop_E)*8
    header = 1

    time_idx = 0L
    while time_idx ne -1 do begin

      size_to_attach = dynamic_size
      if (header) then size_to_attach += subheader_size

      ; check if we have an overflow; if so -> start a new packet
      ; test for dynamic science part (and subheader if needed)
      if(curr_packet_size + size_to_attach gt max_packet_size) then begin

        header = 0

        ; finish the packet by assigning the lists before we create a new one
        if (not first_run) then begin
          slice_source_data = source_data
          slice_source_data.number_time_samples = n_elements(partial_source_data)
          slice_source_data.dynamic_subheaders  = ptr_new(partial_source_data)
          solo_slices[-1].source_data = ptr_new(slice_source_data)
        endif
        first_run = 0

        ; copy the 'SolO' packet
        solo_slice = solo_source_packet_header

        ; add 'SolO' slice to 'SolO' array
        if(isvalid(solo_slices)) then solo_slices = [solo_slices, solo_slice] $
        else solo_slices = [solo_slice]

        ; set the sequence count
        solo_slices[-1].source_sequence_count = n_elements(solo_slices) - 1

        ; add 10 bytes for TM Packet Data Header that is otherwise not accounted for
        ;solo_slices[-1].data_field_length = -1 + 10

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
      if(time_idx eq 0 OR n_elements(partial_source_data) eq 0) then begin

        ; copy the source data (prepare this 'partial' packet); copy it so that the fields are pre-initialized
        new_subpacket = subpacket

        ; adjust current packet size
        ; includes 2 bytes for closing_time_offset
        curr_packet_size += subpacket.pkg_word_width.pkg_total_bytes_fixed*8 ;add subheader size
        solo_slices[-1].data_field_length += subpacket.pkg_word_width.pkg_total_bytes_fixed

        ; calculate the amount of fitting science data samples
        fitting_time_ranges = 0L
        dyn_size = 0L
        for i=time_idx, subpacket.number_samples-1 do begin
          dyn_size+=dynamic_size
          if(curr_packet_size+dyn_size gt max_packet_size) then break
          fitting_time_ranges+=1
        endfor

        ; copy the slices to new pointers
        delta_time_slice = (*subpacket.dynamic_delta_time)[time_idx:time_idx+fitting_time_ranges-1]
        trigger_slice = (*subpacket.dynamic_trigger)[time_idx:time_idx+fitting_time_ranges-1]
        counts_slice = (*subpacket.dynamic_counts)[*,time_idx:time_idx+fitting_time_ranges-1]

        ; initialize dynamic arrays
        new_subpacket.dynamic_delta_time = ptr_new(delta_time_slice)
        new_subpacket.dynamic_trigger = ptr_new(trigger_slice)
        new_subpacket.dynamic_counts = ptr_new(counts_slice)

        ; initialize number_of_structures
        new_subpacket.number_samples = fitting_time_ranges

        ; update all packet data field lengths
        ; toDo

        ; set the dynamic lenght
        new_subpacket.pkg_word_width.dynamic_delta_time = fitting_time_ranges * 2 * 8
        new_subpacket.pkg_word_width.dynamic_trigger = fitting_time_ranges * 8
        new_subpacket.pkg_word_width.dynamic_counts = fitting_time_ranges * loop_E * 8

        ; adjust current packet size
        curr_packet_size += (dynamic_size*fitting_time_ranges) ;add size of dynamic part
        solo_slices[-1].data_field_length += (dynamic_size*fitting_time_ranges)/8

        ; if we reached the end of the subpacket, set idx to -1 to stop the while loop
        time_idx += fitting_time_ranges
        if (time_idx eq subpacket.number_samples) then begin
          time_idx =-1
          ; closing time offset
          new_subpacket.closing_time_offset = subpacket.closing_time_offset
        endif else begin
          ; closing time offset in case we have to split this run
          new_subpacket.closing_time_offset = (*subpacket.dynamic_delta_time)[time_idx]      
        endelse

        ; add created subheader to packet list
        partial_source_data.add, new_subpacket

      endif

    endwhile

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



pro stx_telemetry_prepare_structure_sd_spectrogram_read, fsw_spc_data_time_group=fsw_spc_data_time_group, $
  solo_slices=solo_slices, _extra=extra

  ; init counter for number of structures
  total_number_of_structures=0
  fsw_spc_data_time_group = list()

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
  not_first = 0
  energy_bin_mask_nbr = -1LL
  pixel_set_index = -1

  ; ToDo: Implement (and get) pixel set lookup table
  message, 'INFO: There is no pixel set lookup table yet. Default pixel_mask applied.', /INFO

  interval_entry = stx_fsw_spc_data()

  ; loop through all solo_slices
  foreach solo_packet, solo_slices do begin

    ; loop through all subheaders
    foreach subheader, (*(*solo_packet.source_data).dynamic_subheaders) do begin

        ; set starting_time and duration to defined unique time bin values
        energy_bin_mask_nbr = subheader.energy_bin_mask
        pixel_set_index = subheader.pixel_set_index

        ; convert numbers to masks
        energy_bin_mask=stx_mask2bits(energy_bin_mask_nbr,mask_length=33, /reverse)
        loop_E = fix(total(energy_bin_mask))-1
        energy_index = WHERE(energy_bin_mask eq 1)

        ; ToDo: Implement (and get) pixel set lookup table
        pixel_mask=bytarr(12)
        pixel_mask[*]=1b


      ; create a new list entry for each time bin
      for time_idx=0L, subheader.number_samples -1 do begin

        ; attach a new time bin
        if (not_first) then begin
          fsw_spc_data_time_group.add, { $
            type            : 'stx_fsw_spc_data_time_group', $
            intervals       : interval_column, $
            start_time      : start_time, $
            end_time        : end_time, $
            pixel_mask      : pixel_mask, $
            ;detector_mask   : detector_mask, $
            energy_bin_mask : energy_bin_mask, $
            trigger         : trigger $
          }
        endif
        not_first = 1


        ; get time information
        relative_time = dblarr(2)
        start_time = stx_time_add(t0, seconds=(*subheader.dynamic_delta_time)[time_idx]/10.0d)
        relative_time[0] = stx_telemetry_util_relative_time(start_time)
        if (time_idx eq subheader.number_samples -1) then begin
          end_time = stx_time_add(t0, seconds=subheader.closing_time_offset/10.0d)
        endif else begin
          end_time = stx_time_add(t0, seconds=(*subheader.dynamic_delta_time)[time_idx+1]/10.0d)
        endelse
        relative_time[1] = stx_telemetry_util_relative_time(end_time)
        
        ; decompress trigger information
        trigger = stx_km_decompress((*subheader.dynamic_trigger)[time_idx], $
          compression_param_k_t, compression_param_m_t, compression_param_s_t)

        ; create interval array
        interval_column = replicate(interval_entry, loop_E)
    
        ; loop through all energies
        for i=0L,   loop_E-1 do begin
          interval_column[i].energy_science_channel_range[0] = energy_index[i]
          interval_column[i].energy_science_channel_range[1] = energy_index[i+1]
          interval_column[i].counts = stx_km_decompress((*subheader.dynamic_counts)[i,time_idx], $
            compression_param_k_acc, compression_param_m_acc, compression_param_s_acc)
          interval_column[i].relative_time_range = relative_time
        endfor


      endfor

    endforeach

  endforeach

  ; add last buffer_entry to list
  fsw_spc_data_time_group.add, { $
    type            : 'stx_fsw_spc_data_time_group', $
    intervals       : interval_column, $
    start_time      : start_time, $
    end_time        : end_time, $
    pixel_mask      : pixel_mask, $
    ;detector_mask   : detector_mask, $
    energy_bin_mask : energy_bin_mask, $
    trigger         : trigger $
  }

end



pro stx_telemetry_prepare_structure_sd_spectrogram, solo_slices=solo_slices, $
  L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED=L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED, $
  fsw_spc_data_time_group=fsw_spc_data_time_group, $
  _extra=extra

  ; if solo_slices is empty we write telemetry
  if n_elements(solo_slices) eq 0 then begin
    stx_telemetry_prepare_structure_sd_spectrogram_write, solo_slices=solo_slices, $
      L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED=L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED, $
      _extra=extra

    ; if solo_slices contains data, we are reading telemetry
  endif else begin
    stx_telemetry_prepare_structure_sd_spectrogram_read, solo_slices=solo_slices, $
      fsw_spc_data_time_group=fsw_spc_data_time_group
  endelse
end

