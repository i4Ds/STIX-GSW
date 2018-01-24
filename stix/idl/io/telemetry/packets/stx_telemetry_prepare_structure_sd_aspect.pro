;+
; :description:
;   this routine generates the x-ray level 1 packet
;
;   PARAMETER                               VALUE               WIDTH               NOTE
;   ----------------------------------------------------------------------------------------------
;   APID-PID                                93                                      STIX auxiliary science data processing application
;   Packet Category                         12                                      Science
;   Packet data field length - 1            variable



function prepare_packet_structure_sd_aspect_write_fsw, aspect=aspect, _extra=extra

  ; type checking
   ppl_require, in=aspect, type='stx_fsw_m_aspect'


  ; generate empty x-ray header paket
  packet = stx_telemetry_packet_structure_sd_aspect_header()
  science_data = list()
 
  ; convert time to scet
  stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
    stx_time_obj=aspect.time_axis.time_start[0], reverse=reverse
  packet.coarse_time = coarse_time
  packet.fine_time = fine_time
  
  packet.summing = aspect.summing
  packet.NUMBER_SAMPLES = n_elements(aspect.CHA1)
  
  ; store start_time
  start_time = aspect.time_axis.time_start[0]
  ; initialize pointer and prepare arrays for dynamic content
  packet.dynamic_cha1 = ptr_new(uint(aspect.cha1))
  packet.dynamic_cha2 = ptr_new(uint(aspect.cha2))
  packet.dynamic_chb1 = ptr_new(uint(aspect.chb1))
  packet.dynamic_chb2 = ptr_new(uint(aspect.chb2))  
    

  return, packet

end


pro stx_telemetry_prepare_structure_sd_aspect_write, $
  aspect=aspect,  solo_slices=solo_slices,_extra=extra


  solo_source_packet_header = stx_telemetry_packet_structure_solo_source_packet_header()

  ; read how many bits are left for the source data in bits
  max_packet_size = abs(solo_source_packet_header.pkg_word_width.source_data)

  ; generate aspect intermediate TM packet (based on the input type)
  source_data = prepare_packet_structure_sd_aspect_write_fsw(aspect=aspect, _extra=extra)

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
  subheader_size = source_data.pkg_word_width.pkg_total_bytes_fixed * 8
  ;first_run = 1
  
    ; define dynamic size
    dynamic_size = 4L * 16
    header = 1

    time_idx = 0L
    while time_idx ne -1 do begin

      size_to_attach = dynamic_size
      if (header) then size_to_attach += subheader_size

      ; check if we have an overflow; if so -> start a new packet
      ; test for dynamic science part (and subheader if needed)
      if(curr_packet_size + size_to_attach gt max_packet_size) then begin

        header = 0

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
        curr_packet_size = source_data.pkg_word_width.pkg_total_bytes_fixed * 8
      endif

      ; copy the source data (prepare this 'partial' packet); copy it so that the fields are pre-initialized
      new_source_data = source_data

      ; calculate the amount of fitting science data samples
      fitting_time_ranges = 0L
      dyn_size = 0L
      for i=time_idx, source_data.number_samples-1 do begin
        dyn_size+=dynamic_size
        if(curr_packet_size+dyn_size gt max_packet_size) then break
        fitting_time_ranges+=1
      endfor

      ; copy the slices to new pointers
      DYNAMIC_CHA1_slice = (*source_data.DYNAMIC_CHA1)[time_idx:time_idx+fitting_time_ranges-1]    
      DYNAMIC_CHA2_slice = (*source_data.DYNAMIC_CHA2)[time_idx:time_idx+fitting_time_ranges-1]        
      DYNAMIC_CHB1_slice = (*source_data.DYNAMIC_CHB1)[time_idx:time_idx+fitting_time_ranges-1]        
      DYNAMIC_CHB2_slice = (*source_data.DYNAMIC_CHB2)[time_idx:time_idx+fitting_time_ranges-1]    


      ; initialize dynamic arrays
      new_source_data.DYNAMIC_CHA1 = ptr_new(DYNAMIC_CHA1_slice)
      new_source_data.DYNAMIC_CHA2 = ptr_new(DYNAMIC_CHA2_slice)
      new_source_data.DYNAMIC_CHB1 = ptr_new(DYNAMIC_CHB1_slice)
      new_source_data.DYNAMIC_CHB2 = ptr_new(DYNAMIC_CHB2_slice)
      

      ; initialize number_of_structures
      new_source_data.number_samples = fitting_time_ranges

      ; update all packet data field lengths
      ; toDo

      ; set the dynamic lenght
      new_source_data.pkg_word_width.dynamic_cha1 = fitting_time_ranges * 2 * 8
      new_source_data.pkg_word_width.dynamic_cha2 = fitting_time_ranges * 2 * 8
      new_source_data.pkg_word_width.dynamic_chb1 = fitting_time_ranges * 2 * 8
      new_source_data.pkg_word_width.dynamic_chb2 = fitting_time_ranges * 2 * 8

      
   

      ; if we reached the end of the source_data, set idx to -1 to stop the while loop
      time_idx += fitting_time_ranges
      if (time_idx eq source_data.number_samples) then time_idx =-1
      
      solo_slices[-1].source_data = ptr_new(new_source_data)
      
      ; adjust current packet size
      curr_packet_size += (dynamic_size*fitting_time_ranges) ;add size of dynamic part
      solo_slices[-1].data_field_length = curr_packet_size / 8
      ; add 9 (not 10?) bytes for TM Packet Data Header that is otherwise not accounted for
      solo_slices[-1].data_field_length += 9

    endwhile


  ; add last subheader list to last packet
  ;slice_source_data = source_data
  ;slice_source_data.number_time_samples = n_elements(partial_source_data)
  ;slice_source_data.dynamic_subheaders  = ptr_new(partial_source_data)
  ;solo_slices[-1].source_data = ptr_new(slice_source_data)

  ; update segementation flag
  if(n_elements(solo_slices) eq 1) then solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 3
  if(n_elements(solo_slices) gt 1) then begin
    solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 1
    solo_slices[-1].SEGMENTATION_GROUPING_FLAGS = 2
  endif

