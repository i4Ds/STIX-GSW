;+
; :description:
;   this routine writes the spectrogram specific information
;
; :categories:
;   simulation, writer, telemetry, science data, spectrogram
;
; :params:
;   xray_packet_structure : in, required, type="stx_telemetry_packet_structure_sd_spectrogram_subheader"
;     the input science data
;
;   tmw : in, required, type="stx_telemetry_writer"
;     an open telemerty_writer object
;
; :history:
;    09-Oct-2016 - Simon Marcin (FHNW), initial release
;-

pro stx_telemetry_write_sd_spectrogram, xray_packet_structure, tmw=tmw, _extra=extra

  ppl_require, in=xray_packet_structure[0], $
    type='stx_tmtc_sd_spectrogram'

  ; loop through all subheaders
  foreach packet, xray_packet_structure do begin

    ; write header information
    exclude=['closing_time_offset']
    stx_telemerty_util_write_header, packet=packet, tmw=tmw, $
      exclude=exclude

    ; get number of energy bins
    loop_E = fix(total(stx_mask2bits(packet.energy_bin_mask,mask_length=33, /reverse)))-1
    
    ; process the dynamic part of the subheader
    for data_idx = 0L, packet.NUMBER_SAMPLES-1 do begin

      ; write dynamic_delta_time
      data = (*packet.dynamic_delta_time)[data_idx]
      tmw->write, data, bits=16, debug=debug, silent=silent

      ; write dynamic_trigger
      data = (*packet.dynamic_trigger)[data_idx]
      tmw->write, data, bits=8, debug=debug, silent=silent

      ; write counts
      for idx_E = 0, loop_E -1 do begin
          data = (*packet.dynamic_counts)[idx_E,data_idx]
          tmw->write, data, bits=8, debug=debug, silent=silent
      endfor

    endfor
    
    ; write closing_time_offset
    data = packet.closing_time_offset
    tmw->write, data, bits=16, debug=debug, silent=silent

  endforeach

end