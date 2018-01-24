;+
; :description:
;   this routine writes the background_monitor specific information
;
; :categories:
;   simulation, writer, telemetry, quicklook, background_monitor
;
; :params:
;   background_monitor_packet_structure : in, required, type="stx_telemetry_packet_structure_ql_background_monitor"
;     the input background_monitor
;
;   tmw : in, required, type="stx_telemetry_writer"
;     an open telemerty_writer object
;
; :history:
;    10-Dec-2015 - Simon Marcin (FHNW), initial release
;-

pro stx_telemetry_write_ql_background_monitor, background_monitor_packet_structure, tmw=tmw, _extra=extra

  ppl_require, in=background_monitor_packet_structure, type='stx_tmtc_ql_background_monitor'

  ; get packet_word_with information (lenght of fields)
  pkg_word_width = background_monitor_packet_structure.pkg_word_width

  ; extract tags of packet and word_width
  tags_packet = strlowcase(tag_names(background_monitor_packet_structure))
  tags_pkg_word_width = strlowcase(tag_names(pkg_word_width))

  ; process all header fields
  for tagidx = 0L, n_elements(tags_packet)-1 do begin
    tag_packet = tags_packet[tagidx]

    ; skip type and pkg_ and dynamich_ fields/tags
    if(tag_packet eq 'type' || stregex(tag_packet, 'pkg_.*', /bool) || $
      stregex(tag_packet, 'header_.*', /bool) || stregex(tag_packet, 'dynamic_.*', /bool) || $
      stregex(tag_packet, 'number_of_triggers', /bool)) then continue

    ; get data and lenght in bits of tag
    data = background_monitor_packet_structure.(tagidx)
    bits = pkg_word_width.(tag_index(pkg_word_width, tag_packet))

    ; write bits
    tmw->write, data, bits=bits, debug=debug, silent=silent

  endfor

  ; get number of energy_bins (E)
  number_energy_bins = background_monitor_packet_structure.number_of_energies


  ; process dynamic lightcurves (E times)
  for struct_idx = 0L, background_monitor_packet_structure.number_of_energies-1 do begin
    ;write dynamic_nbr_of_data_points
    data = background_monitor_packet_structure.dynamic_nbr_of_data_points
    bits = 16
    tmw->write, data, bits=bits, debug=debug, silent=silent
    ;write lightcurve data with /extract (array)
    data = (*background_monitor_packet_structure.dynamic_background)[struct_idx,*]
    bits = 8
    tmw->write, data, bits=bits, debug=debug, silent=silent, extract=1
  endfor

  ;write number_of_triggers
  data = background_monitor_packet_structure.number_of_triggers
  bits = 16
  tmw->write, data, bits=bits, debug=debug, silent=silent

  ;write dynamic_trigger_accumulator with /extract (array)
  data = (*background_monitor_packet_structure.dynamic_trigger_accumulator)
  bits = 8
  tmw->write, data, bits=bits, debug=debug, silent=silent, extract=1





end