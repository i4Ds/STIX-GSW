;+
; :description:
;   this routine writes the flare_list specific information
;
; :categories:
;   simulation, writer, telemetry, quicklook, flare_list
;
; :params:
;   packet : in, required, type="stx_telemetry_packet_structure_flare_list"
;
;   tmw : in, required, type="stx_telemetry_writer"
;     an open telemerty_writer object
;
; :history:
;    08-Dec-2015 - Simon Marcin (FHNW), initial release
;-

pro stx_telemetry_write_ql_flare_list, packet, tmw=tmw, _extra=extra
  ppl_require, in=packet, type='stx_tmtc_ql_flare_list'

    ; write header information
    stx_telemerty_util_write_header, packet=packet, tmw=tmw

  ; process all dyamic fields
  if packet.number_of_flares gt 0 then for struct_idx = 0L, packet.number_of_flares-1 do begin

    ;write dynamic_start_coarse data
    data = (*packet.dynamic_start_coarse)[struct_idx]
    tmw->write, data, bits=32, debug=debug, silent=silent

    
    ;write dynamic_end_coarse data
    data = (*packet.dynamic_end_coarse)[struct_idx]
    tmw->write, data, bits=32, debug=debug, silent=silent
    
    
    ;write dynamic_high_flag data
    data = (*packet.dynamic_high_flag)[struct_idx]
    tmw->write, data, bits=8, debug=debug, silent=silent
    
    ;write dynamic_tm_volume
    data = (*packet.dynamic_tm_volume)[struct_idx]
    tmw->write, data, bits=32, debug=debug, silent=silent
    
    ;write dynamic_avg_cfl_z data
    data = (*packet.dynamic_avg_cfl_z)[struct_idx]
    tmw->write, data, bits=8, debug=debug, silent=silent
    
    ;write dynamic_avg_cfl_y
    data = (*packet.dynamic_avg_cfl_y)[struct_idx]
    tmw->write, data, bits=8, debug=debug, silent=silent
    
   
    
    ;write dynamic_processing_status data
    data = (*packet.dynamic_processing_status)[struct_idx]
    tmw->write, data, bits=8, debug=debug, silent=silent
   
  endfor

end