;+
; :description:
;   this routine reads the light curve specific information
;
; :categories:
;   simulation, reader, telemetry, quicklook, light curves
;
; :params:
;   light_curve_packet_structure : in, required, type="stx_telemetry_packet_structure_ql_light_curves"
;     the input light curves
;
;   tmr : in, required, type="stx_telemetry_reader"
;     an open telemerty_reader object
;
; :history:
;    04-Dec-2015 - Simon Marcin (FHNW), initial release
;-

function stx_telemetry_read_ql_light_curves, solo_packet=solo_packet, tmr=tmr, _extra=extra
  ppl_require, in=solo_packet, type='stx_tmtc_solo_source_packet_header'

  ; create emtpy ql_light_curve packet
  ql_light_curves_packet = stx_telemetry_packet_structure_ql_light_curves()

  ; auto fill packet
  tmr->auto_read_structure, packet=ql_light_curves_packet, $
    tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*', 'number_of_triggers', 'number_of_rcrs']

  ; automatically override the default values with the read values
  tmr->auto_override_common_fields, solo_packet=solo_packet, data_packet=ql_light_curves_packet

  ; set solo packet size to this packet header, to allow for calculating the dynamic packet size later
  ; 'stop' should never be encountered
  if(solo_packet.pkg_word_width.source_data gt 0) then stop $
  else solo_packet.pkg_word_width.source_data = ql_light_curves_packet.pkg_word_width.pkg_total_bytes_fixed

  ; extract pixel, energy_bin and detector mask
  stx_telemetry_util_encode_decode_structure, input=ql_light_curves_packet.pixel_mask, pixel_mask=pixel_mask
  stx_telemetry_util_encode_decode_structure, input=ql_light_curves_packet.detector_mask, detector_mask=detector_mask
  stx_telemetry_util_encode_decode_structure, input=ql_light_curves_packet.energy_bin_mask, $
    energy_bin_mask=energy_bin_mask, number_energy_bins=number_energy_bins

  ; dynamic_nbr_of_data_points: read 16 bits
  val = tmr->read(size(uint(0), /type), bits=16, debug=debug, silent=silent)
  ql_light_curves_packet.dynamic_nbr_of_data_points = val

  ; as we peeded 16 bits we have to skip these inside of the loop
  peeked=1
  
  ; prepare data pointers for light_curves
  ;ql_light_curves_packet.dynamic_nbr_of_data_points = 32
  ql_light_curves_packet.dynamic_lightcurves = ptr_new(bytarr(ql_light_curves_packet.number_of_energies,ql_light_curves_packet.dynamic_nbr_of_data_points)-1)
  
  ; process all lightcurves
  for j = 0L, ql_light_curves_packet.number_of_energies-1 do begin
    if not peeked then begin
    ; dynamic_nbr_of_data_points: read 16 bits
    val = tmr->read(size(uint(0), /type), bits=16, debug=debug, silent=silent)
    ;ql_light_curves_packet.dynamic_nbr_of_data_points = val
    endif
    peeked = 0
    ; read 8 bits for each light_curve
    for i = 0L, ql_light_curves_packet.dynamic_nbr_of_data_points-1 do begin
      val = tmr->read(size(byte(0), /type), bits=8, debug=debug, silent=silent)
      (*ql_light_curves_packet.dynamic_lightcurves)[j,i] = val
    endfor
  endfor
  
  
  ; number_of_triggers: read 16 bits
  val = tmr->read(size(uint(0), /type), bits=16, debug=debug, silent=silent)
  ql_light_curves_packet.number_of_triggers = val
  ql_light_curves_packet.dynamic_trigger_accumulator = ptr_new(bytarr(ql_light_curves_packet.number_of_triggers)-1)
  ; read 8 bits for each trigger_accumulator
  for i = 0L, ql_light_curves_packet.number_of_triggers-1 do begin
    val = tmr->read(size(byte(0), /type), bits=8, debug=debug, silent=silent)
    (*ql_light_curves_packet.dynamic_trigger_accumulator)[i] = val
  endfor

  ; number_of_rcrs: read 16 bits
  val = tmr->read(size(uint(0), /type), bits=16, debug=debug, silent=silent)
  ql_light_curves_packet.number_of_rcrs = val
  ql_light_curves_packet.dynamic_rcr_values = ptr_new(bytarr(ql_light_curves_packet.number_of_rcrs)-1)
  ; read 8 bits for each rcr_value
  for i = 0L, ql_light_curves_packet.number_of_triggers-1 do begin
    val = tmr->read(size(byte(0), /type), bits=8, debug=debug, silent=silent)
    (*ql_light_curves_packet.dynamic_rcr_values)[i] = val
  endfor

  ;  if(n_structs ne 0) then message, 'Incorrect alignment of expected number of structures and actual number of structures'
  ;  if(total_data_bytes_read ne data_dynlen) then message, 'Incorrect alignment of counted total bytes and calculated total byte length'

  return, ql_light_curves_packet
end