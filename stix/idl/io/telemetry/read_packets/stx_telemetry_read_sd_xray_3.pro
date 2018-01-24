;+
; :description:
;   this routine reads the xray 3 specific information
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
;    29-Nov-2016 - Simon Marcin (FHNW), initial release
;-

function stx_telemetry_read_sd_xray_3, solo_packet=solo_packet, tmr=tmr, _extra=extra
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
    sub = stx_telemetry_packet_structure_sd_xray_3_subheader()

    ; auto fill packet
    tmr->auto_read_structure, packet=sub, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*']

    ; get dynamic lenghts
    loop_D = fix(total(stx_mask2bits(sub.detector_mask,mask_length=32, /reverse)))

    ; prepare data pointers for science samples
    sub.dynamic_e_low = ptr_new(bytarr(sub.number_substructures))
    sub.dynamic_e_high = ptr_new(bytarr(sub.number_substructures))
    sub.dynamic_spare = ptr_new(bytarr(sub.number_substructures))
    sub.dynamic_tot_counts = ptr_new(bytarr(loop_D,sub.number_substructures))
    sub.dynamic_vis_real = ptr_new(lonarr(loop_D,sub.number_substructures))
    sub.dynamic_vis_imaginary = ptr_new(lonarr(loop_D,sub.number_substructures))
    
    ; process dynamic science dataslices
    for j = 0L, sub.number_substructures-1 do begin

      ; e_low: read 2 bits
      val = tmr->read(1, bits=5, debug=debug, silent=silent)
      (*sub.dynamic_e_low)[j] = val

      ; e_high: read 5 bits
      val = tmr->read(1, bits=5, debug=debug, silent=silent)
      (*sub.dynamic_e_high)[j] = val
      
      ; spare: read 6 bits
      val = tmr->read(1, bits=6, debug=debug, silent=silent)
      (*sub.dynamic_spare)[j] = val

      ; counts: read 8 bits each
      for idx_D = 0, loop_D -1 do begin
          val = tmr->read(1, bits=8, debug=debug, silent=silent)
          (*sub.dynamic_tot_counts)[idx_D,j] = val
          val = tmr->read(1, bits=8, debug=debug, silent=silent)
          ;val = stx_telemetry_util_negative_byte(val, /reverse)
          (*sub.dynamic_vis_real)[idx_D,j] = val
          val = tmr->read(1, bits=8, debug=debug, silent=silent)
          ;val = stx_telemetry_util_negative_byte(val, /reverse)
          (*sub.dynamic_vis_imaginary)[idx_D,j] = val
      endfor

    endfor

    ; add subheader to list
    subheaders.add, sub

  endfor

  ; attach list to sd_xray_packet
  sd_xray_packet.dynamic_subheaders = ptr_new(subheaders)

  return, sd_xray_packet
end