;+
; :description:
;   this routine writes the xray specific information
;
; :categories:
;   simulation, writer, telemetry, quicklook, xray
;
; :params:
;   xray_packet_structure : in, required, type="stx_telemetry_packet_structure_ql_light_curves"
;     the input light curves
;
;   tmw : in, required, type="stx_telemetry_writer"
;     an open telemerty_writer object
;
; :history:
;    01-Dec-2015 - Simon Marcin (FHNW), initial release
;-

pro stx_telemetry_write_sd_xray_0, xray_packet_structure, tmw=tmw, _extra=extra

  ppl_require, in=xray_packet_structure[0], type='stx_tmtc_sd_xray_0'

  ; loop through all subheaders
  foreach packet, xray_packet_structure do begin
    
    ; write header information
    stx_telemerty_util_write_header, packet=packet, tmw=tmw
    
    ; process the dynamic part of the subheader
    for data_idx = 0L, packet.NUMBER_SCIENCE_DATA_SAMPLES-1 do begin
      
      ; write pixel_id
      data = (*packet.dynamic_pixel_id)[data_idx]
      bits = 4
      tmw->write, data, bits=bits, debug=debug, silent=silent

      ; write detector_id
      data = (*packet.dynamic_detector_id)[data_idx]
      bits = 5
      tmw->write, data, bits=bits, debug=debug, silent=silent
    
      ; write energy_id
      data = (*packet.dynamic_energy_id)[data_idx]
      bits = 5
      tmw->write, data, bits=bits, debug=debug, silent=silent
        
      ; write continuation_bits 
      continuation_bit = (*packet.dynamic_continuation_bits)[data_idx]
      bits = 2
      tmw->write, continuation_bit, bits=bits, debug=debug, silent=silent
        
        
      ; write counts (if there are any)
      if(continuation_bit eq 0) THEN CONTINUE
      bits = 16
      if(continuation_bit eq 1) THEN bits = 8
      data = (*packet.dynamic_counts)[data_idx]
      tmw->write, data, bits=bits, debug=debug, silent=silent
            
    endfor
    
  endforeach

end