;+
; :description:
;   this function reads the ql spectra specific information
;
; :categories:
;   simulation, reader, telemetry, quicklook, ql, spectra
;
; :params:
;   light_curve_packet_structure : in, required, type="stx_telemetry_packet_structure_ql_spectra"
;     the input ql spectra
;
;   tmr : in, required, type="stx_telemetry_reader"
;     an open telemerty_reader object
;
; :history:
;    04-Dec-2015 - Simon Marcin (FHNW), initial release
;-

function stx_telemetry_read_ql_spectra, solo_packet=solo_packet, tmr=tmr, _extra=extra
  ppl_require, in=solo_packet, type='stx_tmtc_solo_source_packet_header'

  ; create emtpy ql_light_curve packet
  ql_spectra_packet = stx_telemetry_packet_structure_ql_spectra()

  ; auto fill packet
  tmr->auto_read_structure, packet=ql_spectra_packet, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*']

  ; automatically override the default values with the read values
  tmr->auto_override_common_fields, solo_packet=solo_packet, data_packet=ql_spectra_packet

  ; set solo packet size to this packet header, to allow for calculating the dynamic packet size later
  ; 'stop' should never be encountered
  if(solo_packet.pkg_word_width.source_data gt 0) then stop $
  else solo_packet.pkg_word_width.source_data = ql_spectra_packet.pkg_word_width.pkg_total_bytes_fixed

  ; extract pixel mask
  ; TODO: refactor to util class
  stx_telemetry_util_encode_decode_structure, input=ql_spectra_packet.pixel_mask, pixel_mask=pixel_mask

  ; prepare data pointers for light_curves
  ql_spectra_packet.dynamic_detector_index = ptr_new(bytarr(ql_spectra_packet.number_of_structures)-1)
  ql_spectra_packet.dynamic_spectrum = ptr_new(bytarr(32,ql_spectra_packet.number_of_structures)-1)
  ql_spectra_packet.dynamic_trigger_accumulator = ptr_new(bytarr(ql_spectra_packet.number_of_structures)-1)
  ql_spectra_packet.dynamic_nbr_samples = ptr_new(intarr(ql_spectra_packet.number_of_structures)-1)
  
  ; process all lightcurves
  for i = 0L, ql_spectra_packet.number_of_structures-1 do begin

    ; detector_index: read 8 bits
    val = tmr->read(size(byte(0), /type), bits=8, debug=debug, silent=silent)
    (*ql_spectra_packet.dynamic_detector_index)[i] = val

    ; spectrum: read 8 bits for each of the 32 pieces
    for j = 0L, 31 do begin
      val = tmr->read(size(byte(0), /type), bits=8, debug=debug, silent=silent)
      (*ql_spectra_packet.dynamic_spectrum)[j,i] = val
    endfor

    ; trigger_accumulator: read 8 bits
    val = tmr->read(size(byte(0), /type), bits=8, debug=debug, silent=silent)
    (*ql_spectra_packet.dynamic_trigger_accumulator)[i] = val

    ; delta_time: read 16 bits
    val = tmr->read(size(uint(0), /type), bits=8, debug=debug, silent=silent)
    (*ql_spectra_packet.dynamic_nbr_samples)[i] = val

  endfor

  ;  if(n_structs ne 0) then message, 'Incorrect alignment of expected number of structures and actual number of structures'
  ;  if(total_data_bytes_read ne data_dynlen) then message, 'Incorrect alignment of counted total bytes and calculated total byte length'

  return, ql_spectra_packet
end