;+
; :description:
;   this routine generates the maxi report housekeeping packet
;
;   PARAMETER                               VALUE               WIDTH               NOTE
;   ----------------------------------------------------------------------------------------------
;   APID-PID                                94                                      STIX auxiliary science data processing application
;   Packet Category                         5                                       Science
;   Packet data field length - 1            variable
;   Service Type                            3                                       Science data transfer
;   Service Subtype                         25                                      Science data report
;   SSID                                    2
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
;   > HK_ASP_REF_2V5A_V                     -                   12 bits
;   > HK_ASP_REF_2V5B_V                     -                   12 bits
;   > HK_ASP_TIM01_T                        -                   12 bits
;   > HK_ASP_TIM02_T                        -                   12 bits
;   > HK_ASP_TIM03_T                        -                   12 bits
;   > HK_ASP_TIM04_T                        -                   12 bits
;   > HK_ASP_TIM05_T                        -                   12 bits
;   > HK_ASP_TIM06_T                        -                   12 bits
;   > HK_ASP_TIM07_T                        -                   12 bits
;   > HK_ASP_TIM08_T                        -                   12 bits
;   > HK_ASP_VSENSA_V                       -                   12 bits
;   > HK_ASP_VSENSB_V                       -                   12 bits
;   > HK_ATT_V                              -                   12 bits
;   > ATT_T                                 -                   12 bits
;   > HK_HV_01_16_V                         -                   12 bits
;   > HK_HV_17_32_V                         -                   12 bits
;   > DET_Q1_T                              -                   12 bits
;   > DET_Q2_T                              -                   12 bits
;   > DET_Q3_T                              -                   12 bits
;   > DET_Q4_T                              -                   12 bits
;   > HK_DPU_1V5_V                          -                   12 bits
;   > HK_REF_2V5_V                          -                   12 bits
;   > HK_DPU_2V9_V                          -                   12 bits
;   > HK_PSU_TEMP_T                         -                   12 bits
;   > HW_SW_status_1
;   >> sw_version_number                    -                    8 bits
;   >> CPU_load                             -                    7 bits
;   >> autonomous_asw_booting_status        -                    1 bit
;   >> memory_load_enable_flag              -                    1 bit
;   >> archive_memory_usage                 -                    8 bits
;   >> identifier_IDPU                      -                    1 bit
;   >> identifier_active_SpW_link           -                    1 bit
;   >> watchdog_state                       -                    1 bit
;...>> first_overrun_task                   -                    6 bits
;   > HW_SW_status_2
;   >> commands_received                    -                   16 bits
;   >> commands_rejected                    -                   16 bits
;   > HW_SW_status_3
;   >> detector_status                      -                    4 octets
;   > HW_SW_status_4
;   >> sw_status_4_spare1                   -                    3 bits
;   >> power_status_spw1                    -                    1 bit
;   >> power_status_spw2                    -                    1 bit
;   >> power_status_q4                      -                    1 bit
;   >> power_status_q3                      -                    1 bit
;   >> power_status_q2                      -                    1 bit
;   >> power_status_q1                      -                    1 bit
;   >> power_aspect_b                       -                    1 bit
;   >> power_aspect_a                       -                    1 bit
;   >> attenuator_moving_2                  -                    1 bit
;   >> attenuator_moving_1                  -                    1 bit
;   >> power_status_hv_17_32                -                    1 bit
;   >> power_status_hv_01_16                -                    1 bit
;   >> power_status_lv                      -                    1 bit
;   >> HV1_depolarization                   -                    1 bit
;   >> HV2_depolarization                   -                    1 bit
;   >> attenuator_AB_position_flag          -                    1 bit
;   >> attenuator_BC_position_flag          -                    1 bit
;   >> sw_status_4_spare2                   -                   14 bits
;   > median_value_trigger_accs             -                   24 bits
;   > max_value_trigger_accs                -                   24 bits
;   > HV_regulators_mask                    -                    2 bits
;   > sequence_count_last_TC                -                   14 bits
;   > total_attenuator_motions              -                   16 bits
;   > HK_ASP_PHOTOA0_V                      -                   16 bits
;   > HK_ASP_PHOTOA1_V                      -                   16 bits
;   > HK_ASP_PHOTOB0_V                      -                   16 bits
;   > HK_ASP_PHOTOB1_V                      -                   16 bits
;   > Attenuator_currents                   -                   16 bits
;   > HK_ATT_C                              -                   12 bits
;   > HK_DET_C                              -                   12 bits
;   > FDIR_function_status                  -                    4 octets
;
; :categories:
;   simulation, writer, telemetry, housekeeping, report, maxi
;
; :params:
;   report_maxi : in, required, type="stx_asw_hc_report_maxi"
;     the input report in case of writing telemetry
;     the output structure in case of reading telemetry
;
; :history:
;    03-Aug-2016 - Simon Marcin (FHNW), initial release
;    12-Jun-2017 - Laszlo I. Etesi (FHNW), updated with new TMTC HK spec
;-

