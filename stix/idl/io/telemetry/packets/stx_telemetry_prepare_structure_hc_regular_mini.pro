;+
; :description:
;   this routine generates the mini report housekeeping packet
;
;   PARAMETER                               VALUE               WIDTH               NOTE
;   ----------------------------------------------------------------------------------------------
;   APID-PID                                94                                      STIX auxiliary science data processing application
;   Packet Category                         5                                       Science
;   Packet data field length - 1            variable
;   Service Type                            3                                       Science data transfer
;   Service Subtype                         25                                      Science data report
;   SSID                                    1
;   > sw_running                            -                   1 bit
;   > instrument_number                     -                   3 bits
;   > instrument_mode                       -                   4 bits
;   > HK_DPU_PCB_T                          -                   12 bits
;   > HK_DPU_FPGA_T                         -                   12 bits
;   > HK_DPU_3V3_C                          -                   12 bits
;   > HK_DPU_2V5_C                          -                   12 bits
;   > HK_DPU_1V5_C                          -                   12 bits
;   > HK_DPU_SPW_C                          -                   12 bits
;   > HK_DPU_SPW0_V                         -                   12 bits
;   > HK_DPU_SPW1_V                         -                   12 bits
;   > HW_SW_status_1
;   >> sw_version_number                    -                   8 bits
;   >> CPU_load                             -                   7 bits
;   >> archive_memory_usage                 -                   8 bits
;   >> identifier_IDPU                      -                   1 bit
;   >> identifier_active_SpW_link           -                   1 bit
;   >> sw_status_1_spare                    -                   7 bits
;   > HW_SW_status_2
;   >> commands_rejected                    -                   16 bits
;   >> commands_received                    -                   16 bits
;   > HK_DPU_1V5_V                          -                   12 bits
;   > HK_REF_2V5_V                          -                   12 bits
;   > HK_DPU_2V9_V                          -                   12 bits
;   > HK_PSU_TEMP_T                         -                   12 bits
;   > FDIR_function_status                  -                   4 octets
;
; :categories:
;   simulation, writer, telemetry, housekeeping, report, mini
;
; :params:
;   report_mini : in, required, type="stx_sim_hc_heartbeat"
;     the input report in case of writing telemetry
;     the output structure in case of reading telemetry
;
; :history:
;    17-Feb-2016 - Simon Marcin (FHNW), initial release
;    27.Jul-2016 - Simon Marcin (FHNW), implemented writer and reader
;-

function prepare_packet_structure_hc_regular_mini, report_mini=report_mini, $
  coarse_time=coarse_time, fine_time=fine_time, _extra=extra

  ; generate empty light curves paket
  packet = stx_telemetry_packet_structure_hc_regular_mini()

  ; copy all information to packet
  ; TODO: Refactor to util function
  tags = strlowcase(tag_names(report_mini))

  ; definition of ignored packets for size calculation
  ignore = arr2str('^' + ['type', 'packet', 'header_.*', 'dynamic_*', 'pkg_.*', 'time'] + '$', delimiter='|')

  ;loop through all tags
  for tag_idx = 0L, n_tags(report_mini)-1 do begin
    tag = tags[tag_idx]

    ; Skip tags with ignor definiton
    if(stregex(tags[tag_idx], ignore , /boolean)) then continue
    
    ; Copy the matching information into the packet
    tag_val = report_mini.(tag_idx)
    if(stregex(tags[tag_idx], 'fdir_function_status' , /boolean)) then tag_val = stx_mask2bits(tag_val)
    packet.(tag_index(packet, tag)) = tag_val
  endfor
  
  stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, stx_time_obj=report_mini.time
 
  return, packet

end

pro stx_telemetry_prepare_structure_hc_regular_mini_write, solo_slices=solo_slices, report_mini=report_mini, _extra=extra

  ; type checking
  ppl_require, in=report_mini, type='stx_asw_hc_regular_mini'

  solo_source_packet_header = stx_telemetry_packet_structure_solo_source_packet_header()

  ; read how many bits are left for the source data in bits
  max_packet_size = abs(solo_source_packet_header.pkg_word_width.source_data)

  ; generate report_mini intermediate TM packet
  source_data = prepare_packet_structure_hc_regular_mini(report_mini=report_mini, $
    coarse_time=coarse_time, fine_time=fine_time, _extra=extra)

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
  
  ; set time of SC packet
  solo_source_packet_header.coarse_time = coarse_time
  solo_source_packet_header.fine_time = fine_time

  ; add packet to an array in order it's consistant with bigger packets
  solo_slices = [solo_source_packet_header]

  ; set the sequence count
  solo_slices[-1].source_sequence_count = 0

  ; add 9 (not 10?) bytes for TM Packet Data Header that is otherwise not accounted for
  solo_slices[-1].data_field_length = 9

  ; add general pakete information to 'SolO' slice
  solo_slices[-1].source_data = ptr_new(source_data)

  ; update all packet data field lengths
  solo_slices[-1].pkg_word_width.source_data = (*solo_slices[-1].source_data).pkg_word_width.pkg_total_bytes_fixed * 8
  solo_slices[-1].data_field_length += (*solo_slices[-1].source_data).pkg_word_width.pkg_total_bytes_fixed
  (*solo_slices[-1].source_data).header_data_field_length = solo_slices[-1].data_field_length


  ; update segementation flag
  if(n_elements(solo_slices) eq 1) then solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 3
  if(n_elements(solo_slices) gt 1) then begin
    solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 1
    solo_slices[-1].SEGMENTATION_GROUPING_FLAGS = 2
  endif

