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
;   SSID                                    33
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
;-
function prepare_packet_structure_ql_flare_list_fsw, ql_flare_list=ql_flare_list, _extra=extra

  ; type checking
  ppl_require, in=ql_flare_list, type='stx_asw_ql_flare_list'

  ; generate empty variance paket
  packet = stx_telemetry_packet_structure_ql_flare_list()

  ; fill in the data
  packet.pointer_start = ql_flare_list.pointer_start
  packet.pointer_end = ql_flare_list.pointer_start
  packet.number_of_flares = n_elements(ql_flare_list.start_times)

  ; initialize pointer and prepare arrays for variance
  packet.dynamic_start_coarse  = ptr_new(lon64arr(packet.number_of_flares))
  packet.dynamic_start_fine    = ptr_new(uintarr(packet.number_of_flares))
  packet.dynamic_end_coarse    = ptr_new(lon64arr(packet.number_of_flares))
  packet.dynamic_end_fine      = ptr_new(uintarr(packet.number_of_flares))
  packet.dynamic_high_flag     = ptr_new(bytarr(packet.number_of_flares))
  packet.dynamic_nbr_packets   = ptr_new(bytarr(packet.number_of_flares))
  packet.dynamic_spare         = ptr_new(bytarr(packet.number_of_flares))
  packet.dynamic_processed     = ptr_new(bytarr(packet.number_of_flares))
  packet.dynamic_compression   = ptr_new(bytarr(packet.number_of_flares))
  packet.dynamic_transmitted   = ptr_new(bytarr(packet.number_of_flares))

  ; attach values
  for i=0L,packet.number_of_flares-1 do begin
    stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
      stx_time_obj=ql_flare_list.start_times[i]
    (*packet.dynamic_start_coarse)[i] = coarse_time
    (*packet.dynamic_start_fine)[i] = fine_time

    stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
      stx_time_obj=ql_flare_list.end_times[i]
    (*packet.dynamic_end_coarse)[i] = coarse_time
    (*packet.dynamic_end_fine)[i] = fine_time   
  endfor
  
  (*packet.dynamic_high_flag) = ql_flare_list.HIGH_FLAG
  (*packet.dynamic_nbr_packets) = ql_flare_list.NBR_PACKETS
  (*packet.dynamic_processed) = ql_flare_list.PROCESSED
  (*packet.dynamic_compression) = ql_flare_list.COMPRESSION
  (*packet.dynamic_transmitted) = ql_flare_list.TRANSMITTED

  return, packet
end



