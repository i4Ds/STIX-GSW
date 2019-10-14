;+
; :description:
;   This function creates an uninitialized stx_telemetry_packet_structure_sd_x-rayx_0 structure.
;
; :categories:
;    flight software, structure definition, telemetry, trave HC
;
; :returns:
;    an uninitialized stx_telemetry_packet_structure_sd_x-rayx_0 structure
;
; :examples:
;    ...
;
; :history:
;     31-Aug-2018, Nicky Hochmuth (FHNW), initial release
;
;-
function stx_telemetry_packet_structure_hc_trace, packet_word_width=packet_word_width
  packet_word_width = { $
    type                             : 'stx_tmtc_word_width', $
    packet                           : 'stx_tmtc_hc_trace', $
    length                           : 16, $
    dynamic_tracetext                : 0UL, $ ; dynamic, will be filled during execution with length bytes
    pkg_total_bytes_fixed            : long(0) $
  } 

  tags = strlowcase(tag_names(packet_word_width))

  ; definition of ignored packets for size calculation
  ignore = arr2str('^' + ['type', 'packet', 'header_.*', 'dynamic_*', 'pkg_.*'] + '$', delimiter='|')

  ; compute pkg_total_bytes_fixed
  for i = 0L, n_tags(packet_word_width)-1 do begin
    if(stregex(tags[i], ignore , /boolean)) then continue $
    else packet_word_width.pkg_total_bytes_fixed += packet_word_width.(i)
  endfor

  ; transform bits to bytes
  if (packet_word_width.pkg_total_bytes_fixed MOD 8 gt 0) then message, 'bits are no multiple of 8'
  packet_word_width.pkg_total_bytes_fixed /= 8

  packet = { $
    type                             : 'stx_tmtc_hc_trace', $
    length                           : uint(0), $ defines M
  
    ; Start of science data sample
    dynamic_tracetext                 : ptr_new(), $ ; Array of length M
    pkg_word_width                   : packet_word_width $
  }

  return, packet
end