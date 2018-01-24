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
;     29-Nov-2016, Simon Marcin (FHNW), initial release
;
;-
function stx_telemetry_packet_structure_sd_xray_3_subheader, packet_word_width=packet_word_width
  packet_word_width = { $
    type                             : 'stx_tmtc_word_width', $
    packet                           : 'stx_tmtc_sd_xray_3', $
    delta_time                       : 16, $
    rate_control_regime              : 8, $
    duration                         : 16, $
    number_substructures             : 5, $ 
    spare                            : 7, $
    pixel_mask                       : 12, $
    detector_mask                    : 32, $
    compression_schema_vis           : 8, $        ; +1 spare bit
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
    dynamic_tot_counts               : 0UL, $
    dynamic_vis_real                 : 0UL, $
    dynamic_vis_imaginary            : 0UL, $
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
    type                             : 'stx_tmtc_sd_xray_3', $
    delta_time                       : uint(0), $
    rate_control_regime              : byte(0), $
    duration                         : uint(0), $
    number_substructures             : byte(0), $       ; Defines N
    spare                            : byte(0), $
    pixel_mask                       : uint(0), $       ; Defines P (Pixels)
    detector_mask                    : ulong(0), $      ; Defines D (Detectors)
    compression_schema_vis           : uint(0), $       ; +1 spare bit
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
    dynamic_e_low                    : ptr_new(), $ ; Array of length N
    dynamic_e_high                   : ptr_new(), $ ; Array of length N
    dynamic_spare                    : ptr_new(), $ ; Array of length N
    dynamic_tot_counts               : ptr_new(), $ ; List of length E containing Arrays of Pixelsets*Detectors
    dynamic_vis_real                 : ptr_new(), $ ; List of length E containing Arrays of Pixelsets*Detectors
    dynamic_vis_imaginary            : ptr_new(), $ ; List of length E containing Arrays of Pixelsets*Detectors
    pkg_word_width                   : packet_word_width $
  }

  return, packet
end