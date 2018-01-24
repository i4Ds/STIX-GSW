;+
; :description:
;   this function reads the ql varaince specific information
;
; :categories:
;   simulation, reader, telemetry, quicklook, ql, variance
;
; :params:
;   light_curve_packet_structure : in, required, type="stx_telemetry_packet_structure_ql_variance"
;     the input ql variance
;
;   tmr : in, required, type="stx_telemetry_reader"
;     an open telemerty_reader object
;
; :history:
;    08-Dec-2015 - Simon Marcin (FHNW), initial release
;-

function stx_telemetry_read_ql_variance, solo_packet=solo_packet, tmr=tmr, _extra=extra
  ppl_require, in=solo_packet, type='stx_tmtc_solo_source_packet_header'

  ; create emtpy ql_variance packet
  ql_variance_packet = stx_telemetry_packet_structure_ql_variance()

  ; auto fill packet
  tmr->auto_read_structure, packet=ql_variance_packet, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*']

  ; automatically override the default values with the read values
  tmr->auto_override_common_fields, solo_packet=solo_packet, data_packet=ql_variance_packet

  ; set solo packet size to this packet header, to allow for calculating the dynamic packet size later
  ; 'stop' should never be encountered
  if(solo_packet.pkg_word_width.source_data gt 0) then stop $
  else solo_packet.pkg_word_width.source_data = ql_variance_packet.pkg_word_width.pkg_total_bytes_fixed * 8

  ; extract pixel and detector  mask
  ; TODO: refactor to util class
  stx_telemetry_util_encode_decode_structure, input=ql_variance_packet.pixel_mask, pixel_mask=pixel_mask
  stx_telemetry_util_encode_decode_structure, input=ql_variance_packet.detector_mask, detector_mask=detector_mask

  ; prepare data pointers for light_curves
  ql_variance_packet.dynamic_variance = ptr_new(bytarr(ql_variance_packet.number_of_samples)-1)

  ; process all lightcurves
  for i = 0L, ql_variance_packet.number_of_samples-1 do begin

    ; variance: read 8 bits
    val = tmr->read(size(byte(0), /type), bits=8, debug=debug, silent=silent)
    (*ql_variance_packet.dynamic_variance)[i] = val
    
    ; update dynamic packet size fields
    ql_variance_packet.pkg_word_width.dynamic_variance += 8
    solo_packet.pkg_word_width.source_data += 8

  endfor

  ;  if(n_structs ne 0) then message, 'Incorrect alignment of expected number of structures and actual number of structures'
  ;  if(total_data_bytes_read ne data_dynlen) then message, 'Incorrect alignment of counted total bytes and calculated total byte length'

  return, ql_variance_packet
end