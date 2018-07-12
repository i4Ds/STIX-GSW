;+
; :description:
;   This function creates an uninitialized stx_telemetry_packet_structure_sd_x-rayx_0 structure.
;
; :categories:
;    flight software, structure definition, telemetry, x-ray
;
; :returns:
;    an uninitialized stx_telemetry_packet_structure_sd_x-rayx_0 structure
;
; :examples:
;    ...
;
; :history:
;     22-Mar-2016, Simon Marcin (FHNW), initial release
;     01-May-2018, Laszlo I. Etesi (FHNW), updated in accordance with ICD
;
;-
function stx_telemetry_packet_structure_sd_xray_0_subheader, packet_word_width=packet_word_width
  packet_word_width = { $
    type                             : 'stx_tmtc_word_width', $
    packet                           : 'stx_tmtc_sd_xray_0', $
    starting_time                    : 16, $
    rate_control_regime              : 8, $
    duration                         : 16, $
    spare                            : 4, $
    pixel_mask                       : 12, $
    detector_mask                    : 32, $
    trigger_acc_0                    : 32, $
    trigger_acc_1                    : 32, $
    trigger_acc_2                    : 32, $
    trigger_acc_3                    : 32, $
    trigger_acc_4                    : 32, $
    trigger_acc_5                    : 32, $
    trigger_acc_6                    : 32, $
    trigger_acc_7                    : 32, $
    trigger_acc_8                    : 32, $
    trigger_acc_9                    : 32, $
    trigger_acc_10                   : 32, $
    trigger_acc_11                   : 32, $
    trigger_acc_12                   : 32, $
    trigger_acc_13                   : 32, $
    trigger_acc_14                   : 32, $
    trigger_acc_15                   : 32, $
    number_science_data_samples      : 16, $       ; Defines M
    ; Start of science data sample
    dynamic_pixel_id                 : 0UL, $ ; dynamic, will be filled during execution with M*4 bits
    dynamic_detector_id              : 0UL, $ ; dynamic, will be filled during execution with M*5 bits
    dynamic_energy_id                : 0UL, $ ; dynamic, will be filled during execution with M*5 bits
    dynamic_continuation_bits        : 0UL, $ ; dynamic, will be filled during execution with M*2 bits
    dynamic_counts                   : 0UL, $ ; dynamic, will be filled during execution with M*(0 to 2) bits   
    pkg_total_bytes_fixed            : long(0) $
  } ; 616 bits fixed = 77 bytes

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
    type                             : 'stx_tmtc_sd_xray_0', $
    starting_time                    : uint(0), $
    rate_control_regime              : byte(0), $
    duration                         : uint(0), $
    spare                            : byte(0), $
    pixel_mask                       : uint(0), $
    detector_mask                    : ulong(0), $
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
    number_science_data_samples      : uint(0), $       ; Defines M
    ; Start of science data sample
    dynamic_pixel_id                 : ptr_new(), $ ; Array of length M
    dynamic_detector_id              : ptr_new(), $ ; Array of length M
    dynamic_energy_id                : ptr_new(), $ ; Array of length M
    dynamic_continuation_bits        : ptr_new(), $ ; Array of length M
    dynamic_counts                   : ptr_new(), $ ; Array of length M
    pkg_word_width                   : packet_word_width $
  }

  return, packet
end