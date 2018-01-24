;+
; :description:
;   this routine reads the xray 0 specific information
;
; :categories:
;   simulation, reader, telemetry, science data, xray
;
; :params:
;   solo_packet : in, required, type="stx_telemetry_packet_structure_solo_source_packet_header"
;     the input xray solo packe
;
;   tmr : in, required, type="stx_telemetry_reader"
;     an open telemerty_reader object
;
; :history:
;    28-Sep-2016 - Simon Marcin (FHNW), initial release
;-

function stx_telemetry_read_sd_xray_0, solo_packet=solo_packet, tmr=tmr, _extra=extra
  ppl_require, in=solo_packet, type='stx_tmtc_solo_source_packet_header'

  ; create emtpy ql_light_curve packet
  sd_xray_packet = stx_telemetry_packet_structure_sd_xray_header()

  ; auto fill packet
  tmr->auto_read_structure, packet=sd_xray_packet, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*']

  ; automatically override the default values with the read values
  tmr->auto_override_common_fields, solo_packet=solo_packet, data_packet=sd_xray_packet

  ; set solo packet size to this packet header, to allow for calculating the dynamic packet size later
  ; 'stop' should never be encountered
  if(solo_packet.pkg_word_width.source_data gt 0) then stop $
  else solo_packet.pkg_word_width.source_data = sd_xray_packet.pkg_word_width.pkg_total_bytes_fixed

  ; create a list for multiple subheaders
  subheaders = list()

  ; process all subheaders
  for i = 0L, sd_xray_packet.number_time_samples-1 do begin
    
    ; create emtpy xray_0 packet
    sub = stx_telemetry_packet_structure_sd_xray_0_subheader()

    ; auto fill packet
    tmr->auto_read_structure, packet=sub, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*']

    ; prepare data pointers for science samples
    sub.dynamic_continuation_bits = ptr_new(bytarr(sub.number_science_data_samples)-1)
    sub.dynamic_detector_id = ptr_new(bytarr(sub.number_science_data_samples)-1)
    sub.dynamic_pixel_id = ptr_new(bytarr(sub.number_science_data_samples)-1)
    sub.dynamic_energy_id = ptr_new(bytarr(sub.number_science_data_samples)-1)
    sub.dynamic_counts = ptr_new(intarr(sub.number_science_data_samples)+1)

    ; process dynamic science dataslices
    for j = 0L, sub.number_science_data_samples-1 do begin
      
      ; continuation_bit: read 2 bits
      val = tmr->read(1, bits=2, debug=debug, silent=silent)
      (*sub.dynamic_continuation_bits)[j] = val
      continuation_bit = val
      
      ; detector_id: read 5 bits
      val = tmr->read(1, bits=5, debug=debug, silent=silent)
      (*sub.dynamic_detector_id)[j] = val
      
      ; pixel_id: read 4 bits
      val = tmr->read(1, bits=4, debug=debug, silent=silent)
      (*sub.dynamic_pixel_id)[j] = val
      
      ; energy_id: read 5 bits
      val = tmr->read(1, bits=5, debug=debug, silent=silent)
      (*sub.dynamic_energy_id)[j] = val
      
      ; handle dynamic size of counts
      if (continuation_bit eq 0) then continue
      dynamic_bits = 8
      if (continuation_bit eq 2) then dynamic_bits = 16
      
      ; continuation_bit: read dynamic bits
      val = tmr->read(12, bits=dynamic_bits, debug=debug, silent=silent)
      (*sub.dynamic_counts)[j] = val
      
    endfor
    
    ; add subheader to list
    subheaders.add, sub      
    
  endfor

  ; attach list to sd_xray_packet
  sd_xray_packet.dynamic_subheaders = ptr_new(subheaders)
  
  return, sd_xray_packet
end