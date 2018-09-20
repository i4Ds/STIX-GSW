;+
; :description:
;   this routine generates the variance quicklook packet
;
;   PARAMETER                               VALUE               WIDTH               NOTE
;   ----------------------------------------------------------------------------------------------
;   APID-PID                                93                                      STIX auxiliary science data processing application
;   Packet Category                         12                                      Science
;   Packet data field length - 1            variable
;   Service Type                            21                                      Science data transfer
;   Service Subtype                         3                                       Science data report
;   SSID                                    43
;   > ...
;
; :categories:
;   simulation, writer, telemetry, quicklook,
;
; :params:
;   variance : in, required, type="stx_sim_ql_flare_list"
;     the input variance
;
; :history:
;    19-Dec-2016 - Simon Marcin (FHNW), initial release
;    19-Jun-2018 - Nicky Hochmuth (FHNW) align with ICD
;-
function prepare_packet_structure_ql_flare_list_fsw, ql_flare_list=ql_flare_list, _extra=extra

  ; type checking
  ppl_require, in=ql_flare_list, type='stx_asw_ql_flare_list'

  ; generate empty variance paket
  packet = stx_telemetry_packet_structure_ql_flare_list()

  ; fill in the data
  packet.pointer_start = ql_flare_list.pointer_start
  packet.pointer_end = ql_flare_list.pointer_end
  packet.number_of_flares = ql_flare_list.number_flares
  
  hasFlares = packet.number_of_flares gt 0
  
  ; initialize pointer and prepare arrays for data
  
  packet.dynamic_start_coarse             = ptr_new(hasFlares ? lon64arr(packet.number_of_flares) : 0)
  packet.dynamic_end_coarse               = ptr_new(hasFlares ? lon64arr(packet.number_of_flares) : 0)
  packet.dynamic_high_flag                = ptr_new(hasFlares ? uintarr(packet.number_of_flares) : 0)
  packet.dynamic_tm_volume                = ptr_new(hasFlares ? lon64arr(packet.number_of_flares) : 0)
  packet.dynamic_avg_cfl_z                = ptr_new(hasFlares ? intarr(packet.number_of_flares) : 0)
  packet.dynamic_avg_cfl_y                = ptr_new(hasFlares ? intarr(packet.number_of_flares) : 0)
  packet.dynamic_processing_status        = ptr_new(hasFlares ? bytarr(packet.number_of_flares) : 0)

  
  
  if hasFlares then begin
    ; attach values
    for i=0L,packet.number_of_flares-1 do begin
      stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
        stx_time_obj=ql_flare_list.start_coarse[i]
      (*packet.dynamic_start_coarse)[i] = coarse_time
      
      stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
        stx_time_obj=ql_flare_list.end_coarse[i]
      (*packet.dynamic_end_coarse)[i] = coarse_time
    endfor
    
    (*packet.dynamic_high_flag) = ql_flare_list.HIGH_FLAG
    (*packet.dynamic_tm_volume) = ql_flare_list.tm_volume
    (*packet.dynamic_avg_cfl_z) = ql_flare_list.avg_cfl_z
    (*packet.dynamic_avg_cfl_y) = ql_flare_list.avg_cfl_y
    (*packet.dynamic_processing_status) = ql_flare_list.processing_status
  endif

  return, packet
end



