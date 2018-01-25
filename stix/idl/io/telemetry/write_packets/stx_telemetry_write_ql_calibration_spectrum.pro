;+
; :description:
;   this routine writes the calibration spectrum specific information
;
; :categories:
;   simulation, writer, telemetry, quicklook, calibration spectrum
;
; :params:
;   calibration_spectrum_packet_structure : in, required, type="stx_telemetry_packet_structure_ql_calibration_spectrum"
;     the input calibration spectrum
;
;   tmw : in, required, type="stx_telemetry_writer"
;     an open telemerty_writer object
;
; :history:
;    21-Sep-2016 - Simon Marcin (FHNW), refactored function of Laszlo
;    22-Sep-2016 - Simon Marcin (FHNW), adapted to the new intermediate structure
;-

pro stx_telemetry_write_ql_calibration_spectrum, calibration_spectrum_packet_structure, $
  tmw=tmw, _extra=extra

  ppl_require, in=calibration_spectrum_packet_structure, type='stx_tmtc_ql_calibration_spectrum'

  pkg_word_width = calibration_spectrum_packet_structure.pkg_word_width

  ; extract tags of packet and word_width
  tags_packet = strlowcase(tag_names(calibration_spectrum_packet_structure))
  tags_pkg_word_width = strlowcase(tag_names(pkg_word_width))

  ; process all header fields
  for tagidx = 0L, n_elements(tags_packet)-1 do begin
    tag_packet = tags_packet[tagidx]

    ; skip type and pkg_ and dynamich_ fields/tags
    if(tag_packet eq 'type' || stregex(tag_packet, 'pkg_.*', /bool) || $
      stregex(tag_packet, 'header_.*', /bool) || stregex(tag_packet, 'dynamic_.*', /bool)) then continue

    ; get data and lenght in bits of tag
    data = calibration_spectrum_packet_structure.(tagidx)
    bits = pkg_word_width.(tag_index(pkg_word_width, tag_packet))

    ; write bits
    tmw->write, data, bits=bits, debug=debug, silent=silent

  endfor

  ; process all dyamic fields
  for struct_idx = 0L, calibration_spectrum_packet_structure.number_of_structures-1 do begin

    ;write spare bits
    data = (*calibration_spectrum_packet_structure.dynamic_spare)[struct_idx]
    tmw->write, data, bits=4, debug=debug, silent=silent

    ;write detector_id bits
    data = (*calibration_spectrum_packet_structure.dynamic_detector_id)[struct_idx]
    tmw->write, data, bits=5, debug=debug, silent=silent
    
    ;write pixel_id bits
    data = (*calibration_spectrum_packet_structure.dynamic_pixel_id)[struct_idx]
    tmw->write, data, bits=4, debug=debug, silent=silent
    
    ;write subspectra_id bits
    data = (*calibration_spectrum_packet_structure.dynamic_subspectra_id)[struct_idx]
    tmw->write, data, bits=3, debug=debug, silent=silent
    
    ;write number_points bits
    data = (*calibration_spectrum_packet_structure.dynamic_number_points)[struct_idx]
    tmw->write, data, bits=16, debug=debug, silent=silent
    
    ;write spectral_point data with /extract (array)
    data = (*calibration_spectrum_packet_structure.dynamic_spectral_points)[struct_idx]
    tmw->write, data, bits=8, debug=debug, silent=silent, extract=1

  endfor

end