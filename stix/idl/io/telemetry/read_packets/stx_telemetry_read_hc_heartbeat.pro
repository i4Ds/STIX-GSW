;+
; :description:
;   this function reads the hc heartbeat specific information
;
; :categories:
;   simulation, reader, telemetry, quicklook, hc, heartbeat
;
; :params:
;   solo_packet : in, required, type="stx_telemetry_packet_structure_solo_source_packet_header"
;     a complete input packet
;
;   tmr : in, required, type="stx_telemetry_reader"
;     an open telemerty_reader object
;
; :history:
;    08-Dec-2015 - Simon Marcin (FHNW), initial release
;-

function stx_telemetry_read_hc_heartbeat, solo_packet=solo_packet, tmr=tmr, _extra=extra
  ppl_require, in=solo_packet, type='stx_tmtc_solo_source_packet_header'

  ; create emtpy ql_variance packet
  hc_heartbeat_packet = stx_telemetry_packet_structure_hc_heartbeat()

  ; auto fill packet
  tmr->auto_read_structure, packet=hc_heartbeat_packet, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*']

  ; automatically override the default values with the read values
  tmr->auto_override_common_fields, solo_packet=solo_packet, data_packet=hc_heartbeat_packet

  ; set solo packet size to this packet header, to allow for calculating the dynamic packet size later
  ; 'stop' should never be encountered
  if(solo_packet.pkg_word_width.source_data gt 0) then stop $
  else solo_packet.pkg_word_width.source_data = hc_heartbeat_packet.pkg_word_width.pkg_total_bytes_fixed * 8

  ; extract flare_message
  stx_telemetry_util_encode_decode_structure, input=hc_heartbeat_packet.flare_message, flare_message=flare_message

  return, hc_heartbeat_packet
end