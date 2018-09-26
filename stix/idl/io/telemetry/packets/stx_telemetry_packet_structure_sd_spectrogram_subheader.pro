;+
; :description:
;   This function creates an uninitialized stx_telemetry_packet_structure_sd_spectrogram structure.
;
; :categories:
;    flight software, structure definition, telemetry, spectrogram
;
; :returns:
;    an uninitialized stx_telemetry_packet_structure_sd_spectrogram structure
;
; :examples:
;    ...
;
; :history:
;     07-Oct-2016, Simon Marcin (FHNW), initial release
;
;-
function stx_telemetry_packet_structure_sd_spectrogram_subheader, packet_word_width=packet_word_width
  packet_word_width = { $
    type                             : 'stx_tmtc_word_width', $
    packet                           : 'stx_tmtc_sd_spectrogram', $
    pixel_mask                       : 16, $
    detector_mask                    : 32, $
    rcr                              : 8, $
    energy_low                       : 6, $       ; number e bin Defines M (first bit  spare)
    energy_high                      : 5, $       ; number e bin Defines M
    energy_unit                      : 5, $       ; number e bin Defines M
    number_samples                   : 16, $       ; Defines N
    ; Start of science data sample
    dynamic_delta_time               : 0UL, $ 
    dynamic_trigger                  : 0UL, $
    dynamic_counts                   : 0UL, $ ; dynamic, will be filled during execution with M bytes
    closing_time_offset              : 16, $
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
    type                             : 'stx_tmtc_sd_spectrogram', $
    pixel_mask                       : uint(0), $
    detector_mask                    : ulong64(0), $
    rcr                              : byte(0), $
    energy_low                       : byte(0), $       ; number e bin Defines M (first bit  spare)
    energy_high                      : byte(0), $       ; number e bin Defines M
    energy_unit                      : byte(0), $       ; number e bin Defines M
    number_samples                   : uint(0), $       ; Defines N
    ; Start of science data sample
    dynamic_delta_time               : ptr_new(), $ 
    dynamic_trigger                  : ptr_new(), $
    dynamic_counts                   : ptr_new(), $
    closing_time_offset              : uint(0), $
    pkg_word_width                   : packet_word_width $
  }

  return, packet
end