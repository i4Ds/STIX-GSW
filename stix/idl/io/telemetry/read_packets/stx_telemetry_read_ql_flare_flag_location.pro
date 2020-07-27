;+
; :description:
;   this function reads the ql flare_flag_location specific information
;
; :categories:
;   simulation, reader, telemetry, quicklook, ql, flare_flag_location
;
; :params:
;   light_curve_packet_structure : in, required, type="stx_telemetry_packet_structure_ql_flare_flag_location"
;     the input ql flare_flag_location
;
;   tmr : in, required, type="stx_telemetry_reader"
;     an open telemerty_reader object
;
; :history:
;    27-Jan-2016 - Simon Marcin (FHNW), initial release
;-

function stx_telemetry_read_ql_flare_flag_location, solo_packet=solo_packet, tmr=tmr, _extra=extra
  ppl_require, in=solo_packet, type='stx_tmtc_solo_source_packet_header'

  ; create emtpy ql_light_curve packet
  ql_flare_flag_location_packet = stx_telemetry_packet_structure_ql_flare_flag_location()

  ; auto fill packet
  tmr->auto_read_structure, packet=ql_flare_flag_location_packet, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*']

  ; automatically override the default values with the read values
  tmr->auto_override_common_fields, solo_packet=solo_packet, data_packet=ql_flare_flag_location_packet

  ; set solo packet size to this packet header, to allow for calculating the dynamic packet size later
  ; 'stop' should never be encountered
  if(solo_packet.pkg_word_width.source_data gt 0) then stop $
  else solo_packet.pkg_word_width.source_data = ql_flare_flag_location_packet.pkg_word_width.pkg_total_bytes_fixed * 8

  ; prepare data pointers for light_curves
  ql_flare_flag_location_packet.dynamic_flare_flag = ptr_new(bytarr(ql_flare_flag_location_packet.number_of_samples)-1)
  ql_flare_flag_location_packet.dynamic_flare_location_z = ptr_new(intarr(ql_flare_flag_location_packet.number_of_samples)-1)
  ql_flare_flag_location_packet.dynamic_flare_location_y = ptr_new(intarr(ql_flare_flag_location_packet.number_of_samples)-1)
 
  ; process all entries
  for i = 0L, ql_flare_flag_location_packet.number_of_samples-1 do begin

    ; dynamic_flare_flag: read 8 bits
    val = tmr->read(size(byte(0), /type), bits=8, debug=debug, silent=silent)
    (*ql_flare_flag_location_packet.dynamic_flare_flag)[i] = val

    ; dynamic_flare_location_z: read 8 bits
    val = tmr->read(size(fix(0), /type), bits=8, debug=debug, silent=silent)
    (*ql_flare_flag_location_packet.dynamic_flare_location_z)[i] = val

    ; dynamic_flare_location_y: read 8 bits
    val = tmr->read(size(fix(0), /type), bits=8, debug=debug, silent=silent)
    (*ql_flare_flag_location_packet.dynamic_flare_location_y)[i] = val
    
    ; add dynamic size: 1 byte for each value
    solo_packet.pkg_word_width.source_data += 3 * 8

  endfor

  return, ql_flare_flag_location_packet
end