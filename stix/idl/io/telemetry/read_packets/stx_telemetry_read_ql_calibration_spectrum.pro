;+
; :description:
;   this routine reads the calibration spectrum specific information
;
; :categories:
;   simulation, reader, telemetry, quicklook, calibration spectrum
;
; :params:
;   light_curve_packet_structure : in, required, type="stx_telemetry_packet_structure_ql_calibration_spectrum"
;     the input light curves
;
;   tmr : in, required, type="stx_telemetry_reader"
;     an open telemerty_reader object
;
; :history:
;    13-Oct-2016 - Simon Marcin (FHNW), initial release
;-

function stx_telemetry_read_ql_calibration_spectrum, solo_packet=solo_packet, tmr=tmr, _extra=extra
  ppl_require, in=solo_packet, type='stx_tmtc_solo_source_packet_header'

  ; create emtpy ql_light_curve packet
  ql_calibration_spectrum_packet = stx_telemetry_packet_structure_ql_calibration_spectrum()

  ; auto fill packet
  tmr->auto_read_structure, packet=ql_calibration_spectrum_packet, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*']

  ; automatically override the default values with the read values
  tmr->auto_override_common_fields, solo_packet=solo_packet, data_packet=ql_calibration_spectrum_packet

  ; set solo packet size to this packet header, to allow for calculating the dynamic packet size later
  ; 'stop' should never be encountered
  if(solo_packet.pkg_word_width.source_data gt 0) then stop $
  else solo_packet.pkg_word_width.source_data = ql_calibration_spectrum_packet.pkg_word_width.pkg_total_bytes_fixed

  ; extract pixel, energy_bin and detector mask
  stx_telemetry_util_encode_decode_structure, input=ql_calibration_spectrum_packet.pixel_mask, pixel_mask=pixel_mask
  stx_telemetry_util_encode_decode_structure, input=ql_calibration_spectrum_packet.detector_mask, detector_mask=detector_mask
  stx_telemetry_util_encode_decode_structure, input=ql_calibration_spectrum_packet.subspectrum_mask, subspectrum_mask=subspectrum_mask


  ; prepare data pointers
  ql_calibration_spectrum_packet.dynamic_spare = ptr_new(bytarr(ql_calibration_spectrum_packet.number_of_structures))
  ql_calibration_spectrum_packet.dynamic_detector_id = ptr_new(bytarr(ql_calibration_spectrum_packet.number_of_structures))
  ql_calibration_spectrum_packet.dynamic_pixel_id = ptr_new(bytarr(ql_calibration_spectrum_packet.number_of_structures))
  ql_calibration_spectrum_packet.dynamic_number_points = ptr_new(uintarr(ql_calibration_spectrum_packet.number_of_structures))
  ql_calibration_spectrum_packet.dynamic_subspectra_id = ptr_new(bytarr(ql_calibration_spectrum_packet.number_of_structures))
  dynamic_spc = list()

  ; process all lightcurves
  for i = 0L, ql_calibration_spectrum_packet.number_of_structures-1 do begin

    ; dynamic_spare: read 4 bits
    val = tmr->read(size(byte(0), /type), bits=4, debug=debug, silent=silent)
    (*ql_calibration_spectrum_packet.dynamic_spare)[i] = val

    ; dynamic_detector_id: read 4 bits
    val = tmr->read(size(byte(0), /type), bits=5, debug=debug, silent=silent)
    (*ql_calibration_spectrum_packet.dynamic_detector_id)[i] = val
    
    ; dynamic_pixel_id: read 4 bits
    val = tmr->read(size(byte(0), /type), bits=4, debug=debug, silent=silent)
    (*ql_calibration_spectrum_packet.dynamic_pixel_id)[i] = val
    
    ; dynamic_subspectra_id: read 4 bits
    val = tmr->read(size(byte(0), /type), bits=3, debug=debug, silent=silent)
    (*ql_calibration_spectrum_packet.dynamic_subspectra_id)[i] = val

    ; dynamic_number_points: read 16 bits
    ; Repeater number of following loop
    val = tmr->read(size(uint(0), /type), bits=16, debug=debug, silent=silent)
    (*ql_calibration_spectrum_packet.dynamic_number_points)[i] = val
    
    ; read 8 bits per spectral point   
    sub=intarr(val)
    for j = 0L, val-1 do begin
      sub[j] = tmr->read(size(fix(0), /type), bits=8, debug=debug, silent=silent)
    endfor
    dynamic_spc.add, sub    

  endfor

    ql_calibration_spectrum_packet.dynamic_spectral_points = ptr_new(dynamic_spc)

  ;  if(n_structs ne 0) then message, 'Incorrect alignment of expected number of structures and actual number of structures'
  ;  if(total_data_bytes_read ne data_dynlen) then message, 'Incorrect alignment of counted total bytes and calculated total byte length'

  return, ql_calibration_spectrum_packet
end