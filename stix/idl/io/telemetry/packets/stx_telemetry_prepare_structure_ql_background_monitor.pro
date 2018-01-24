;+
; :description:
;   this routine generates the background_monitor quicklook packet
;
;   PARAMETER                               VALUE               WIDTH               NOTE
;   ----------------------------------------------------------------------------------------------
;   APID-PID                                93                                      STIX auxiliary science data processing application
;   Packet Category                         12                                      Science
;   Packet data field length - 1            variable
;   Service Type                            21                                      Science data transfer
;   Service Subtype                         3                                       Science data report
;   SSID                                    31
;   > Coarse Time (SCET)                    -                   4 octets
;   > Fine Time (SCET)                      -                   2 octets
;   > Integration Time                      -                   1 octet
;   > Energy Bin Mask                       -                   33 bits             --> E Masks
;   > Spare block                           -                   3 bits
;   > Number of Structures (N)              -                   2 octet
;   > Background
;   > > Background                                              E octets            per sample (ExN)
;   > > Live Time                                               1 octet             per sample (1xN)
;
; :categories:
;   simulation, writer, telemetry, quicklook, background
;
; :params:
;   background_monitor : in, required, type="stx_fsw_ql_bkgd_monitor"
;     the input light curves
;
; :history:
;    10-Dec-2015 - Simon Marcin (FHNW), initial release
;    19-Sep-2016 - Simon Marcin (FHNW), added read functionality and implemented fsw-writer
;-
function prepare_packet_structure_ql_background_monitor_write_fsw, ql_background_monitor=ql_background_monitor, $
  compression_param_k_bg=compression_param_k_bg, compression_param_m_bg=compression_param_m_bg, $
  compression_param_s_bg=compression_param_s_bg, compression_param_k_t=compression_param_k_t, $
  compression_param_m_t=compression_param_m_t, compression_param_s_t=compression_param_s_t, $
  number_energy_bins=number_energy_bins, _extra=extra

  ; type checking
  ppl_require, in=ql_background_monitor, type='stx_fsw_m_background'

  default, compression_param_k_t, 5
  default, compression_param_m_t, 3
  default, compression_param_s_t, 0
  default, compression_param_k_bg, 5
  default, compression_param_m_bg, 3
  default, compression_param_s_bg, 0

  ; generate empty background_monitor paket
  packet = stx_telemetry_packet_structure_ql_background_monitor()

  ; convert time to scet
  stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
    stx_time_obj=ql_background_monitor.TIME_AXIS.TIME_START[0]
  packet.coarse_time = coarse_time
  packet.fine_time = fine_time
  packet.integration_time = ql_background_monitor.TIME_AXIS.duration[0] *10
  
  ; s, kkk, mmm
  packet.compression_schema_background = stx_km_compression_params_to_schema($
    compression_param_k_bg,compression_param_m_bg,compression_param_s_bg)
  packet.compression_schema_trigger = stx_km_compression_params_to_schema($
    compression_param_k_t,compression_param_m_t,compression_param_s_t)

  ; the energy_bin mask is converted to a number
  packet.energy_bin_mask = stx_mask2bits(stx_energy_axis_to_mask(ql_background_monitor.energy_axis),mask_length=33)
  number_energy_bins = n_elements(ql_background_monitor.energy_axis.LOW_FSW_IDX)
  packet.number_of_energies = number_energy_bins

  ; number of structures
  packet.number_of_triggers = n_elements(ql_background_monitor.TIME_AXIS.duration)
  packet.dynamic_nbr_of_data_points = n_elements(ql_background_monitor.TIME_AXIS.duration)
  
  ; initialize pointer and prepare arrays for background and live time values
  packet.dynamic_background = ptr_new(bytarr(number_energy_bins,packet.dynamic_nbr_of_data_points))
  packet.dynamic_trigger_accumulator = ptr_new(bytarr(packet.dynamic_nbr_of_data_points))
  
  ; compress and attach values
  (*packet.dynamic_trigger_accumulator) = stx_km_compress(ql_background_monitor.TRIGGERS, $
    compression_param_k_t, compression_param_m_t, compression_param_s_t)

  (*packet.dynamic_background) = stx_km_compress(ulong64(ql_background_monitor.BACKGROUND), $
    compression_param_k_bg, compression_param_m_bg, compression_param_s_bg)
  
  return, packet
end


