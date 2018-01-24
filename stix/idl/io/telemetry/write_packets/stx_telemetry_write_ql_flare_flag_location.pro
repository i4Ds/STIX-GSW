;+
; :description:
;   this routine writes the flare_flag_location specific information
;
; :categories:
;   simulation, writer, telemetry, quicklook, flare_flag_location
;
; :params:
;   light_curve_packet_structure : in, required, type="stx_telemetry_packet_structure_flare_flag_location"
;     the flare_flag_location object
;
;   tmw : in, required, type="stx_telemetry_writer"
;     an open telemerty_writer object
;
; :history:
;    27-Jan-2016 - Simon Marcin (FHNW), initial release
;-

pro stx_telemetry_write_ql_flare_flag_location, flare_flag_location_packet_structure, tmw=tmw, _extra=extra
  ppl_require, in=flare_flag_location_packet_structure, type='stx_tmtc_ql_flare_flag_location'

  ; get packet_word_with information (lenght of fields)
  pkg_word_width = flare_flag_location_packet_structure.pkg_word_width

  ; extract tags of packet and word_width
  tags_packet = strlowcase(tag_names(flare_flag_location_packet_structure))
  tags_pkg_word_width = strlowcase(tag_names(pkg_word_width))

  ; process all header fields
  for tagidx = 0L, n_elements(tags_packet)-1 do begin
    tag_packet = tags_packet[tagidx]

    ; skip type and pkg_ and dynamich_ fields/tags
    if(tag_packet eq 'type' || stregex(tag_packet, 'pkg_.*', /bool) || $
      stregex(tag_packet, 'header_.*', /bool) || stregex(tag_packet, 'dynamic_.*', /bool)) then continue

    ; get data and lenght in bits of tag
    data = flare_flag_location_packet_structure.(tagidx)
    bits = pkg_word_width.(tag_index(pkg_word_width, tag_packet))

    ; write bits
    tmw->write, data, bits=bits, debug=debug, silent=silent

  endfor

  ; process all dyamic fields
  for sample_idx = 0L, flare_flag_location_packet_structure.number_of_samples-1 do begin

    ;write flare_flag data
    data = (*flare_flag_location_packet_structure.dynamic_flare_flag)[sample_idx]
    bits = 8
    tmw->write, data, bits=bits, debug=debug, silent=silent

    ;write dynamic_flare_location_z data 
    data = (*flare_flag_location_packet_structure.dynamic_flare_location_z)[sample_idx]
    bits = 8
    tmw->write, data, bits=bits, debug=debug, silent=silent

    ;write dynamic_flare_location_y
    data = (*flare_flag_location_packet_structure.dynamic_flare_location_y)[sample_idx]
    bits = 8
    tmw->write, data, bits=bits, debug=debug, silent=silent

  endfor

end