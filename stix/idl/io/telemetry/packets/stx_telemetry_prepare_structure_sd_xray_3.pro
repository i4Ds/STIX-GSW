;+
; :description:
;   this routine generates the x-ray level 1 packet
;
;   PARAMETER                               VALUE               WIDTH               NOTE
;   ----------------------------------------------------------------------------------------------
;   APID-PID                                93                                      STIX auxiliary science data processing application
;   Packet Category                         12                                      Science
;   Packet data field length - 1            variable


;ToDO: Packet description

; :categories:
;   simulation, writer, telemetry, science_data, level 3
;
; :params:
;
; :keywords:
;
; :history:
;    06-Oct-2016 - Simon Marcin (FHNW), initial release
;-
function prepare_packet_structure_sd_xray_3_write_fsw, $
  L3_IMG_COMBINED_VISIBILITY_GROUPED=L3_IMG_COMBINED_VISIBILITY_GROUPED, $
  compression_param_k_acc=compression_param_k_acc, compression_param_m_acc=compression_param_m_acc, $
  compression_param_s_acc=compression_param_s_acc, compression_param_k_t=compression_param_k_t, $
  compression_param_m_t=compression_param_m_t, compression_param_s_t=compression_param_s_t, $
  compression_param_k_acc=compression_param_k_vis, compression_param_m_acc=compression_param_m_vis, $
  compression_param_s_acc=compression_param_s_vis, lvl_2=lvl_2, _extra=extra

  ; type checking
    if ((size(L3_IMG_COMBINED_VISIBILITY_GROUPED))[2] ne 11) then message, 'L3_IMG_COMBINED_VISIBILITY_GROUPED has to be a list of stx_fsw_visibility_time_group'
    ppl_require, in=L3_IMG_COMBINED_VISIBILITY_GROUPED[0], type='stx_fsw_visibility_time_group'
    input = L3_IMG_COMBINED_VISIBILITY_GROUPED

  default, compression_param_k_t, 5
  default, compression_param_m_t, 3
  default, compression_param_s_t, 0
  default, compression_param_k_acc, 5
  default, compression_param_m_acc, 3
  default, compression_param_s_acc, 0
  default, compression_param_k_vis, 4
  default, compression_param_m_vis, 3
  default, compression_param_s_vis, 1

  ; generate empty x-ray header paket
  packet = stx_telemetry_packet_structure_sd_xray_header()
  science_data = list()

  ; fill in the header data
  packet.ssid = 23
  packet.compression_schema_acc = ishft(compression_param_s_acc, 6) or ishft(compression_param_k_acc, 3) or compression_param_m_acc
  packet.compression_schema_t = ishft(compression_param_s_acc, 6) or ishft(compression_param_k_acc, 3) or compression_param_m_acc
  packet.number_time_samples = (size(input))[1]
  compression_schema_vis = ishft(compression_param_s_vis, 6) or ishft(compression_param_k_vis, 3) or compression_param_m_vis

  ; convert time to scet
  stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
    stx_time_obj=input[0].START_TIME
  packet.coarse_time = coarse_time
  packet.fine_time = fine_time

  ; store start_time
  start_time = (input[0].START_TIME)

  ; fill in the subheader data
  foreach buffer_slice, input do begin

    ; create a subheader packet
    sub_packet = stx_telemetry_packet_structure_sd_xray_3_subheader()

    ; fill in the subheader data
    sub_packet.delta_time = fix(round(stx_time_diff(buffer_slice.START_TIME,start_time)*10))
    sub_packet.rate_control_regime = buffer_slice.rcr
    sub_packet.compression_schema_vis = compression_schema_vis
    sub_packet.duration = fix(round(stx_time_diff(buffer_slice.END_TIME,$
      buffer_slice.START_TIME)*10))

    sub_packet.number_substructures = (size(buffer_slice.INTERVALS))[1]
    sub_packet.detector_mask=stx_mask2bits(buffer_slice.detector_mask,mask_length=32)
    sub_packet.pixel_mask=stx_mask2bits(buffer_slice.pixel_mask,mask_length=12)
    loop_D = fix(TOTAL(buffer_slice.detector_mask))
    
    detector_index = where(buffer_slice.detector_mask eq 1)

    sub_packet.trigger_acc_0 = stx_km_compress(buffer_slice.trigger[0], compression_param_k_t, compression_param_m_t, compression_param_s_t)
    sub_packet.trigger_acc_1 = stx_km_compress(buffer_slice.trigger[1], compression_param_k_t, compression_param_m_t, compression_param_s_t)
    sub_packet.trigger_acc_2 = stx_km_compress(buffer_slice.trigger[2], compression_param_k_t, compression_param_m_t, compression_param_s_t)
    sub_packet.trigger_acc_3 = stx_km_compress(buffer_slice.trigger[3], compression_param_k_t, compression_param_m_t, compression_param_s_t)
    sub_packet.trigger_acc_4 = stx_km_compress(buffer_slice.trigger[4], compression_param_k_t, compression_param_m_t, compression_param_s_t)
    sub_packet.trigger_acc_5 = stx_km_compress(buffer_slice.trigger[5], compression_param_k_t, compression_param_m_t, compression_param_s_t)
    sub_packet.trigger_acc_6 = stx_km_compress(buffer_slice.trigger[6], compression_param_k_t, compression_param_m_t, compression_param_s_t)
    sub_packet.trigger_acc_7 = stx_km_compress(buffer_slice.trigger[7], compression_param_k_t, compression_param_m_t, compression_param_s_t)
    sub_packet.trigger_acc_8 = stx_km_compress(buffer_slice.trigger[8], compression_param_k_t, compression_param_m_t, compression_param_s_t)
    sub_packet.trigger_acc_9 = stx_km_compress(buffer_slice.trigger[9], compression_param_k_t, compression_param_m_t, compression_param_s_t)
    sub_packet.trigger_acc_10 = stx_km_compress(buffer_slice.trigger[10], compression_param_k_t, compression_param_m_t, compression_param_s_t)
    sub_packet.trigger_acc_11 = stx_km_compress(buffer_slice.trigger[11], compression_param_k_t, compression_param_m_t, compression_param_s_t)
    sub_packet.trigger_acc_12 = stx_km_compress(buffer_slice.trigger[12], compression_param_k_t, compression_param_m_t, compression_param_s_t)
    sub_packet.trigger_acc_13 = stx_km_compress(buffer_slice.trigger[13], compression_param_k_t, compression_param_m_t, compression_param_s_t)
    sub_packet.trigger_acc_14 = stx_km_compress(buffer_slice.trigger[14], compression_param_k_t, compression_param_m_t, compression_param_s_t)
    sub_packet.trigger_acc_15 = stx_km_compress(buffer_slice.trigger[15], compression_param_k_t, compression_param_m_t, compression_param_s_t)

    ; initialize pointer and prepare arrays for dynamic content
    sub_packet.dynamic_e_low = ptr_new(bytarr(sub_packet.number_substructures))
    sub_packet.dynamic_e_high = ptr_new(bytarr(sub_packet.number_substructures))
    sub_packet.dynamic_spare = ptr_new(bytarr(sub_packet.number_substructures))
    sub_packet.dynamic_tot_counts = ptr_new(bytarr(loop_D, sub_packet.number_substructures))
    sub_packet.dynamic_vis_real = ptr_new(bytarr(loop_D, sub_packet.number_substructures))
    sub_packet.dynamic_vis_imaginary = ptr_new(bytarr(loop_D, sub_packet.number_substructures))

    ;Loop through all data samples
    for e_id = 0L, sub_packet.number_substructures-1 do begin

      ; attach corresponding counts and energy infsormation
      (*sub_packet.dynamic_e_low)[e_id] = buffer_slice.intervals[e_id].ENERGY_SCIENCE_CHANNEL_RANGE[0]
      ; -1 because the energy bound 32 doesn't fit in 5bits tmtc.
      (*sub_packet.dynamic_e_high)[e_id] = buffer_slice.intervals[e_id].ENERGY_SCIENCE_CHANNEL_RANGE[1]-1
      (*sub_packet.dynamic_tot_counts)[*,e_id] = stx_km_compress($
        buffer_slice.intervals[e_id].vis[detector_index].total_flux, $
        compression_param_k_acc, compression_param_m_acc, compression_param_s_acc, error=error)
      (*sub_packet.dynamic_vis_real)[*,e_id] = stx_km_compress($
        buffer_slice.intervals[e_id].vis[detector_index].REAL_PART, $
        compression_param_k_vis, compression_param_m_vis, compression_param_s_vis, error=error)
      (*sub_packet.dynamic_vis_imaginary)[*,e_id] = stx_km_compress($
        buffer_slice.intervals[e_id].vis[detector_index].IMAG_PART, $
        compression_param_k_vis, compression_param_m_vis, compression_param_s_vis, error=error)
      ; check for compression errors
      if error then message, 'ERROR: Compression parameters are bad.'

    endfor

    ; add science data
    science_data.add, sub_packet

  endforeach

  ;assign science_data to packet
  packet.dynamic_subheaders = ptr_new(science_data)
  return, packet