pro stx_telemetry_prepare_structure_ql_background_monitor_write, solo_slices=solo_slices, $
  ql_background_monitor=ql_background_monitor, $
  ql_lt_background_monitor=ql_lt_background_monitor, _extra=extra

  solo_source_packet_header = stx_telemetry_packet_structure_solo_source_packet_header()

  ; read how many bits are left for the source data in bits
  max_packet_size = abs(solo_source_packet_header.pkg_word_width.source_data)

  ; generate background intermediate TM packet
  number_energy_bins=0
  source_data = prepare_packet_structure_ql_background_monitor_write_fsw($
    ql_background_monitor=ql_background_monitor, $
    ql_lt_background_monitor=ql_lt_background_monitor,$
    number_energy_bins=number_energy_bins, _extra=extra)

  ; set the sc time of the solo_header packet
  solo_source_packet_header.coarse_time = source_data.coarse_time
  solo_source_packet_header.fine_time = source_data.fine_time

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

  ; get the number of background_monitor
  n_structures = source_data.dynamic_nbr_of_data_points

  ; E octets (background/energy binning) + 1 octet live_time + 1 octet nbr_energies (E)
  dynamic_struct_size = (number_energy_bins + 1) * 8

  ; max fitting background_monitor per paket
  static_packet_size = (source_data.pkg_word_width.pkg_total_bytes_fixed + (number_energy_bins*2))*8
  max_fitting_paket = UINT((max_packet_size - static_packet_size)/dynamic_struct_size)

  ; set curr_packet_size = max_packet_size in order to create a new packet
  curr_packet_size = max_packet_size

  ;Process ever background_monitor with its trigger acumulator and rcr values
  for structure_idx = 0L, n_structures-1 do begin

    ; check if we have an overflow; if so -> start a new packet
    ; test for E octets (background/energy binning) + 1 octet live_time
    if(curr_packet_size + dynamic_struct_size gt max_packet_size) then begin
      ; copy the 'SolO' packet
      solo_slice = solo_source_packet_header

      ; add 'SolO' slice to 'SolO' array
      if(isvalid(solo_slices)) then solo_slices = [solo_slices, solo_slice] $
      else solo_slices = solo_slice

      ; set the sequence count
      solo_slices[-1].source_sequence_count = n_elements(solo_slices) - 1

      ; add 9 (not 10?) bytes for TM Packet Data Header that is otherwise not accounted for
      solo_slices[-1].data_field_length = 9

      ; initialize the current packet size to the fixed packet length
      curr_packet_size = static_packet_size
    endif

    ; run the following lines of code if we started a new 'SolO' packet
    if(solo_slices[-1].source_data eq ptr_new()) then begin
      ; copy the source data (prepare this 'partial' packet)
      partial_source_data = ptr_new(source_data)

      ; add general pakete information to 'SolO' slice
      solo_slices[-1].source_data = partial_source_data

      ; calculate the amount of fitting pakets
      if((n_structures-structure_idx)*dynamic_struct_size gt max_packet_size-curr_packet_size) then begin
        ; use all available space if more samples than space are available
        fitting_pakets = max_fitting_paket
      endif else begin
        ; just use the needed space for the last few pakets
        fitting_pakets = CEIL(n_structures-structure_idx)
      endelse

      ; initialize dynamic arrays
      (*solo_slices[-1].source_data).dynamic_background = ptr_new(bytarr(number_energy_bins,fitting_pakets)-1)
      (*solo_slices[-1].source_data).dynamic_trigger_accumulator = ptr_new(bytarr(fitting_pakets)-1)

      ; initialize number_of_structures
      (*solo_slices[-1].source_data).dynamic_nbr_of_data_points = 0
      (*solo_slices[-1].source_data).number_of_triggers = 0

      ; update all packet data field lengths
      solo_slices[-1].pkg_word_width.source_data = static_packet_size
      solo_slices[-1].data_field_length += static_packet_size/8
      (*solo_slices[-1].source_data).header_data_field_length = solo_slices[-1].data_field_length

      ; set the dynamic lenght to 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_background = 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_trigger_accumulator = 0
      
    endif

    ; run the following lines of code when adding a new background_monitor to an existing packet that has space left
    if((*(*solo_slices[-1].source_data).dynamic_background)[0,(structure_idx MOD max_fitting_paket)] eq -1) then begin
      ; copy the slices to new pointers
      background_slice = reform((*source_data.dynamic_background)[0:number_energy_bins-1,structure_idx])
      trigger_slice = reform((*source_data.dynamic_trigger_accumulator)[structure_idx])

      ; attach slices to paket
      (*(*solo_slices[-1].source_data).dynamic_background)[0:number_energy_bins-1s,(structure_idx MOD max_fitting_paket)] = background_slice
      (*(*solo_slices[-1].source_data).dynamic_trigger_accumulator)[(structure_idx MOD max_fitting_paket)] = trigger_slice

      ; adjust current packet size
      curr_packet_size += dynamic_struct_size
      solo_slices[-1].pkg_word_width.source_data += dynamic_struct_size * 8
      (*solo_slices[-1].source_data).header_data_field_length += dynamic_struct_size
      solo_slices[-1].data_field_length += dynamic_struct_size / 8

      ; increase dynamic lenght 
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_background += number_energy_bins * 8
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_trigger_accumulator += 8

      ; adjust number of attached structures
      (*solo_slices[-1].source_data).dynamic_nbr_of_data_points++
      (*solo_slices[-1].source_data).number_of_triggers++

    endif
  endfor

  ; update segementation flag
  if(n_elements(solo_slices) eq 1) then solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 3
  if(n_elements(solo_slices) gt 1) then begin
    solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 1
    solo_slices[-1].SEGMENTATION_GROUPING_FLAGS = 2
  endif 