end



pro stx_telemetry_prepare_structure_sd_aspect_read, stx_fsw_m_aspect=stx_fsw_m_aspect, $
  solo_slices=solo_slices, _extra=extra

  ; init counter for number of structures
  total_number_of_structures=0
  fsw_spc_data_time_group = list()

  ; start time as stx_time
  stx_telemetry_util_time2scet,coarse_time=(*solo_slices[0].source_data).coarse_time, $
    fine_time=(*solo_slices[0].source_data).fine_time, stx_time_obj=t0, /reverse
  
    
  CHA1 = list()
  CHA2 = list()
  CHB1 = list()
  CHB2 = list()
    
    for solo_slice_idx = 0L, (size(solo_slices, /DIM))[0]-1 do begin
      ; count total_number_of_structures
      total_number_of_structures+=(*solo_slices[solo_slice_idx].source_data).number_samples  
      CHA1->add, *(*solo_slices[solo_slice_idx].source_data).DYNAMIC_CHA1,  /extract
      CHA2->add, *(*solo_slices[solo_slice_idx].source_data).DYNAMIC_CHA2,  /extract
      CHB1->add, *(*solo_slices[solo_slice_idx].source_data).DYNAMIC_CHB1,  /extract
      CHB2->add, *(*solo_slices[solo_slice_idx].source_data).DYNAMIC_CHB2,  /extract 
    endfor
      
  ; create time_axis
  coarse_time = (*solo_slices[0].source_data).coarse_time
  fine_time = (*solo_slices[0].source_data).fine_time
  time_axis=stx_telemetry_util_scet2axis(coarse_time=coarse_time, fine_time=fine_time, $
    nbr_structures=total_number_of_structures, $
    integration_time_in_s=(*solo_slices[0].source_data).SUMMING / 1000d)
  
  ;create new stx_asw_ql_variance object
  if(arg_present(stx_fsw_m_aspect)) then begin
    
    stx_fsw_m_aspect = stx_fsw_m_aspect($
      summing= (*solo_slices[0].source_data).SUMMING, $
      time_axis=time_axis, $
      cha1=CHA1->toarray(),$
      cha2=CHA2->toarray(),$
      chb1=CHB1->toarray(),$
      chb2=CHB2->toarray())
    
  endif

end



pro stx_telemetry_prepare_structure_sd_aspect, solo_slices=solo_slices, aspect=aspect, stx_fsw_m_aspect=stx_fsw_m_aspect, _extra=extra

  ; if solo_slices is empty we write telemetry
  if n_elements(solo_slices) eq 0 then begin
    stx_telemetry_prepare_structure_sd_aspect_write, solo_slices=solo_slices, $
      aspect=aspect, $
      _extra=extra

    ; if solo_slices contains data, we are reading telemetry
  endif else begin
    stx_telemetry_prepare_structure_sd_aspect_read, solo_slices=solo_slices, stx_fsw_m_aspect=stx_fsw_m_aspect
  endelse
end

