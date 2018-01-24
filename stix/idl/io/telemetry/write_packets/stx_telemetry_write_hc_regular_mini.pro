;+
; :description:
;   this routine writes the mini report (house keeping) specific information
;
; :categories:
;   simulation, writer, telemetry, house keeping, mini
;
; :params:
;   report_mini_packet_structure : in, required, type="stx_telemetry_packet_structure_hc_regular_mini"
;     the input packet
;
;   tmw : in, required, type="stx_telemetry_writer"
;     an open telemerty_writer object
;
; :history:
;    27-Jul-2016 - Simon Marcin (FHNW), initial release
;-

pro stx_telemetry_write_hc_regular_mini, report_mini_packet_structure, tmw=tmw, _extra=extra

  ppl_require, in=report_mini_packet_structure, type='stx_tmtc_hc_regular_mini'

  ; get packet_word_with information (lenght of fields)
  pkg_word_width = report_mini_packet_structure.pkg_word_width

  ; extract tags of packet and word_width
  tags_packet = strlowcase(tag_names(report_mini_packet_structure))
  tags_pkg_word_width = strlowcase(tag_names(pkg_word_width))

  ; process all header fields
  for tagidx = 0L, n_elements(tags_packet)-1 do begin
    tag_packet = tags_packet[tagidx]

    ; skip type and pkg_ and dynamich_ fields/tags
    if(tag_packet eq 'type' || stregex(tag_packet, 'pkg_.*', /bool) || $
      stregex(tag_packet, 'header_.*', /bool) || stregex(tag_packet, 'dynamic_.*', /bool)) then continue

    ; get data and lenght in bits of tag
    data = report_mini_packet_structure.(tagidx)
    bits = pkg_word_width.(tag_index(pkg_word_width, tag_packet))

    ; write bits
    tmw->write, data, bits=bits, debug=debug, silent=silent

  endfor


end