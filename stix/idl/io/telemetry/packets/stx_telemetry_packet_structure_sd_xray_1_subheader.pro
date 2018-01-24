;+
; :description:
;   This function creates an uninitialized stx_telemetry_packet_structure_sd_x-rayx_1 structure.
;
; :categories:
;    flight software, structure definition, telemetry, x-ray
;
; :returns:
;    an uninitialized stx_telemetry_packet_structure_sd_x-rayx_1 structure
;
; :examples:
;    ...
;
; :history:
;     26-Oct-2016, Simon Marcin (FHNW), initial release
;
;-
function stx_telemetry_packet_structure_sd_xray_1_subheader, packet_word_width=packet_word_width
  packet_word_width = { $
    type                             : 'stx_tmtc_word_width', $
    packet                           : 'stx_tmtc_sd_xray_1', $
    delta_time                       : 16, $
    rate_control_regime              : 8, $
    number_energy_groups             : 5, $ 
    spare                            : 3, $
    number_of_pixel_sets             : 8, $
    pixel_set_index                  : 8, $
    detector_mask                    : 32, $
    duration                         : 16, $
    number_science_data_samples      : 16, $       ; Defines M
    trigger_acc_0                    : 8, $
    trigger_acc_1                    : 8, $
    trigger_acc_2                    : 8, $
    trigger_acc_3                    : 8, $
    trigger_acc_4                    : 8, $
    trigger_acc_5                    : 8, $
    trigger_acc_6                    : 8, $
    trigger_acc_7                    : 8, $
    trigger_acc_8                    : 8, $
    trigger_acc_9                    : 8, $
    trigger_acc_10                   : 8, $
    trigger_acc_11                   : 8, $
    trigger_acc_12                   : 8, $
    trigger_acc_13                   : 8, $
    trigger_acc_14                   : 8, $
    trigger_acc_15                   : 8, $
    ; Start of science data sample
    dynamic_e_low                    : 0UL, $
    dynamic_e_high                   : 0UL, $
    dynamic_spare                    : 0UL, $
    dynamic_counts                   : 0UL, $
    pkg_total_bytes_fixed            : long(0) $
  } ; 584 bits fixed = 73 bytes

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
    type                             : 'stx_tmtc_sd_xray_1', $
    delta_time                       : uint(0), $
    rate_control_regime              : byte(0), $
    number_energy_groups             : uint(0), $       ; Defines E
    spare                            : byte(0), $
    number_of_pixel_sets             : uint(0), $       ; Defines P (Pixels)
    pixel_set_index                  : uint(0), $
    detector_mask                    : ulong(0), $      ; Defines D (Detectors)
    duration                         : uint(0), $
    number_science_data_samples      : uint(0), $       ; Defines M
    trigger_acc_0                    : ulong(0), $
    trigger_acc_1                    : ulong(0), $
    trigger_acc_2                    : ulong(0), $
    trigger_acc_3                    : ulong(0), $
    trigger_acc_4                    : ulong(0), $
    trigger_acc_5                    : ulong(0), $
    trigger_acc_6                    : ulong(0), $
    trigger_acc_7                    : ulong(0), $
    trigger_acc_8                    : ulong(0), $
    trigger_acc_9                    : ulong(0), $
    trigger_acc_10                   : ulong(0), $
    trigger_acc_11                   : ulong(0), $
    trigger_acc_12                   : ulong(0), $
    trigger_acc_13                   : ulong(0), $
    trigger_acc_14                   : ulong(0), $
    trigger_acc_15                   : ulong(0), $
    ; Start of science data sample
    dynamic_e_low                    : ptr_new(), $ ; Array of length E
    dynamic_e_high                   : ptr_new(), $ ; Array of length E
    dynamic_spare                    : ptr_new(), $ ; Array of length E
    dynamic_counts                   : ptr_new(), $ ; List of length E containing Arrays of Pixelsets*Detectors
    pkg_word_width                   : packet_word_width $
  }

  return, packet
end