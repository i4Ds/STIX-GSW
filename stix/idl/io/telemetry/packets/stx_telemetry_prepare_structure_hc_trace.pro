;ToDO: Packet description

; :categories:
;   simulation, writer, telemetry, HC, trace
;
; :params:
;
; :keywords:
;
; :history:
;    31-Aug-2018 - Nicky Hochmuth (FHNW), initial release
;-
function prepare_packet_structure_hc_trace_write_fsw, $
  trace, _extra=extra

  default, trace, "hello world"

  ; generate empty x-ray header paket
  packet = stx_telemetry_packet_structure_sd_xray_header()
  science_data = list()

  ; fill in the header data
  packet.ssid = 25
  packet.number_time_samples = (size(input))[1]


  packet.coarse_time = 0
  packet.fine_time = 0
  
  ;todo add trace to package ....
  
  return, packet

end


pro stx_telemetry_prepare_structure_hc_trace_write, $
  trace=trace, $
  solo_slices=solo_slices, _extra=extra


  ;todo add trace to package ....


end



pro stx_telemetry_prepare_structure_hc_trace_read, trace=trace, $
  solo_slices=solo_slices, _extra=extra
  
  tracetext = ""
  
  ; loop through all solo_slices
  foreach solo_packet, solo_slices do begin

    ; loop through all subheaders
    foreach subheader, (*(*solo_packet.source_data).dynamic_subheaders) do begin
        
        tracetext += string((*subheader.dynamic_tracetext))
       
    endforeach

  endforeach

  ; add last buffer_entry to list
  trace = { $
            type            : 'stx_hc_trace', $
            tracetext       : tracetext $
          }

end



pro stx_telemetry_prepare_structure_hc_trace, solo_slices=solo_slices, $
  trace=trace, _extra=extra

  ; if solo_slices is empty we write telemetry
  if n_elements(solo_slices) eq 0 then begin
    stx_telemetry_prepare_structure_hc_trace_write, solo_slices=solo_slices, $
      trace=trace, _extra=extra

    ; if solo_slices contains data, we are reading telemetry
  endif else begin
    stx_telemetry_prepare_structure_hc_trace_read, solo_slices=solo_slices, $
      trace=trace
  endelse
end

