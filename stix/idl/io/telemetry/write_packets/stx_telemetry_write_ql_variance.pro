;+
; :description:
;   this routine writes the variance specific information
;
; :categories:
;   simulation, writer, telemetry, quicklook, variance
;
; :params:
;   light_curve_packet_structure : in, required, type="stx_telemetry_packet_structure_variance"
;     the spectra object
;
;   tmw : in, required, type="stx_telemetry_writer"
;     an open telemerty_writer object
;
; :history:
;    08-Dec-2015 - Simon Marcin (FHNW), initial release
;-

pro stx_telemetry_write_ql_variance, variance_packet_structure, tmw=tmw, _extra=extra
  ppl_require, in=variance_packet_structure, type='stx_tmtc_ql_variance'

  ; get packet_word_with information (lenght of fields)
  pkg_word_width = variance_packet_structure.pkg_word_width

  ; extract tags of packet and word_width
  tags_packet = strlowcase(tag_names(variance_packet_structure))
  tags_pkg_word_width = strlowcase(tag_names(pkg_word_width))

  ; process all header fields
  for tagidx = 0L, n_elements(tags_packet)-1 do begin
    tag_packet = tags_packet[tagidx]

    ; skip type and pkg_ and dynamich_ fields/tags
    if(tag_packet eq 'type' || stregex(tag_packet, 'pkg_.*', /bool) || $
      stregex(tag_packet, 'header_.*', /bool) || stregex(tag_packet, 'dynamic_.*', /bool)) then continue

    ; get data and lenght in bits of tag
    data = variance_packet_structure.(tagidx)
    bits = pkg_word_width.(tag_index(pkg_word_width, tag_packet))

    ; write bits
    tmw->write, data, bits=bits, debug=debug, silent=silent

  endfor

  ; process all dyamic fields
  for struct_idx = 0L, variance_packet_structure.number_of_samples-1 do begin

    ;write detector_index data
    data = (*variance_packet_structure.dynamic_variance)[struct_idx]
    bits = 8
    tmw->write, data, bits=bits, debug=debug, silent=silent

  endfor

end