end



pro stx_telemetry_prepare_structure_ql_background_monitor_read, solo_slices=solo_slices, $
  asw_ql_background_monitor=asw_ql_background_monitor, _extra=extra
  
  ; convert numbers to masks (only for the first packet) 
  stx_telemetry_util_encode_decode_structure, $
    input=(*solo_slices[0].source_data).energy_bin_mask, $
    energy_bin_mask=energy_bin_mask, number_energy_bins=number_energy_bins
  
  ; init counter for number of structures
  total_number_of_structures=0

  ; get compression params
  stx_km_compression_schema_to_params, (*solo_slices[0].source_data).compression_schema_trigger, k=compression_param_k_t, m=compression_param_m_t, s=compression_param_s_t
  stx_km_compression_schema_to_params, (*solo_slices[0].source_data).compression_schema_background, k=compression_param_k_bg, m=compression_param_m_bg, s=compression_param_s_bg
  
  ; get energy axis
  energy_axis=stx_construct_energy_axis(select=(where(energy_bin_mask eq 1)))
  
  ; reading the solo_sclices and update the STX_ASW_QL_BACKGROUND_MONITOR packet
  for solo_slice_idx = 0L, (size(solo_slices, /DIM))[0]-1 do begin

    ; count total_number_of_structures
    total_number_of_structures+=(*solo_slices[solo_slice_idx].source_data).number_of_triggers

    ; init slices
    slice_background = stx_km_decompress(ulong((*(*solo_slices[solo_slice_idx].source_data).dynamic_background)),$
      compression_param_k_bg, compression_param_m_bg, compression_param_s_bg)


    slice_triggers = stx_km_decompress(ulong((*(*solo_slices[solo_slice_idx].source_data).dynamic_trigger_accumulator)),$
      compression_param_k_t, compression_param_m_t, compression_param_s_t)

    ; append the slices to the final arrays
    if  solo_slice_idx eq 0 then begin
      background = slice_background
      triggers = slice_triggers
    endif else begin
      background = [counts, slice_background]
      triggers = [triggers, slice_triggers]
    endelse

  endfor  
  
  ; create time_axis
  stx_telemetry_util_time2scet,coarse_time=(*solo_slices[0].source_data).coarse_time, $
    fine_time=(*solo_slices[0].source_data).fine_time, stx_time_obj=t0, /reverse
  seconds=lindgen(total_number_of_structures+1)*((*solo_slices[0].source_data).integration_time/10.0)
  axis=stx_time_add(t0,seconds=seconds)
  time_axis=stx_construct_time_axis(axis)
  
  ;create new asw_ql_background_monitor object
  if(arg_present(asw_ql_background_monitor)) then begin
    asw_ql_background_monitor=stx_asw_ql_background_monitor(total_number_of_structures,$
      number_energy_bins)
    asw_ql_background_monitor.time_axis=time_axis
    asw_ql_background_monitor.energy_axis=energy_axis
    asw_ql_background_monitor.background=background
    asw_ql_background_monitor.triggers=triggers
  endif
    
end
  

pro stx_telemetry_prepare_structure_ql_background_monitor, solo_slices=solo_slices, $
  asw_ql_background_monitor=asw_ql_background_monitor, _extra=extra

  ; if solo_slices is empty we write telemetry
  if n_elements(solo_slices) eq 0 then begin
    stx_telemetry_prepare_structure_ql_background_monitor_write, solo_slices=solo_slices, $
       ql_background_monitor=ql_background_monitor, _extra=extra

  ; if solo_slices contains data, we are reading telemetry
  endif else begin
    stx_telemetry_prepare_structure_ql_background_monitor_read, solo_slices=solo_slices, $
      asw_ql_background_monitor=asw_ql_background_monitor, _extra=extra
  endelse
  
end

  