pro stx_telemetry_prepare_structure_ql_flare_list_write, ql_flare_list=ql_flare_list, $
  solo_slices=solo_slices, _extra=extra

  solo_source_packet_header = stx_telemetry_packet_structure_solo_source_packet_header()

  ; read how many bits are left for the source data in bits
  max_packet_size = abs(solo_source_packet_header.pkg_word_width.source_data)

  ; generate variance intermediate TM packet
  source_data = prepare_packet_structure_ql_flare_list_fsw(ql_flare_list=ql_flare_list, _extra=extra)
  
  stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, stx_time_obj=stx_construct_time()
  
  
  ; set the sc time of the solo_header packet
  solo_source_packet_header.coarse_time = coarse_time
  solo_source_packet_header.fine_time = fine_time

  ; copy all header information to solo packet
  ; TODO: Refactor to util function
  tags = strlowcase(tag_names(source_data))

  for tag_idx = 0L, n_tags(source_data)-1 do begin
    tag = tags[tag_idx]

    if(~stregex(tag, 'header_.*', /bool)) then continue

    ; Copy the matching header information to solo_source_packet_header
    tag_val = source_data.(tag_idx)
    solo_source_packet_header.(tag_index(solo_source_packet_header, (stregex(tag, 'header_(.*)', /extract, /subexpr))[1])) = tag_val
  endfor

  ; get the number of data samples
  n_structures = source_data.number_of_flares

  ; size of dynamic part (bits)
  dynamic_struct_size = 16*8

  ; max fitting samples per paket
  max_fitting_paket = UINT((max_packet_size - (source_data.pkg_word_width.pkg_total_bytes_fixed*8))/dynamic_struct_size)

  ; set curr_packet_size = max_packet_size in order to create a new packet
  curr_packet_size = max_packet_size
     

    ;Process ever sample with its trigger acumulator, detector index and delta_time
    for structure_idx = 0L, n_structures-1 do begin
 
      
      ; check if we have an overflow; if so -> start a new packet
      if(curr_packet_size + dynamic_struct_size gt max_packet_size) then begin
        ; copy the 'SolO' packet
        solo_slice = solo_source_packet_header
  
        ; add 'SolO' slice to 'SolO' array
        if(isvalid(solo_slices)) then solo_slices = [solo_slices, solo_slice] $
        else solo_slices = solo_slice
  
        ; set the sequence count
        solo_slices[-1].source_sequence_count = n_elements(solo_slices) - 1
  
        ; initialize the current packet size to the fixed packet length
        curr_packet_size = source_data.pkg_word_width.pkg_total_bytes_fixed
      endif
  
      ; run the following lines of code if we started a new 'SolO' packet
      if(solo_slices[-1].source_data eq ptr_new()) then begin
        ; copy the source data (prepare this 'partial' packet)
        partial_source_data = ptr_new(source_data)
  
        ; add general pakete information to 'SolO' slice
        solo_slices[-1].source_data = partial_source_data
  
        ; calculate the amount of fitting pakets
        if((n_structures-structure_idx)*dynamic_struct_size gt max_packet_size-curr_packet_size) then begin
          ; use all available space if more information than space are available
          fitting_pakets = max_fitting_paket + 1
        endif else begin
          ; just use the needed space for the last few pakets
          fitting_pakets = n_structures-structure_idx
        endelse
      
      
        if fitting_pakets gt 0 then begin
          ; initialize dynamic arrays  
          (*solo_slices[-1].source_data).dynamic_start_coarse       = ptr_new(lon64arr(fitting_pakets)-1)
          (*solo_slices[-1].source_data).dynamic_end_coarse         = ptr_new(lon64arr(fitting_pakets))
          (*solo_slices[-1].source_data).dynamic_high_flag          = ptr_new(uintarr(fitting_pakets))
          (*solo_slices[-1].source_data).dynamic_tm_volume          = ptr_new(lon64arr(fitting_pakets))
          (*solo_slices[-1].source_data).dynamic_avg_cfl_z          = ptr_new(intarr(fitting_pakets))
          (*solo_slices[-1].source_data).dynamic_avg_cfl_y          = ptr_new(intarr(fitting_pakets))
          (*solo_slices[-1].source_data).dynamic_processing_status  = ptr_new(bytarr(fitting_pakets))
        endif
        
  
        ; initialize number_of_structures
        (*solo_slices[-1].source_data).number_of_flares = 0
  
        ; update all packet data field lengths
        solo_slices[-1].pkg_word_width.source_data = (*solo_slices[-1].source_data).pkg_word_width.pkg_total_bytes_fixed * 8
        solo_slices[-1].data_field_length = (*solo_slices[-1].source_data).pkg_word_width.pkg_total_bytes_fixed
        (*solo_slices[-1].source_data).header_data_field_length = solo_slices[-1].data_field_length
        
        ; add 9 (not 10?) bytes for TM Packet Data Header that is otherwise not accounted for
        solo_slices[-1].data_field_length += 9
        
        if n_structures eq 0 then break; 
  
      endif
      
     
      
      write_pos = (structure_idx MOD (max_fitting_paket + 1))
      
      ;print, write_pos
      
      ; run the following lines of code when adding a new flare list sample to an existing packet that has space left
      if((*(*solo_slices[-1].source_data).dynamic_start_coarse)[write_pos] eq -1) then begin
        ; copy the slices to new pointers
        slice_start_coarse  =  reform((*source_data.dynamic_start_coarse)[structure_idx]) 
        slice_end_coarse    =  reform((*source_data.dynamic_end_coarse )[structure_idx])
        slice_high_flag     =  reform((*source_data.dynamic_high_flag  )[structure_idx])
        slice_tm_volume     =  reform((*source_data.dynamic_tm_volume)[structure_idx])
        slice_avg_cfl_z     =  reform((*source_data.dynamic_avg_cfl_z)[structure_idx])
        slice_avg_cfl_y     =  reform((*source_data.dynamic_avg_cfl_y)[structure_idx])
        slice_processing_status   =  reform((*source_data.dynamic_processing_status)[structure_idx])
     
        ; attach slices to paket
       (*(*solo_slices[-1].source_data).dynamic_start_coarse)[write_pos] = slice_start_coarse
       (*(*solo_slices[-1].source_data).dynamic_end_coarse  )[write_pos] = slice_end_coarse  
       (*(*solo_slices[-1].source_data).dynamic_high_flag   )[write_pos] = slice_high_flag   
       (*(*solo_slices[-1].source_data).dynamic_tm_volume   )[write_pos] = slice_tm_volume 
       (*(*solo_slices[-1].source_data).dynamic_avg_cfl_z   )[write_pos] = slice_avg_cfl_z   
       (*(*solo_slices[-1].source_data).dynamic_avg_cfl_y   )[write_pos] = slice_avg_cfl_y   
       (*(*solo_slices[-1].source_data).dynamic_processing_status )[write_pos] = slice_processing_status
       
        ; adjust current packet size
        curr_packet_size += dynamic_struct_size
        solo_slices[-1].pkg_word_width.source_data += dynamic_struct_size
        (*solo_slices[-1].source_data).header_data_field_length += dynamic_struct_size/8
        solo_slices[-1].data_field_length += dynamic_struct_size/8
  
        ; increase dynamic lenght
        (*solo_slices[-1].source_data).pkg_word_width.dynamic_start_coarse  += 32
        (*solo_slices[-1].source_data).pkg_word_width.dynamic_end_coarse    += 32
        (*solo_slices[-1].source_data).pkg_word_width.dynamic_high_flag     += 8
        (*solo_slices[-1].source_data).pkg_word_width.dynamic_tm_volume     += 32
        (*solo_slices[-1].source_data).pkg_word_width.dynamic_avg_cfl_z     += 8
        (*solo_slices[-1].source_data).pkg_word_width.dynamic_avg_cfl_y     += 8
        (*solo_slices[-1].source_data).pkg_word_width.dynamic_processing_status  += 8
  
        ; adjust number of attached structures
        (*solo_slices[-1].source_data).number_of_flares++
        
      endif
    endfor
  
  ; update segementation flag
  if(n_elements(solo_slices) eq 1) then solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 3
  if(n_elements(solo_slices) gt 1) then begin
    solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 1
    solo_slices[-1].SEGMENTATION_GROUPING_FLAGS = 2
  endif

