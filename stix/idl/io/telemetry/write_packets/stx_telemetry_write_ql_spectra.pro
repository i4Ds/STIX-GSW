;+
; :description:
;   this routine writes the spectra specific information
;
; :categories:
;   simulation, writer, telemetry, quicklook, spectra
;
; :params:
;   light_curve_packet_structure : in, required, type="stx_telemetry_packet_structure_spectra"
;     the spectra object
;
;   tmw : in, required, type="stx_telemetry_writer"
;     an open telemerty_writer object
;
; :history:
;    01-Dec-2015 - Simon Marcin (FHNW), initial release
;-

pro stx_telemetry_write_ql_spectra, spectra_packet_structure, tmw=tmw, _extra=extra
  ppl_require, in=spectra_packet_structure, type='stx_tmtc_ql_spectra'

  ; get packet_word_with information (lenght of fields)
  pkg_word_width = spectra_packet_structure.pkg_word_width

  ; extract tags of packet and word_width
  tags_packet = strlowcase(tag_names(spectra_packet_structure))
  tags_pkg_word_width = strlowcase(tag_names(pkg_word_width))

  ; process all header fields
  for tagidx = 0L, n_elements(tags_packet)-1 do begin
    tag_packet = tags_packet[tagidx]

    ; skip type and pkg_ and dynamich_ fields/tags
    if(tag_packet eq 'type' || stregex(tag_packet, 'pkg_.*', /bool) || $
      stregex(tag_packet, 'header_.*', /bool) || stregex(tag_packet, 'dynamic_.*', /bool)) then continue

    ; get data and lenght in bits of tag
    data = spectra_packet_structure.(tagidx)
    bits = pkg_word_width.(tag_index(pkg_word_width, tag_packet))

    ; write bits
    tmw->write, data, bits=bits, debug=debug, silent=silent

  endfor

  ; process all dyamic fields
  for struct_idx = 0L, spectra_packet_structure.number_of_structures-1 do begin

    ;write detector_index data
    data = (*spectra_packet_structure.dynamic_detector_index)[struct_idx]
    bits = 8
    tmw->write, data, bits=bits, debug=debug, silent=silent
    
    ;write spectrum data with /extract
    data = (*spectra_packet_structure.dynamic_spectrum)[0:31,struct_idx]
    bits = 8
    tmw->write, data, bits=bits, debug=debug, silent=silent, extract=1

    ;write trigger_accumulator
    data = (*spectra_packet_structure.dynamic_trigger_accumulator)[struct_idx]
    bits = 8
    tmw->write, data, bits=bits, debug=debug, silent=silent

    ;write delta_time data
    data = (*spectra_packet_structure.dynamic_nbr_samples)[struct_idx]
    bits = 8
    tmw->write, data, bits=bits, debug=debug, silent=silent

  endfor

end