pro stx_telemetry_prepare_structure_ql_flare_list_write, ql_flare_list=ql_flare_list, $
  solo_slices=solo_slices, _extra=extra

  solo_source_packet_header = stx_telemetry_packet_structure_solo_source_packet_header()

  ; read how many bits are left for the source data in bits
  max_packet_size = abs(solo_source_packet_header.pkg_word_width.source_data)

  ; generate variance intermediate TM packet
  source_data = prepare_packet_structure_ql_flare_list_fsw(ql_flare_list=ql_flare_list, _extra=extra)

  ; set the sc time of the solo_header packet
  solo_source_packet_header.coarse_time = (*source_data.dynamic_start_coarse)[0]
  solo_source_packet_header.fine_time = (*source_data.dynamic_start_fine)[0]

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
  dynamic_struct_size = 15*8

  ; max fitting samples per paket
  max_fitting_paket = UINT((max_packet_size - (source_data.pkg_word_width.pkg_total_bytes_fixed*8))/dynamic_struct_size)

  ; set curr_packet_size = max_packet_size in order to create a new packet
  curr_packet_size = max_packet_size

  ;Process ever sample with its trigger acumulator, detector index and delta_time
  for structure_idx = 0L, n_structures-1 do begin

    ; check if we have an overflow; if so -> start a new packet
    ; test for E octets (light curves/energy binning) + 1 octet trigger + 1 octet rcr values
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
        fitting_pakets = max_fitting_paket
      endif else begin
        ; just use the needed space for the last few pakets
        fitting_pakets = n_structures-structure_idx
      endelse

      ; initialize dynamic arrays
      (*solo_slices[-1].source_data).dynamic_start_coarse  = ptr_new(lon64arr(fitting_pakets)-1)
      (*solo_slices[-1].source_data).dynamic_start_fine    = ptr_new(uintarr(fitting_pakets))
      (*solo_slices[-1].source_data).dynamic_end_coarse    = ptr_new(lon64arr(fitting_pakets))
      (*solo_slices[-1].source_data).dynamic_end_fine      = ptr_new(uintarr(fitting_pakets))
      (*solo_slices[-1].source_data).dynamic_high_flag     = ptr_new(bytarr(fitting_pakets))
      (*solo_slices[-1].source_data).dynamic_nbr_packets   = ptr_new(bytarr(fitting_pakets))
      (*solo_slices[-1].source_data).dynamic_spare         = ptr_new(bytarr(fitting_pakets))
      (*solo_slices[-1].source_data).dynamic_processed     = ptr_new(bytarr(fitting_pakets))
      (*solo_slices[-1].source_data).dynamic_compression   = ptr_new(bytarr(fitting_pakets))
      (*solo_slices[-1].source_data).dynamic_transmitted   = ptr_new(bytarr(fitting_pakets))

      ; initialize number_of_structures
      (*solo_slices[-1].source_data).number_of_flares = 0

      ; update all packet data field lengths
      solo_slices[-1].pkg_word_width.source_data = (*solo_slices[-1].source_data).pkg_word_width.pkg_total_bytes_fixed * 8
      solo_slices[-1].data_field_length = (*solo_slices[-1].source_data).pkg_word_width.pkg_total_bytes_fixed
      (*solo_slices[-1].source_data).header_data_field_length = solo_slices[-1].data_field_length
      
      ; add 9 (not 10?) bytes for TM Packet Data Header that is otherwise not accounted for
      solo_slices[-1].data_field_length += 9

    endif

    ; run the following lines of code when adding a new variance sample to an existing packet that has space left
    if((*(*solo_slices[-1].source_data).dynamic_start_coarse)[(structure_idx MOD max_fitting_paket)] eq -1) then begin
      ; copy the slices to new pointers
      slice_start_coarse  =  reform((*source_data.dynamic_start_coarse)[structure_idx]) 
      slice_start_fine    =  reform((*source_data.dynamic_start_fine )[structure_idx])
      slice_end_coarse    =  reform((*source_data.dynamic_end_coarse )[structure_idx])
      slice_end_fine      =  reform((*source_data.dynamic_end_fine   )[structure_idx])
      slice_high_flag     =  reform((*source_data.dynamic_high_flag  )[structure_idx])
      slice_nbr_packets   =  reform((*source_data.dynamic_nbr_packets)[structure_idx])
      slice_spare         =  reform((*source_data.dynamic_spare      )[structure_idx])
      slice_processed     =  reform((*source_data.dynamic_processed  )[structure_idx])
      slice_compression   =  reform((*source_data.dynamic_compression)[structure_idx])
      slice_transmitted   =  reform((*source_data.dynamic_transmitted)[structure_idx])

      ; attach slices to paket
     (*(*solo_slices[-1].source_data).dynamic_start_coarse)[(structure_idx MOD max_fitting_paket)] = slice_start_coarse
     (*(*solo_slices[-1].source_data).dynamic_start_fine  )[(structure_idx MOD max_fitting_paket)] = slice_start_fine  
     (*(*solo_slices[-1].source_data).dynamic_end_coarse  )[(structure_idx MOD max_fitting_paket)] = slice_end_coarse  
     (*(*solo_slices[-1].source_data).dynamic_end_fine    )[(structure_idx MOD max_fitting_paket)] = slice_end_fine    
     (*(*solo_slices[-1].source_data).dynamic_high_flag   )[(structure_idx MOD max_fitting_paket)] = slice_high_flag   
     (*(*solo_slices[-1].source_data).dynamic_nbr_packets )[(structure_idx MOD max_fitting_paket)] = slice_nbr_packets 
     (*(*solo_slices[-1].source_data).dynamic_spare       )[(structure_idx MOD max_fitting_paket)] = slice_spare       
     (*(*solo_slices[-1].source_data).dynamic_processed   )[(structure_idx MOD max_fitting_paket)] = slice_processed   
     (*(*solo_slices[-1].source_data).dynamic_compression )[(structure_idx MOD max_fitting_paket)] = slice_compression 
     (*(*solo_slices[-1].source_data).dynamic_transmitted )[(structure_idx MOD max_fitting_paket)] = slice_transmitted 

      ; adjust current packet size
      curr_packet_size += dynamic_struct_size
      solo_slices[-1].pkg_word_width.source_data += dynamic_struct_size
      (*solo_slices[-1].source_data).header_data_field_length += dynamic_struct_size/8
      solo_slices[-1].data_field_length += dynamic_struct_size/8

      ; increase dynamic lenght
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_start_coarse += 32
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_start_fine   += 16
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_end_coarse   += 32
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_end_fine     += 16
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_high_flag    += 8
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_nbr_packets  += 8
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_spare        += 4
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_processed    += 1
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_compression  += 2
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_transmitted  += 1

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
    
    ;convert time
    slice_start_times=replicate(stx_time(),(*solo_slices[solo_slice_idx].source_data).number_of_flares)
    slice_end_times=replicate(stx_time(),(*solo_slices[solo_slice_idx].source_data).number_of_flares)
    for i=0L,(*solo_slices[solo_slice_idx].source_data).number_of_flares-1 do begin
      coarse_time=(*(*solo_slices[solo_slice_idx].source_data).dynamic_start_coarse)[i]
      fine_time=(*(*solo_slices[solo_slice_idx].source_data).dynamic_start_fine)[i]
      stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
        stx_time_obj=stx_time_obj, /reverse
      slice_start_times[i]=stx_time_obj
      
      coarse_time=(*(*solo_slices[solo_slice_idx].source_data).dynamic_end_coarse)[i]
      fine_time=(*(*solo_slices[solo_slice_idx].source_data).dynamic_end_fine)[i]
      stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
        stx_time_obj=stx_time_obj, /reverse
      slice_end_times[i]=stx_time_obj
    endfor

    ; init slices
    slice_high_flag = (*(*solo_slices[solo_slice_idx].source_data).dynamic_high_flag)
    slice_nbr_packets = (*(*solo_slices[solo_slice_idx].source_data).dynamic_nbr_packets)
    slice_processed = (*(*solo_slices[solo_slice_idx].source_data).dynamic_processed)
    slice_compression = (*(*solo_slices[solo_slice_idx].source_data).dynamic_compression)
    slice_transmitted = (*(*solo_slices[solo_slice_idx].source_data).dynamic_transmitted)

    ; append the slices to the final arrays
    if  solo_slice_idx eq 0 then begin
      start_times  = slice_start_times 
      end_times    = slice_end_times  
      high_flag    = slice_high_flag  
      nbr_packets  = slice_nbr_packets
      processed    = slice_processed  
      compression  = slice_compression
      transmitted  = slice_transmitted
    endif else begin
      start_times  = [start_times ,slice_start_times ]
      end_times    = [end_times   ,slice_end_times   ]
      high_flag    = [high_flag   ,slice_high_flag   ]
      nbr_packets  = [nbr_packets ,slice_nbr_packets ]
      processed    = [processed   ,slice_processed   ]
      compression  = [compression ,slice_compression ]
      transmitted  = [transmitted ,slice_transmitted ]
    endelse

  endfor

  ;create new stx_asw_ql_flare_list object
  if(arg_present(asw_ql_flare_list)) then begin
    asw_ql_flare_list=stx_asw_ql_flare_list(number_flares=total_number_of_structures)
    asw_ql_flare_list.pointer_start=pointer_start
    asw_ql_flare_list.pointer_end=pointer_end
    asw_ql_flare_list.start_times = start_times
    asw_ql_flare_list.end_times   = end_times  
    asw_ql_flare_list.high_flag   = high_flag  
    asw_ql_flare_list.nbr_packets = nbr_packets
    asw_ql_flare_list.processed   = processed  
    asw_ql_flare_list.compression = compression
    asw_ql_flare_list.transmitted = transmitted
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

