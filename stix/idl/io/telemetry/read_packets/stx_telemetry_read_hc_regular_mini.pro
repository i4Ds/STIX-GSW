;+
; :description:
;   this routine reads the report mini specific information
;
; :categories:
;   simulation, reader, telemetry, house keeping, mini
;
; :params:
;   light_curve_packet_structure : in, required, type="stx_telemetry_packet_structure_hc_regular_mini"
;     the input report
;
;   tmr : in, required, type="stx_telemetry_reader"
;     an open telemerty_reader object
;
; :history:
;    27-Jul-2016 - Simon Marcin (FHNW), initial release
;    23-Aug-2016 - Simon Marcin (FHNW), added FDIR status mask
;-

function stx_telemetry_read_hc_regular_mini, solo_packet=solo_packet, tmr=tmr, _extra=extra
  ppl_require, in=solo_packet, type='stx_tmtc_solo_source_packet_header'

  ; create emtpy ql_light_curve packet
  hc_regular_mini_packet = stx_telemetry_packet_structure_hc_regular_mini()

  ; auto fill packet
  tmr->auto_read_structure, packet=hc_regular_mini_packet, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*']

  ; automatically override the default values with the read values
  tmr->auto_override_common_fields, solo_packet=solo_packet, data_packet=hc_regular_mini_packet

  ; set solo packet size to this packet header, to allow for calculating the dynamic packet size later
  ; 'stop' should never be encountered
  if(solo_packet.pkg_word_width.source_data gt 0) then stop $
  else solo_packet.pkg_word_width.source_data = hc_regular_mini_packet.pkg_word_width.pkg_total_bytes_fixed

  ;  if(n_structs ne 0) then message, 'Incorrect alignment of expected number of structures and actual number of structures'
  ;  if(total_data_bytes_read ne data_dynlen) then message, 'Incorrect alignment of counted total bytes and calculated total byte length'

  return, hc_regular_mini_packet
end