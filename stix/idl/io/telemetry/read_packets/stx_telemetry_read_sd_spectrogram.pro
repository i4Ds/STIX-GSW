;+
; :description:
;   this routine reads the spectrogram specific information
;
; :categories:
;   simulation, reader, telemetry, science data, spectrogram
;
; :params:
;   solo_packet : in, required, type="stx_telemetry_packet_structure_solo_source_packet_header"
;     the input xray solo packe
;
;   tmr : in, required, type="stx_telemetry_reader"
;     an open telemerty_reader object
;
; :history:
;    09-Oct-2016 - Simon Marcin (FHNW), initial release
;-

function stx_telemetry_read_sd_spectrogram, solo_packet=solo_packet, tmr=tmr, _extra=extra
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
    sub = stx_telemetry_packet_structure_sd_spectrogram_subheader()

    ; auto fill packet
    tmr->auto_read_structure, packet=sub, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*', 'closing_time_offset']

    ; get dynamic lenghts
   
    
    loop_E = max([1,((sub.energy_high + 1) - sub.energy_low) / (sub.energy_unit + 1)]);
    loop_T = sub.number_samples

    ; prepare data pointers for science samples
    sub.dynamic_delta_time = ptr_new(uintarr(loop_T))
    sub.dynamic_trigger = ptr_new(uintarr(loop_T))
    sub.dynamic_counts = ptr_new(uintarr(loop_E,loop_T))

    ; process dynamic science dataslices
    for idx_T = 0L, loop_T-1 do begin

      ; dynamic_delta_time: read 16 bits
      val = tmr->read(12, bits=16, debug=debug, silent=silent)
      (*sub.dynamic_delta_time)[idx_T] = val

      ; dynamic_trigger: read 8 bits
      val = tmr->read(1, bits=8, debug=debug, silent=silent)
      (*sub.dynamic_trigger)[idx_T] = val

      ; counts: read 8 bits each
      for idx_E = 0, loop_E -1 do begin
          val = tmr->read(1, bits=8, debug=debug, silent=silent)
          (*sub.dynamic_counts)[idx_E,idx_T] = val
      endfor

    endfor
    
    ; closing_time_offset: read 16 bits
    val = tmr->read(12, bits=16, debug=debug, silent=silent)
    sub.closing_time_offset = val


    ; add subheader to list
    subheaders.add, sub

  endfor

  ; attach list to sd_xray_packet
  sd_xray_packet.dynamic_subheaders = ptr_new(subheaders)

  return, sd_xray_packet
end