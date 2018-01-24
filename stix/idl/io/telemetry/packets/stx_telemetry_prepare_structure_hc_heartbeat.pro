;+
; :description:
;   this routine generates the heartbeat housekeeping packet
;
;   PARAMETER                               VALUE               WIDTH               NOTE
;   ----------------------------------------------------------------------------------------------
;   APID-PID                                94                                      STIX auxiliary science data processing application
;   Packet Category                         5                                       Science
;   Packet data field length - 1            variable
;   Service Type                            3                                       Science data transfer
;   Service Subtype                         25                                      Science data report
;   SSID                                    4
;   > Coarse Time (OBT)                     -                   4 octets
;   > Flare Message                         -                   1 octets
;   > X location                            -                   1 octet
;   > Y location                            -                   1 octet
;   > Flare duration                        -                   4 octets
;
; :categories:
;   simulation, writer, telemetry, housekeeping, heartbeat
;
; :params:
;   heartbeat : in, required, type="stx_sim_hc_heartbeat"
;     the input variance
;
; :history:
;    28-Jan-2016 - Simon Marcin (FHNW), initial release
;-
function prepare_packet_structure_hc_heartbeat, heartbeat=heartbeat, _extra=extra

  ; type checking
  ppl_require, in=heartbeat, type='stx_asw_hc_heartbeat'

  ; generate empty heartbeat paket
  packet = stx_telemetry_packet_structure_hc_heartbeat()

  stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, stx_time_obj=heartbeat.time

  ; fill in the data
  packet.obt_coarse_time = coarse_time
  packet.x_location = heartbeat.x_location
  packet.y_location = heartbeat.y_location
  packet.flare_duration = heartbeat.flare_duration
  packet.flare_message = heartbeat.flare_message

  ; spare bits
  packet.spare_block = uint(0)

  return, packet
end



pro stx_telemetry_prepare_structure_hc_heartbeat_write, solo_slices=solo_slices, $
  heartbeat=heartbeat, _extra=extra

  solo_source_packet_header = stx_telemetry_packet_structure_solo_source_packet_header()

  ; read how many bits are left for the source data in bits
  max_packet_size = abs(solo_source_packet_header.pkg_word_width.source_data)

  ; generate variance intermediate TM packet
  source_data = prepare_packet_structure_hc_heartbeat(heartbeat=heartbeat, _extra=extra)
  solo_source_packet_header.coarse_time = source_data.obt_coarse_time

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


pro stx_telemetry_prepare_structure_hc_heartbeat_read, solo_slices=solo_slices, $
  asw_hc_heartbeat=asw_hc_heartbeat
    
  stx_telemetry_util_time2scet, coarse_time=(*solo_slices[0].source_data).obt_coarse_time, $
  fine_time=0, stx_time_obj=stx_time_obj, /reverse
  
  ; create stx_asw_hc_heartbeat packet
  asw_hc_heartbeat = stx_asw_hc_heartbeat()
  asw_hc_heartbeat.time = stx_time_obj
  asw_hc_heartbeat.flare_message = (*solo_slices[0].source_data).flare_message
  asw_hc_heartbeat.x_location = (*solo_slices[0].source_data).x_location
  asw_hc_heartbeat.y_location  = (*solo_slices[0].source_data).y_location
  asw_hc_heartbeat.flare_duration = (*solo_slices[0].source_data).flare_duration
  asw_hc_heartbeat.attenuator_motion = (*solo_slices[0].source_data).attenuator_motion
  
end


pro stx_telemetry_prepare_structure_hc_heartbeat, solo_slices=solo_slices, $
  asw_hc_heartbeat=asw_hc_heartbeat, heartbeat=heartbeat, _extra=extra

  ; if solo_slices is empty we write telemetry
  if n_elements(solo_slices) eq 0 then begin
    stx_telemetry_prepare_structure_hc_heartbeat_write, solo_slices=solo_slices, $
      heartbeat=heartbeat, _extra=extra

    ; if solo_slices contains data, we are reading telemetry
  endif else begin
    stx_telemetry_prepare_structure_hc_heartbeat_read, solo_slices=solo_slices, $
      asw_hc_heartbeat=asw_hc_heartbeat
  endelse
end


