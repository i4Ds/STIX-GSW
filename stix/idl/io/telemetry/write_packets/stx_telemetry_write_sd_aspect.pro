;+
; :DESCRIPTION:
;   this routine writes the ascpect specific information
;
; :CATEGORIES:
;   simulation, writer, telemetry, sd, aspect
;
; :PARAMS:
;   light_curve_packet_structure : in, required, type="stx_telemetry_packet_structure_aspect"
;     the aspect object
;
;   tmw : in, required, type="stx_telemetry_writer"
;     an open telemerty_writer object
;
; :HISTORY:
;    11-Mar-2017 - Nicky Hochmuth (FHNW), initial release
;-

pro stx_telemetry_write_sd_aspect, aspect_packet_structure, tmw=tmw, _extra=extra
  ppl_require, in=aspect_packet_structure, type='stx_tmtc_sd_aspect'

  ; get packet_word_with information (lenght of fields)
  pkg_word_width = aspect_packet_structure.pkg_word_width

  ; extract tags of packet and word_width
  tags_packet = strlowcase(tag_names(aspect_packet_structure))
  tags_pkg_word_width = strlowcase(tag_names(pkg_word_width))

  ; process all header fields
  for tagidx = 0L, n_elements(tags_packet)-1 do begin
    tag_packet = tags_packet[tagidx]

    ; skip type and pkg_ and dynamich_ fields/tags
    if(tag_packet eq 'type' || stregex(tag_packet, 'pkg_.*', /bool) || $
      stregex(tag_packet, 'header_.*', /bool) || stregex(tag_packet, 'dynamic_.*', /bool)) then continue

    ; get data and lenght in bits of tag
    data = aspect_packet_structure.(tagidx)
    bits = pkg_word_width.(tag_index(pkg_word_width, tag_packet))

    ; write bits
    tmw->write, data, bits=bits, debug=debug, silent=silent

  endfor

  ; process all dyamic fields
  for struct_idx = 0L, aspect_packet_structure.number_samples-1 do begin

    ;write CHA1 data
    data = (*aspect_packet_structure.dynamic_CHA1)[struct_idx]
    tmw->write, data, bits=16, debug=debug, silent=silent

    ;write CHA2 data
    data = (*aspect_packet_structure.dynamic_CHA2)[struct_idx]
    tmw->write, data, bits=16, debug=debug, silent=silent

    ;write CHB1 data
    data = (*aspect_packet_structure.dynamic_CHB1)[struct_idx]
    tmw->write, data, bits=16, debug=debug, silent=silent

    ;write CHB2 data
    data = (*aspect_packet_structure.dynamic_CHB2)[struct_idx]
    tmw->write, data, bits=16, debug=debug, silent=silent

  endfor

end