pro stx_telemerty_util_write_header, packet=packet, tmw=tmw, exclude=exclude

  ; get packet_word_with information (lenght of fields)
  pkg_word_width = packet.pkg_word_width

  ; extract tags of packet and word_width
  tags_packet = strlowcase(tag_names(packet))
  tags_pkg_word_width = strlowcase(tag_names(pkg_word_width))

  ; process all header fields
  for tagidx = 0L, n_elements(tags_packet)-1 do begin
    tag_packet = tags_packet[tagidx]

    ; skip type and pkg_ and dynamich_ fields/tags
    if(tag_packet eq 'type' || stregex(tag_packet, 'pkg_.*', /bool) || $
      stregex(tag_packet, 'header_.*', /bool) || stregex(tag_packet, 'dynamic_.*', /bool)) then continue
    if(arg_present(exclude)) then if(WHERE(exclude eq tag_packet) ne -1) then continue
    
    ; get data and lenght in bits of tag
    data = packet.(tagidx)
    bits = pkg_word_width.(tag_index(pkg_word_width, tag_packet))

    ; write bits
    tmw->write, data, bits=bits, debug=debug, silent=silent

  endfor

end