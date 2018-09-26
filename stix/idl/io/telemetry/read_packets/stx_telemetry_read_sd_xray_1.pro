;+
; :description:
;   this routine reads the xray 1 specific information
;
; :categories:
;   simulation, reader, telemetry, science data, xray
;
; :params:
;   solo_packet : in, required, type="stx_telemetry_packet_structure_solo_source_packet_header"
;     the input xray solo packe
;
;   tmr : in, required, type="stx_telemetry_reader"
;     an open telemerty_reader object
;
; :history:
;    07-Oct-2016 - Simon Marcin (FHNW), initial release
;-

function stx_telemetry_read_sd_xray_1, solo_packet=solo_packet, tmr=tmr, lvl_2=lvl_2, _extra=extra
  ppl_require, in=solo_packet, type='stx_tmtc_solo_source_packet_header'

  ; create emtpy ql_light_curve packet
  sd_xray_packet = stx_telemetry_packet_structure_sd_xray_header()

  ; auto fill packet
  tmr->auto_read_structure, packet=sd_xray_packet, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*']

  ; automatically override the default values with the read values
  tmr->auto_override_common_fields, solo_packet=solo_packet, data_packet=sd_xray_packet

  ; set solo packet size to this packet header, to allow for calculating the dynamic packet size later
  ; 'stop' should never be encountered
  if(solo_packet.pkg_word_width.source_data gt 0) then stop $
  else solo_packet.pkg_word_width.source_data = sd_xray_packet.pkg_word_width.pkg_total_bytes_fixed

  ; create a list for multiple subheaders
  subheaders = list()

  ; process all subheaders
  
  ;print, "time_bins in packet: ", sd_xray_packet.number_time_samples
  
  for i = 0L, sd_xray_packet.number_time_samples-1 do begin

    ; create emtpy xray_0 packet
    sub = stx_telemetry_packet_structure_sd_xray_1_subheader()
    if keyword_set(lvl_2) then sub.type = 'stx_tmtc_sd_xray_2'

    ; auto fill packet until pixel descriptors
    tmr->auto_read_structure, packet=sub, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*', 'detector_mask', 'duration', 'trigger_.*','number_energy_groups']

    ; get dynamic lenghts
    loop_P = sub.number_of_pixel_sets

    sub.dynamic_pixel_sets = ptr_new(ulonarr(loop_P))
    ; process dynamic pixel sets
    for j = 0L, loop_P-1 do begin
      ; pixel descriptor: read 16 bits
      val = tmr->read(0, bits=16, debug=debug, silent=silent)
      (*sub.dynamic_pixel_sets)[j] = val
    endfor

    
    ; auto fill packet from pixel descriptors to the end
    tmr->auto_read_structure, packet=sub, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*', 'delta_time', 'rate_control_regime', 'number_of_pixel_sets']
    
    loop_D = fix(total(stx_mask2bits(sub.detector_mask,mask_length=32, /reverse)))

    ; prepare data pointers for science samples
    sub.dynamic_e_low = ptr_new(bytarr(sub.number_energy_groups))
    sub.dynamic_e_high = ptr_new(bytarr(sub.number_energy_groups))
    sub.dynamic_n_counts = ptr_new(uintarr(sub.number_energy_groups))
    sub.dynamic_counts = ptr_new(intarr(loop_P,loop_D,sub.number_energy_groups))

    ; process dynamic science dataslices
    for j = 0L, sub.number_energy_groups-1 do begin

      ; e_low: read 8 bits
      val = tmr->read(1, bits=8, debug=debug, silent=silent)
      (*sub.dynamic_e_low)[j] = val

      ; e_high: read 8 bits
      val = tmr->read(1, bits=8, debug=debug, silent=silent)
      (*sub.dynamic_e_high)[j] = val

      ; spare: read 16 bits
      val = tmr->read(0, bits=16, debug=debug, silent=silent)
      (*sub.dynamic_n_counts)[j] = val
                  
      assert_equals, (*sub.dynamic_n_counts)[j],  loop_D * loop_P, "repeater number for counts does not match"
        
      ; counts: read 8 bits each
      for idx_D = 0, loop_D -1 do begin
        for idx_P = 0, loop_P -1 do begin
          val = tmr->read(1, bits=8, debug=debug, silent=silent)
          (*sub.dynamic_counts)[idx_P,idx_D,j] = val
        endfor
      endfor
           
    endfor

    ; add subheader to list
    subheaders.add, sub

  endfor

  ; attach list to sd_xray_packet
  sd_xray_packet.dynamic_subheaders = ptr_new(subheaders)

  return, sd_xray_packet
end