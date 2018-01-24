;+
; :description:
;   this routine writes the xray specific information
;
; :categories:
;   simulation, writer, telemetry, science data, level 1
;
; :params:
;   xray_packet_structure : in, required, type="stx_telemetry_packet_structure_sd_xray_1_subheader"
;     the input science data
;
;   tmw : in, required, type="stx_telemetry_writer"
;     an open telemerty_writer object
;
; :history:
;    06-Oct-2016 - Simon Marcin (FHNW), initial release
;-

pro stx_telemetry_write_sd_xray_1, xray_packet_structure, tmw=tmw, _extra=extra
  
  ppl_require, in=xray_packet_structure[0], $
    type=['stx_tmtc_sd_xray_1',$
    'stx_tmtc_sd_xray_2']

  ; loop through all subheaders
  foreach packet, xray_packet_structure do begin

    ; write header information
    stx_telemerty_util_write_header, packet=packet, tmw=tmw

    ; process the dynamic part of the subheader
    for data_idx = 0L, packet.NUMBER_SCIENCE_DATA_SAMPLES-1 do begin

      ; write e_low
      data = (*packet.dynamic_e_low)[data_idx]
      tmw->write, data, bits=5, debug=debug, silent=silent

      ; write e_high
      data = (*packet.dynamic_e_high)[data_idx]
      tmw->write, data, bits=5, debug=debug, silent=silent

      ; write spare
      data = (*packet.dynamic_spare)[data_idx]
      tmw->write, data, bits=6, debug=debug, silent=silent

      ; write counts
      loop_D = fix(total(stx_mask2bits(packet.detector_mask,mask_length=32, /reverse)))
      loop_P = packet.number_of_pixel_sets
      for idx_D = 0, loop_D -1 do begin
        for idx_P = 0, loop_P -1 do begin
          data = (*packet.dynamic_counts)[idx_P,idx_D,data_idx]
          tmw->write, data, bits=8, debug=debug, silent=silent
        endfor
      endfor

    endfor

  endforeach

end