end


pro stx_telemetry_prepare_structure_sd_xray_3_write, $
  L3_IMG_COMBINED_VISIBILITY_GROUPED=L3_IMG_COMBINED_VISIBILITY_GROUPED, $
  compression_param_k_acc=compression_param_k_acc, compression_param_m_acc=compression_param_m_acc, $
  compression_param_s_acc=compression_param_s_acc, compression_param_k_t=compression_param_k_t, $
  compression_param_m_t=compression_param_m_t, compression_param_s_t=compression_param_s_t, $
  solo_slices=solo_slices, _extra=extra


  solo_source_packet_header = stx_telemetry_packet_structure_solo_source_packet_header()

  ; read how many bits are left for the source data in bits
  max_packet_size = abs(solo_source_packet_header.pkg_word_width.source_data)

  ; generate spectra intermediate TM packet (based on the input type)
  source_data = prepare_packet_structure_sd_xray_3_write_fsw($
    L3_IMG_COMBINED_VISIBILITY_GROUPED = L3_IMG_COMBINED_VISIBILITY_GROUPED, _extra=extra)

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
  structure_idx = 0
  first_run = 1
  
  ;Process ever subheader with its dynamic science data
  foreach subpacket, (*source_data.dynamic_subheaders) do begin

    ; get dynamic params
    loop_E = subpacket.number_substructures
    loop_D=fix(total(stx_mask2bits(subpacket.detector_mask,/reverse)))

    ; define dynamic size
    dynamic_size = (2+3* loop_D)*8 ; e_low+e_high+spare  + (tot,real,imag)*loop_D
    header = 1

    energy_idx = 0L
    while energy_idx ne -1 do begin

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

        number_science_samples = 0

      endif

      ; run the following lines of code if we have to add a new subheader
      if(energy_idx eq 0 OR n_elements(partial_source_data) eq 0) then begin

        ; copy the source data (prepare this 'partial' packet); copy it so that the fields are pre-initialized
        new_subpacket = subpacket

        ; adjust current packet size
        curr_packet_size += subpacket.pkg_word_width.pkg_total_bytes_fixed*8 ;add subheader size
        solo_slices[-1].data_field_length += subpacket.pkg_word_width.pkg_total_bytes_fixed

        ; calculate the amount of fitting science data samples
        fitting_energy_ranges = 0L
        dyn_size = 0L
        for i=energy_idx, subpacket.number_substructures-1 do begin
          dyn_size+=dynamic_size
          if(curr_packet_size+dyn_size gt max_packet_size) then break
          fitting_energy_ranges+=1
        endfor

        ; copy the slices to new pointers
        e_low_slice = (*subpacket.dynamic_e_low)[energy_idx:energy_idx+fitting_energy_ranges-1]
        e_high_slice = (*subpacket.dynamic_e_high)[energy_idx:energy_idx+fitting_energy_ranges-1]
        spare_slice = (*subpacket.dynamic_spare)[energy_idx:energy_idx+fitting_energy_ranges-1]
        tot_counts_slice = (*subpacket.dynamic_tot_counts)[*,energy_idx:energy_idx+fitting_energy_ranges-1]
        vis_slice_real = (*subpacket.dynamic_vis_real)[*,energy_idx:energy_idx+fitting_energy_ranges-1]
        vis_slice_imag = (*subpacket.dynamic_vis_imaginary)[*,energy_idx:energy_idx+fitting_energy_ranges-1]

        ; initialize dynamic arrays
        new_subpacket.dynamic_e_low = ptr_new(e_low_slice)
        new_subpacket.dynamic_e_high = ptr_new(e_high_slice)
        new_subpacket.dynamic_tot_counts = ptr_new(tot_counts_slice)
        new_subpacket.dynamic_spare = ptr_new(spare_slice)
        new_subpacket.dynamic_vis_real = ptr_new(vis_slice_real)
        new_subpacket.dynamic_vis_imaginary = ptr_new(vis_slice_imag)

        ; initialize number_of_structures
        new_subpacket.number_substructures = fitting_energy_ranges

        ; update all packet data field lengths
        ; toDo

        ; set the dynamic lenght to 0
        new_subpacket.pkg_word_width.dynamic_e_low = fitting_energy_ranges * 5
        new_subpacket.pkg_word_width.dynamic_e_high = fitting_energy_ranges * 5
        new_subpacket.pkg_word_width.dynamic_spare = fitting_energy_ranges * 6
        new_subpacket.pkg_word_width.dynamic_tot_counts = fitting_energy_ranges * loop_D * 8
        new_subpacket.pkg_word_width.dynamic_vis_real = fitting_energy_ranges *  loop_D  * 8
        new_subpacket.pkg_word_width.dynamic_vis_imaginary = fitting_energy_ranges *  loop_D  * 8
        
        ; adjust current packet size
        curr_packet_size += (dynamic_size*fitting_energy_ranges) ;add size of dynamic part
        solo_slices[-1].data_field_length += (dynamic_size*fitting_energy_ranges)/8

        ; if we reached the end of the subpacket, set idx to -1 to stop the while loop
        energy_idx += fitting_energy_ranges
        if (energy_idx eq subpacket.number_substructures) then energy_idx =-1

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



