;+
; :description:
;   this routine writes the light curve specific information
;
; :categories:
;   simulation, writer, telemetry, quicklook, light curves
;
; :params:
;   light_curve_packet_structure : in, required, type="stx_telemetry_packet_structure_ql_light_curves"
;     the input light curves
;
;   tmw : in, required, type="stx_telemetry_writer"
;     an open telemerty_writer object
;
; :history:
;    01-Dec-2015 - Simon Marcin (FHNW), initial release
;-

pro stx_telemetry_write_ql_light_curves, light_curve_packet_structure, tmw=tmw, _extra=extra
  
  ppl_require, in=light_curve_packet_structure, type='stx_tmtc_ql_light_curves'

  ; get packet_word_with information (lenght of fields)
  pkg_word_width = light_curve_packet_structure.pkg_word_width

  ; extract tags of packet and word_width
  tags_packet = strlowcase(tag_names(light_curve_packet_structure))
  tags_pkg_word_width = strlowcase(tag_names(pkg_word_width))

  ; process all header fields
  for tagidx = 0L, n_elements(tags_packet)-1 do begin
    tag_packet = tags_packet[tagidx]

    ; skip type and pkg_ and dynamich_ fields/tags
    if(tag_packet eq 'type' || stregex(tag_packet, 'pkg_.*', /bool) || $
      stregex(tag_packet, 'header_.*', /bool) || stregex(tag_packet, 'dynamic_.*', /bool) || $
      stregex(tag_packet, 'number_of_rcrs', /bool) || stregex(tag_packet, 'number_of_triggers', /bool)) then continue

    ; get data and lenght in bits of tag
    data = light_curve_packet_structure.(tagidx)
    bits = pkg_word_width.(tag_index(pkg_word_width, tag_packet))

    ; write bits
    tmw->write, data, bits=bits, debug=debug, silent=silent

  endfor

  ; get number of energy_bins (E)
  number_energy_bins = light_curve_packet_structure.number_of_energies

  ; process dynamic lightcurves (E times)
  for struct_idx = 0L, light_curve_packet_structure.number_of_energies-1 do begin
    ;write dynamic_nbr_of_data_points
    data = light_curve_packet_structure.dynamic_nbr_of_data_points
    bits = 16
    tmw->write, data, bits=bits, debug=debug, silent=silent
    ;write lightcurve data with /extract (array)
    data = (*light_curve_packet_structure.dynamic_lightcurves)[struct_idx,*]
    bits = 8
    tmw->write, data, bits=bits, debug=debug, silent=silent, extract=1
  endfor

  ;write number_of_triggers
  data = light_curve_packet_structure.number_of_triggers
  bits = 16
  tmw->write, data, bits=bits, debug=debug, silent=silent

  ;write dynamic_trigger_accumulator with /extract (array)
  data = (*light_curve_packet_structure.dynamic_trigger_accumulator)
  bits = 8
  tmw->write, data, bits=bits, debug=debug, silent=silent, extract=1

  ;write number_of_rcrs
  data = light_curve_packet_structure.number_of_rcrs
  bits = 16
  tmw->write, data, bits=bits, debug=debug, silent=silent
  
  ;write dynamic_rcr_values with /extract (array)
  data = (*light_curve_packet_structure.dynamic_rcr_values)
  bits = 8
  tmw->write, data, bits=bits, debug=debug, silent=silent, extract=1


end