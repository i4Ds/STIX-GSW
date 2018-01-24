;+
; :description:
;   this function reads the sd aapect specific information
;
; :categories:
;   simulation, reader, telemetry, sd, aspect
;
; :params:
;   aspect_packet_structure : in, required, type="stx_telemetry_packet_structure_sd_aspect"
;     the input ql aspect
;
;   tmr : in, required, type="stx_telemetry_reader"
;     an open telemerty_reader object
;
; :history:
;    08-Dec-2015 - Simon Marcin (FHNW), initial release
;-

function stx_telemetry_read_sd_aspect, solo_packet=solo_packet, tmr=tmr, _extra=extra
 
  ppl_require, in=solo_packet, type='stx_tmtc_solo_source_packet_header'

  ; create emtpy ql_aspect packet
  ql_aspect_packet = stx_telemetry_packet_structure_sd_aspect_header()

  ; auto fill packet
  tmr->auto_read_structure, packet=ql_aspect_packet, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*']

  ; automatically override the default values with the read values
  tmr->auto_override_common_fields, solo_packet=solo_packet, data_packet=ql_aspect_packet

  ; set solo packet size to this packet header, to allow for calculating the dynamic packet size later
  ; 'stop' should never be encountered
  if(solo_packet.pkg_word_width.source_data gt 0) then stop $
  else solo_packet.pkg_word_width.source_data = ql_aspect_packet.pkg_word_width.pkg_total_bytes_fixed * 8

  ; prepare data pointers for light_curves
  ql_aspect_packet.DYNAMIC_CHA1 = ptr_new(uintarr(ql_aspect_packet.number_samples)-1)
  ql_aspect_packet.DYNAMIC_CHA2 = ptr_new(uintarr(ql_aspect_packet.number_samples)-1)
  ql_aspect_packet.DYNAMIC_CHB1 = ptr_new(uintarr(ql_aspect_packet.number_samples)-1)
  ql_aspect_packet.DYNAMIC_CHB2 = ptr_new(uintarr(ql_aspect_packet.number_samples)-1)

  ; process all lightcurves
  for i = 0L, ql_aspect_packet.number_samples-1 do begin

    ; aspect: read 16 bits
    val = tmr->read(size(uint(0), /type), bits=16, debug=debug, silent=silent)
    (*ql_aspect_packet.DYNAMIC_CHA1)[i] = val
    
    ; aspect: read 16 bits
    val = tmr->read(size(uint(0), /type), bits=16, debug=debug, silent=silent)
    (*ql_aspect_packet.dynamic_cha2)[i] = val
    
    ; aspect: read 16 bits
    val = tmr->read(size(uint(0), /type), bits=16, debug=debug, silent=silent)
    (*ql_aspect_packet.dynamic_chb1)[i] = val
    
    ; aspect: read 16 bits
    val = tmr->read(size(uint(0), /type), bits=16, debug=debug, silent=silent)
    (*ql_aspect_packet.dynamic_chb2)[i] = val
    
    ; update dynamic packet size fields
    ql_aspect_packet.pkg_word_width.dynamic_cha1 += 16
    ql_aspect_packet.pkg_word_width.dynamic_cha2 += 16
    ql_aspect_packet.pkg_word_width.dynamic_chb1 += 16
    ql_aspect_packet.pkg_word_width.dynamic_chb2 += 16
    
    solo_packet.pkg_word_width.source_data += 4 * 16

  endfor

  ;  if(n_structs ne 0) then message, 'Incorrect alignment of expected number of structures and actual number of structures'
  ;  if(total_data_bytes_read ne data_dynlen) then message, 'Incorrect alignment of counted total bytes and calculated total byte length'

  return, ql_aspect_packet
end