pro stx_telemetry_prepare_structure_sd_xray_3_read, fsw_visibility_time_group=fsw_visibility_time_group, $
  solo_slices=solo_slices, _extra=extra

  ; init counter for number of structures
  total_number_of_structures=0
  fsw_visibility_time_group = list()

  ; get compression params
  stx_km_compression_schema_to_params, (*solo_slices[0].source_data).compression_schema_acc, k=compression_param_k_acc, m=compression_param_m_acc, s=compression_param_s_acc
  stx_km_compression_schema_to_params, (*solo_slices[0].source_data).compression_schema_t, k=compression_param_k_t, m=compression_param_m_t, s=compression_param_s_t
 



  ; use starting time and duration as unique identifier per time bin
  starting_time = -1L
  duration = 0L
  not_first = 0

  ;ToDo: the ivs output should be changed accordingly.
  init_detector_mask = stx_mask2bits( (*(*solo_slices[0].source_data).dynamic_subheaders)[0].detector_mask,/reverse)
  interval_entry = stx_fsw_vis_image( n_detectors=fix(total( init_detector_mask )) )
  

  ; loop through all solo_slices
  foreach solo_packet, solo_slices do begin
    
    ; start time as stx_time  
    stx_telemetry_util_time2scet,coarse_time=(*solo_packet.source_data).COARSE_TIME, $
      fine_time=(*solo_packet.source_data).fine_time, stx_time_obj=t0, /reverse
  
    
    ; loop through all subheaders
    foreach subheader, (*(*solo_packet.source_data).dynamic_subheaders) do begin
      

      ; create a new time bin
      if (starting_time ne subheader.delta_time or duration ne subheader.duration) then begin        

        ; attach a new time bin
        if (not_first) then begin
          fsw_visibility_time_group.add, { $
            type            : 'stx_fsw_visibility_time_group', $
            intervals       : interval_column, $
            start_time      : start_time, $
            end_time        : end_time, $
            pixel_mask      : pixel_mask, $
            detector_mask   : detector_mask, $
            rcr             : rcr ,$
            trigger         : trigger $
          }
        endif
        not_first = 1

        ; set starting_time and duration to defined unique time bin values
        duration = subheader.duration
        starting_time = subheader.delta_time

        ; convert numbers to masks
        detector_mask= stx_mask2bits(subheader.detector_mask,/reverse)
        pixel_mask= stx_mask2bits(subheader.pixel_mask, /reverse)
        loop_D = fix(total(detector_mask))

        ; get subheader information
        rcr = subheader.rate_control_regime
        start_time = stx_time_add(t0, seconds=subheader.delta_time/10.0d)
        end_time = stx_time_add(t0, seconds=(subheader.duration+subheader.delta_time)/10.d)

        trigger = ULON64ARR(16)
        trigger[0] = stx_km_decompress(subheader.trigger_acc_0, compression_param_k_t, compression_param_m_t, compression_param_s_t)
        trigger[1] = stx_km_decompress(subheader.trigger_acc_1, compression_param_k_t, compression_param_m_t, compression_param_s_t)
        trigger[2] = stx_km_decompress(subheader.trigger_acc_2, compression_param_k_t, compression_param_m_t, compression_param_s_t)
        trigger[3] = stx_km_decompress(subheader.trigger_acc_3, compression_param_k_t, compression_param_m_t, compression_param_s_t)
        trigger[4] = stx_km_decompress(subheader.trigger_acc_4, compression_param_k_t, compression_param_m_t, compression_param_s_t)
        trigger[5] = stx_km_decompress(subheader.trigger_acc_5, compression_param_k_t, compression_param_m_t, compression_param_s_t)
        trigger[6] = stx_km_decompress(subheader.trigger_acc_6, compression_param_k_t, compression_param_m_t, compression_param_s_t)
        trigger[7] = stx_km_decompress(subheader.trigger_acc_7, compression_param_k_t, compression_param_m_t, compression_param_s_t)
        trigger[8] = stx_km_decompress(subheader.trigger_acc_8, compression_param_k_t, compression_param_m_t, compression_param_s_t)
        trigger[9] = stx_km_decompress(subheader.trigger_acc_9, compression_param_k_t, compression_param_m_t, compression_param_s_t)
        trigger[10] = stx_km_decompress(subheader.trigger_acc_10, compression_param_k_t, compression_param_m_t, compression_param_s_t)
        trigger[11] = stx_km_decompress(subheader.trigger_acc_11, compression_param_k_t, compression_param_m_t, compression_param_s_t)
        trigger[12] = stx_km_decompress(subheader.trigger_acc_12, compression_param_k_t, compression_param_m_t, compression_param_s_t)
        trigger[13] = stx_km_decompress(subheader.trigger_acc_13, compression_param_k_t, compression_param_m_t, compression_param_s_t)
        trigger[14] = stx_km_decompress(subheader.trigger_acc_14, compression_param_k_t, compression_param_m_t, compression_param_s_t)
        trigger[15] = stx_km_decompress(subheader.trigger_acc_15, compression_param_k_t, compression_param_m_t, compression_param_s_t)

        interval_column = []

      endif

      ; create a an archive buffer entry for each count
      tmp_interval = replicate(interval_entry, subheader.NUMBER_ENERGY_GROUPS)
      relative_time = dblarr(2)
      relative_time[0] = stx_telemetry_util_relative_time(start_time)
      relative_time[1] = stx_telemetry_util_relative_time(end_time)
      energy_science_channel_range = bytarr(2)

      ; loop through all data samples
      for e=0L,   subheader.NUMBER_ENERGY_GROUPS-1 do begin
        tmp_interval[e].energy_science_channel_range[0] = (*subheader.dynamic_e_low)[e]
        ;+1 as we substract 1 in the writing process.
        tmp_interval[e].energy_science_channel_range[1] = (*subheader.dynamic_e_high)[e]+1
        
        tmp_interval[e].total_flux = stx_km_decompress((*subheader.dynamic_tot_counts)[e], $
            compression_param_k_t, compression_param_m_t, compression_param_s_t)
          
        for d=0L, loop_D-1 do begin
          
          tmp_interval[e].vis[d].detector_id = (*subheader.dynamic_detector_id)[e,d]
           
          tmp_interval[e].vis[d].REAL_PART = stx_km_decompress((*subheader.dynamic_vis_real)[e,d], $
            compression_param_k_acc, compression_param_m_acc, compression_param_s_acc)
          tmp_interval[e].vis[d].IMAG_PART = stx_km_decompress((*subheader.dynamic_vis_imaginary)[e,d], $
            compression_param_k_acc, compression_param_m_acc, compression_param_s_acc)
            
          if (*subheader.dynamic_vis_real)[e,d] ne 0 OR (*subheader.dynamic_vis_imaginary)[e,d] ne 0 then begin
            print, tmp_interval[e].vis[d].REAL_PART  ,tmp_interval[e].vis[d].IMAG_PART
          endif
        endfor
        
        tmp_interval[e].relative_time_range = relative_time
        if keyword_set(lvl_2) then tmp_interval[e].sumcase = pixel_set_index
      endfor

      if(n_elements(interval_column) eq 0) then interval_column = [tmp_interval] $
      else interval_column = [interval_column,tmp_interval]

    endforeach

  endforeach

  ; add last buffer_entry to list
  fsw_visibility_time_group.add, { $
    type            : 'stx_fsw_visibility_time_group', $
    intervals       : interval_column, $
    start_time      : start_time, $
    end_time        : end_time, $
    pixel_mask      : pixel_mask, $
    detector_mask   : detector_mask, $
    rcr             : rcr ,$
    trigger         : trigger $
  }

end



pro stx_telemetry_prepare_structure_sd_xray_3, solo_slices=solo_slices, $
  L3_IMG_COMBINED_VISIBILITY_GROUPED=L3_IMG_COMBINED_VISIBILITY_GROUPED, $
  fsw_visibility_time_group=fsw_visibility_time_group, _extra=extra

  ; if solo_slices is empty we write telemetry
  if n_elements(solo_slices) eq 0 then begin
    stx_telemetry_prepare_structure_sd_xray_3_write, solo_slices=solo_slices, $
      L3_IMG_COMBINED_VISIBILITY_GROUPED=L3_IMG_COMBINED_VISIBILITY_GROUPED, $
      _extra=extra

    ; if solo_slices contains data, we are reading telemetry
  endif else begin
    stx_telemetry_prepare_structure_sd_xray_3_read, solo_slices=solo_slices, $
      fsw_visibility_time_group=fsw_visibility_time_group
  endelse
end