end




pro stx_telemetry_prepare_structure_hc_regular_mini_read, solo_slices=solo_slices, report_mini=report_mini, _extra=extra

  ; a mini report has the size of one telemetry packet
  if n_elements(solo_slices) gt 1 then begin
    message, "There are too many telemetry slices. Only one needed for hc_regular_mini."
  endif
  
  ; convert fdir_status_mask
  stx_telemetry_util_encode_decode_structure, $
    input=(*solo_slices[0].source_data).FDIR_function_status, fdir_status_mask=fdir_status_mask
  
  ;subseconds_seconds_from_scet, solo_slices[0].sc_time, seconds, subseconds  
  stx_telemetry_util_time2scet, coarse_time=solo_slices[0].coarse_time, fine_time=solo_slices[0].fine_time, $
    stx_time_obj=stx_time_obj, /reverse

  
  ; copy the data to a new asw_hc_regular_mini structure
  report_mini = stx_asw_hc_regular_mini() 
  report_mini.time                       = stx_time_obj
  report_mini.instrument_mode            = (*solo_slices[0].source_data).instrument_mode           
  report_mini.HK_DPU_PCB_T               = (*solo_slices[0].source_data).HK_DPU_PCB_T              
  report_mini.HK_DPU_FPGA_T              = (*solo_slices[0].source_data).HK_DPU_FPGA_T             
  report_mini.HK_DPU_3V3_C               = (*solo_slices[0].source_data).HK_DPU_3V3_C              
  report_mini.HK_DPU_2V5_C               = (*solo_slices[0].source_data).HK_DPU_2V5_C              
  report_mini.HK_DPU_1V5_C               = (*solo_slices[0].source_data).HK_DPU_1V5_C              
  report_mini.HK_DPU_SPW_C               = (*solo_slices[0].source_data).HK_DPU_SPW_C              
  report_mini.HK_DPU_SPW0_V              = (*solo_slices[0].source_data).HK_DPU_SPW0_V             
  report_mini.HK_DPU_SPW1_V              = (*solo_slices[0].source_data).HK_DPU_SPW1_V             
  report_mini.sw_version_number          = (*solo_slices[0].source_data).sw_version_number         
  report_mini.CPU_load                   = (*solo_slices[0].source_data).CPU_load                  
  report_mini.archive_memory_usage       = (*solo_slices[0].source_data).archive_memory_usage      
  report_mini.identifier_IDPU            = (*solo_slices[0].source_data).identifier_IDPU           
  report_mini.identifier_active_SpW_link = (*solo_slices[0].source_data).identifier_active_SpW_link
  report_mini.commands_rejected          = (*solo_slices[0].source_data).commands_rejected         
  report_mini.commands_received          = (*solo_slices[0].source_data).commands_received         
  report_mini.HK_DPU_1V5_V               = (*solo_slices[0].source_data).HK_DPU_1V5_V              
  report_mini.HK_REF_2V5_V               = (*solo_slices[0].source_data).HK_REF_2V5_V              
  report_mini.HK_DPU_2V9_V               = (*solo_slices[0].source_data).HK_DPU_2V9_V              
  report_mini.HK_PSU_TEMP_T              = (*solo_slices[0].source_data).HK_PSU_TEMP_T     
  report_mini.FDIR_function_status       =  fdir_status_mask
  report_mini.FDIR_temp_status           = (*solo_slices[0].source_data).FDIR_temp_status
  report_mini.FDIR_voltage_status        = (*solo_slices[0].source_data).FDIR_voltage_status
  report_mini.FDIR_current_status        = (*solo_slices[0].source_data).FDIR_current_status
  report_mini.executed_tc_packets        = (*solo_slices[0].source_data).executed_tc_packets
  report_mini.sent_tc_packets            = (*solo_slices[0].source_data).sent_tc_packets
  report_mini.failed_tm_generations      = (*solo_slices[0].source_data).failed_tm_generations

end



pro stx_telemetry_prepare_structure_hc_regular_mini, solo_slices=solo_slices, $
  report_mini=report_mini, hc_regular_mini=hc_regular_mini, _extra=extra

  ; if solo_slices is empty we write telemetry
  if n_elements(solo_slices) eq 0 then begin
    stx_telemetry_prepare_structure_hc_regular_mini_write, solo_slices=solo_slices, report_mini=hc_regular_mini, _extra=extra

    ; if solo_slices contains data, we are reading telemetry
  endif else begin
    stx_telemetry_prepare_structure_hc_regular_mini_read, solo_slices=solo_slices, report_mini=report_mini, _extra=extra
  endelse
  
end