function prepare_packet_structure_hc_regular_maxi, report_maxi=report_maxi, $
  coarse_time=coarse_time, fine_time=fine_time, _extra=extra

  ; generate empty light curves paket
  packet = stx_telemetry_packet_structure_hc_regular_maxi()

  ; copy all information to packet
  ; TODO: Refactor to util function
  tags = strlowcase(tag_names(report_maxi))

  ; definition of ignored packets for size calculation
  ignore = arr2str('^' + ['type', 'packet', 'header_.*', 'dynamic_*', 'pkg_.*', 'time'] + '$', delimiter='|')

  ;loop through all tags
  for tag_idx = 0L, n_tags(report_maxi)-1 do begin
    tag = tags[tag_idx]

    ; Skip tags with ignor definiton
    if(stregex(tags[tag_idx], ignore , /boolean)) then continue

    ; Copy the matching information into the packet
    tag_val = report_maxi.(tag_idx)
    packet.(tag_index(packet, tag)) = tag_val
  endfor
  
  stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, stx_time_obj=report_maxi.time

  return, packet

end

pro stx_telemetry_prepare_structure_hc_regular_maxi_write, solo_slices=solo_slices, report_maxi=report_maxi, _extra=extra

  ; type checking
  ppl_require, in=report_maxi, type='stx_asw_hc_regular_maxi'

  solo_source_packet_header = stx_telemetry_packet_structure_solo_source_packet_header()

  ; read how many bits are left for the source data in bits
  max_packet_size = abs(solo_source_packet_header.pkg_word_width.source_data)

  ; generate report_maxi intermediate TM packet
  source_data = prepare_packet_structure_hc_regular_maxi(report_maxi=report_maxi, $
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

  ; add general pakete information to 'SolO' slice
  solo_slices[-1].source_data = ptr_new(source_data)

  ; update all packet data field lengths
  solo_slices[-1].pkg_word_width.source_data = (*solo_slices[-1].source_data).pkg_word_width.pkg_total_bytes_fixed * 8
  solo_slices[-1].data_field_length = (*solo_slices[-1].source_data).pkg_word_width.pkg_total_bytes_fixed
  (*solo_slices[-1].source_data).header_data_field_length = solo_slices[-1].data_field_length
  
  ; add 9 (not 10?) bytes for TM Packet Data Header that is otherwise not accounted for
  solo_slices[-1].data_field_length += 9

  ; update segementation flag
  if(n_elements(solo_slices) eq 1) then solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 3
  if(n_elements(solo_slices) gt 1) then begin
    solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 1
    solo_slices[-1].SEGMENTATION_GROUPING_FLAGS = 2
  endif

end




pro stx_telemetry_prepare_structure_hc_regular_maxi_read, solo_slices=solo_slices, report_maxi=report_maxi, _extra=extra

  ; a maxi report has the size of one telemetry packet
  if n_elements(solo_slices) gt 1 then begin
    message, "There are too many telemetry slices. Only one needed for hc_regular_maxi."
  endif
  
  stx_telemetry_util_time2scet, coarse_time=solo_slices[0].coarse_time, fine_time=solo_slices[0].fine_time, $
    stx_time_obj=stx_time_obj, /reverse

  ; copy the data to a new asw_hc_regular_maxi structure
  report_maxi = stx_asw_hc_regular_maxi()
  report_maxi.time                        = stx_time_obj
  report_maxi.sw_running                  = (*solo_slices[0].source_data).sw_running
  report_maxi.instrument_number           = (*solo_slices[0].source_data).instrument_number
  report_maxi.instrument_mode             = (*solo_slices[0].source_data).instrument_mode
  report_maxi.HK_DPU_PCB_T                = (*solo_slices[0].source_data).HK_DPU_PCB_T
  report_maxi.HK_DPU_FPGA_T               = (*solo_slices[0].source_data).HK_DPU_FPGA_T
  report_maxi.HK_DPU_3V3_C                = (*solo_slices[0].source_data).HK_DPU_3V3_C
  report_maxi.HK_DPU_2V5_C                = (*solo_slices[0].source_data).HK_DPU_2V5_C
  report_maxi.HK_DPU_1V5_C                = (*solo_slices[0].source_data).HK_DPU_1V5_C
  report_maxi.HK_DPU_SPW_C                = (*solo_slices[0].source_data).HK_DPU_SPW_C
  report_maxi.HK_DPU_SPW0_V               = (*solo_slices[0].source_data).HK_DPU_SPW0_V
  report_maxi.HK_DPU_SPW1_V               = (*solo_slices[0].source_data).HK_DPU_SPW1_V
  report_maxi.HK_ASP_REF_2V5A_V           = (*solo_slices[0].source_data).HK_ASP_REF_2V5A_V
  report_maxi.HK_ASP_REF_2V5B_V           = (*solo_slices[0].source_data).HK_ASP_REF_2V5B_V
  report_maxi.HK_ASP_TIM01_T              = (*solo_slices[0].source_data).HK_ASP_TIM01_T
  report_maxi.HK_ASP_TIM02_T              = (*solo_slices[0].source_data).HK_ASP_TIM02_T
  report_maxi.HK_ASP_TIM03_T              = (*solo_slices[0].source_data).HK_ASP_TIM03_T
  report_maxi.HK_ASP_TIM04_T              = (*solo_slices[0].source_data).HK_ASP_TIM04_T
  report_maxi.HK_ASP_TIM05_T              = (*solo_slices[0].source_data).HK_ASP_TIM05_T
  report_maxi.HK_ASP_TIM06_T              = (*solo_slices[0].source_data).HK_ASP_TIM06_T
  report_maxi.HK_ASP_TIM07_T              = (*solo_slices[0].source_data).HK_ASP_TIM07_T
  report_maxi.HK_ASP_TIM08_T              = (*solo_slices[0].source_data).HK_ASP_TIM08_T
  report_maxi.HK_ASP_VSENSA_V             = (*solo_slices[0].source_data).HK_ASP_VSENSA_V
  report_maxi.HK_ASP_VSENSB_V             = (*solo_slices[0].source_data).HK_ASP_VSENSB_V
  report_maxi.HK_ATT_V                    = (*solo_slices[0].source_data).HK_ATT_V
  report_maxi.ATT_T                       = (*solo_slices[0].source_data).ATT_T
  report_maxi.HK_HV_01_16_V               = (*solo_slices[0].source_data).HK_HV_01_16_V
  report_maxi.HK_HV_17_32_V               = (*solo_slices[0].source_data).HK_HV_17_32_V
  report_maxi.DET_Q1_T                    = (*solo_slices[0].source_data).DET_Q1_T
  report_maxi.DET_Q2_T                    = (*solo_slices[0].source_data).DET_Q2_T
  report_maxi.DET_Q3_T                    = (*solo_slices[0].source_data).DET_Q3_T
  report_maxi.DET_Q4_T                    = (*solo_slices[0].source_data).DET_Q4_T
  report_maxi.HK_DPU_1V5_V                = (*solo_slices[0].source_data).HK_DPU_1V5_V
  report_maxi.HK_REF_2V5_V                = (*solo_slices[0].source_data).HK_REF_2V5_V
  report_maxi.HK_DPU_2V9_V                = (*solo_slices[0].source_data).HK_DPU_2V9_V
  report_maxi.HK_PSU_TEMP_T               = (*solo_slices[0].source_data).HK_PSU_TEMP_T
  report_maxi.sw_version_number           = (*solo_slices[0].source_data).sw_version_number
  report_maxi.CPU_load                    = (*solo_slices[0].source_data).CPU_load
  report_maxi.autonomous_asw_booting_status = (*solo_slices[0].source_data).autonomous_asw_booting_status
  report_maxi.memory_load_enable_flag     = (*solo_slices[0].source_data).memory_load_enable_flag
  report_maxi.archive_memory_usage        = (*solo_slices[0].source_data).archive_memory_usage
  report_maxi.identifier_IDPU             = (*solo_slices[0].source_data).identifier_IDPU
  report_maxi.identifier_active_SpW_link  = (*solo_slices[0].source_data).identifier_active_SpW_link 
  report_maxi.watchdog_state              = (*solo_slices[0].source_data).watchdog_state
  report_maxi.first_overrun_task          = (*solo_slices[0].source_data).first_overrun_task
  report_maxi.commands_received           = (*solo_slices[0].source_data).commands_received
  report_maxi.commands_rejected           = (*solo_slices[0].source_data).commands_rejected
  report_maxi.attenuator_moving_2         = (*solo_slices[0].source_data).attenuator_moving_2
  report_maxi.attenuator_moving_1         = (*solo_slices[0].source_data).attenuator_moving_1
  report_maxi.power_status_hv_17_32       = (*solo_slices[0].source_data).power_status_hv_17_32
  report_maxi.power_status_hv_01_16       = (*solo_slices[0].source_data).power_status_hv_01_16
  report_maxi.power_status_lv             = (*solo_slices[0].source_data).power_status_lv 
  report_maxi.detector_status             = (*solo_slices[0].source_data).detector_status
  report_maxi.sw_status_4_spare1          = (*solo_slices[0].source_data).sw_status_4_spare1
  report_maxi.power_status_spw1           = (*solo_slices[0].source_data).power_status_spw1
  report_maxi.power_status_spw2           = (*solo_slices[0].source_data).power_status_spw2
  report_maxi.power_status_q4             = (*solo_slices[0].source_data).power_status_q4
  report_maxi.power_status_q3             = (*solo_slices[0].source_data).power_status_q3
  report_maxi.power_status_q2             = (*solo_slices[0].source_data).power_status_q2
  report_maxi.power_status_q1             = (*solo_slices[0].source_data).power_status_q1
  report_maxi.power_aspect_b              = (*solo_slices[0].source_data).power_aspect_b
  report_maxi.power_aspect_a              = (*solo_slices[0].source_data).power_aspect_a
  report_maxi.HV1_depolarization          = (*solo_slices[0].source_data).HV1_depolarization
  report_maxi.HV2_depolarization          = (*solo_slices[0].source_data).HV2_depolarization
  report_maxi.attenuator_AB_position_flag = (*solo_slices[0].source_data).attenuator_AB_position_flag
  report_maxi.attenuator_BC_position_flag = (*solo_slices[0].source_data).attenuator_BC_position_flag
  report_maxi.sw_status_4_spare2           = (*solo_slices[0].source_data).sw_status_4_spare2
  report_maxi.median_value_trigger_accs   = (*solo_slices[0].source_data).median_value_trigger_accs
  report_maxi.max_value_trigger_accs      = (*solo_slices[0].source_data).max_value_trigger_accs
  report_maxi.HV_regulators_mask          = (*solo_slices[0].source_data).HV_regulators_mask
  report_maxi.sequence_count_last_TC      = (*solo_slices[0].source_data).sequence_count_last_TC
  report_maxi.total_attenuator_motions    = (*solo_slices[0].source_data).total_attenuator_motions
  report_maxi.HK_ASP_PHOTOA0_V            = (*solo_slices[0].source_data).HK_ASP_PHOTOA0_V
  report_maxi.HK_ASP_PHOTOA1_V            = (*solo_slices[0].source_data).HK_ASP_PHOTOA1_V
  report_maxi.HK_ASP_PHOTOB0_V            = (*solo_slices[0].source_data).HK_ASP_PHOTOB0_V
  report_maxi.HK_ASP_PHOTOB1_V            = (*solo_slices[0].source_data).HK_ASP_PHOTOB1_V
  report_maxi.Attenuator_currents         = (*solo_slices[0].source_data).Attenuator_currents
  report_maxi.HK_ATT_C                    = (*solo_slices[0].source_data).HK_ATT_C
  report_maxi.HK_DET_C                    = (*solo_slices[0].source_data).HK_DET_C
  report_maxi.FDIR_function_status        = (*solo_slices[0].source_data).FDIR_function_status

end



pro stx_telemetry_prepare_structure_hc_regular_maxi, solo_slices=solo_slices, $
  report_maxi=report_maxi, hc_regular_maxi=hc_regular_maxi, _extra=extra

  ; if solo_slices is empty we write telemetry
  if n_elements(solo_slices) eq 0 then begin
    stx_telemetry_prepare_structure_hc_regular_maxi_write, solo_slices=solo_slices, report_maxi=hc_regular_maxi, _extra=extra

    ; if solo_slices contains data, we are reading telemetry
  endif else begin
    stx_telemetry_prepare_structure_hc_regular_maxi_read, solo_slices=solo_slices, report_maxi=report_maxi, _extra=extra
  endelse

end


