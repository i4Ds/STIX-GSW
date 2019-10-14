;+
; :description:
;   this routine reads the trace specific information
;
; :categories:
;   simulation, reader, telemetry, hc, trace
;
; :params:
;   solo_packet : in, required, type="stx_telemetry_packet_structure_solo_source_packet_header"
;     the input xray solo packe
;
;   tmr : in, required, type="stx_telemetry_reader"
;     an open telemerty_reader object
;
; :history:
;    31-Aug-2018 - Nicky Hochmuth (FHNW), initial release
;-

function stx_telemetry_read_hc_trace, solo_packet=solo_packet, tmr=tmr, _extra=extra
  ppl_require, in=solo_packet, type='stx_tmtc_solo_source_packet_header'

  ; create emtpy ql_light_curve packet
  sd_xray_packet = stx_telemetry_packet_structure_sd_xray_header()

  ; auto fill packet
  tmr->auto_read_structure, packet=sd_xray_packet, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*']

  ; automatically override the default values with the read values
  tmr->auto_override_common_fields, solo_packet=solo_packet, data_packet=sd_xray_packet

  ; set solo packet size to this packet header, to allow for calculating the dynamic packet size later
  ; 'stop' should never be encountered
  if(solo_packet.pkg_word_width.source_data gt 0) then stop $
  else solo_packet.pkg_word_width.source_data = sd_xray_packet.pkg_word_width.pkg_total_bytes_fixed

  ; create a list for multiple subheaders
  subheaders = list()

  ; process all subheaders
  for i = 0L, sd_xray_packet.number_time_samples-1 do begin
    ; create emtpy ql_light_curve packet
    packet = stx_telemetry_packet_structure_hc_trace()

    ; auto fill packet
    tmr->auto_read_structure, packet=packet, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*']

    ; automatically override the default values with the read values
    tmr->auto_override_common_fields, solo_packet=solo_packet, data_packet=packet

    packet.dynamic_tracetext = ptr_new(bytarr(packet.length))
    
    for b = 0L, packet.length-1 do begin
    
      val = tmr->read(1, bits=8, debug=debug, silent=silent)
      (*packet.dynamic_tracetext)[b] = val
    endfor
     
    ; add subheader to list
    subheaders.add, packet
  endfor
  
   ; attach list to sd_xray_packet
  sd_xray_packet.dynamic_subheaders = ptr_new(subheaders)
  
  return, sd_xray_packet
end