end


pro stx_telemetry_prepare_structure_ql_flare_list_read, asw_ql_flare_list=asw_ql_flare_list, $
  solo_slices=solo_slices, _extra=extra

  ; init counter for number of structures
  total_number_of_structures=0
  pointer_start=(*solo_slices[0].source_data).pointer_start
  pointer_end=(*solo_slices[0].source_data).pointer_end

  for solo_slice_idx = 0L, (size(solo_slices, /DIM))[0]-1 do begin

    ; count total_number_of_structures
    total_number_of_structures+=(*solo_slices[solo_slice_idx].source_data).number_of_flares
    
    if (*solo_slices[solo_slice_idx].source_data).number_of_flares eq 0 then continue
    
    ;convert time
    slice_start_times=replicate(stx_time(),(*solo_slices[solo_slice_idx].source_data).number_of_flares)
    slice_end_times=replicate(stx_time(),(*solo_slices[solo_slice_idx].source_data).number_of_flares)
    
    for i=0L,(*solo_slices[solo_slice_idx].source_data).number_of_flares-1 do begin
      coarse_time=(*(*solo_slices[solo_slice_idx].source_data).dynamic_start_coarse)[i]
      stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=0, $
        stx_time_obj=stx_time_obj, /reverse
      slice_start_times[i]=stx_time_obj
      
      coarse_time=(*(*solo_slices[solo_slice_idx].source_data).dynamic_end_coarse)[i]
      
      stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=0, $
        stx_time_obj=stx_time_obj, /reverse
      slice_end_times[i]=stx_time_obj
    endfor

    ; init slices
    slice_high_flag = (*(*solo_slices[solo_slice_idx].source_data).dynamic_high_flag)
    slice_tm_volume = (*(*solo_slices[solo_slice_idx].source_data).dynamic_tm_volume)
    slice_avg_cfl_z = (*(*solo_slices[solo_slice_idx].source_data).dynamic_avg_cfl_z)
    slice_avg_cfl_y = (*(*solo_slices[solo_slice_idx].source_data).dynamic_avg_cfl_y)
    slice_processing_status = (*(*solo_slices[solo_slice_idx].source_data).dynamic_processing_status)

    ; append the slices to the final arrays
    if  solo_slice_idx eq 0 then begin
      start_times  = slice_start_times 
      end_times    = slice_end_times  
      high_flag    = slice_high_flag
      tm_volume    = slice_tm_volume
      avg_cfl_z    = slice_avg_cfl_z
      avg_cfl_y    = slice_avg_cfl_y
      processing_status = slice_processing_status

    endif else begin
      start_times  = [start_times ,slice_start_times ]
      end_times    = [end_times   ,slice_end_times   ]
      high_flag    = [high_flag   ,slice_high_flag   ]
      tm_volume    = [tm_volume ,slice_tm_volume ]
      avg_cfl_z    = [avg_cfl_z ,slice_avg_cfl_z ]
      avg_cfl_y    = [avg_cfl_y ,slice_avg_cfl_y ]
      processing_status  = [processing_status ,slice_processing_status ]
    endelse

  endfor

  ;create new stx_asw_ql_flare_list object
  if(arg_present(asw_ql_flare_list)) then begin
    asw_ql_flare_list=stx_asw_ql_flare_list(number_flares=total_number_of_structures)
    asw_ql_flare_list.pointer_start=pointer_start
    asw_ql_flare_list.pointer_end=pointer_end
    if total_number_of_structures GT 0 then begin
      asw_ql_flare_list.start_coarse = start_times
      asw_ql_flare_list.end_coarse   = end_times  
      asw_ql_flare_list.high_flag   = high_flag  
      asw_ql_flare_list.tm_volume   = tm_volume  
      asw_ql_flare_list.avg_cfl_z = avg_cfl_z
      asw_ql_flare_list.avg_cfl_y   = avg_cfl_y  
      asw_ql_flare_list.processing_status = processing_status
    endif
  endif
end


pro stx_telemetry_prepare_structure_ql_flare_list, ql_flare_list=ql_flare_list, $
  asw_ql_flare_list=asw_ql_flare_list, solo_slices=solo_slices, _extra=extra

  ; if solo_slices is empty we write telemetry
  if n_elements(solo_slices) eq 0 then begin
    stx_telemetry_prepare_structure_ql_flare_list_write, ql_flare_list=ql_flare_list, $
      solo_slices=solo_slices, _extra=extra

    ; if solo_slices contains data, we are reading telemetry
  endif else begin
    stx_telemetry_prepare_structure_ql_flare_list_read, solo_slices=solo_slices, $
      asw_ql_flare_list=asw_ql_flare_list, _extra=extra

  endelse

end

