;+
; :description:
;   this routine reads the xray 3 specific information
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
;    29-Nov-2016 - Simon Marcin (FHNW), initial release
;-

function stx_telemetry_read_sd_xray_3, solo_packet=solo_packet, tmr=tmr, _extra=extra
  ppl_require, in=solo_packet, type='stx_tmtc_solo_source_packet_header'

  ; create emtpy xray_header
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
  for i = 0L, sd_xray_packet.number_time_samples-1 do begin

    ; create emtpy xray_0 packet
    sub = stx_telemetry_packet_structure_sd_xray_3_subheader()

    ; auto fill packet
    tmr->auto_read_structure, packet=sub, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*']

    ; prepare data pointers for science samples
    sub.dynamic_e_low = ptr_new(bytarr(sub.number_energy_groups))
    sub.dynamic_e_high = ptr_new(bytarr(sub.number_energy_groups))
    sub.dynamic_tot_counts = ptr_new(bytarr(sub.number_energy_groups))
    sub.dynamic_number_detectors = ptr_new(lonarr(sub.number_energy_groups))
    
    sub.dynamic_detector_id = ptr_new(list())
    sub.dynamic_vis_real = ptr_new(list())
    sub.dynamic_vis_imaginary = ptr_new(list())
    
    ; process dynamic science dataslices
    for j = 0L, sub.number_energy_groups-1 do begin

      ; e_low: read 2 bits
      val = tmr->read(1, bits=8, debug=debug, silent=silent)
      (*sub.dynamic_e_low)[j] = val

      ; e_high: read 5 bits
      val = tmr->read(1, bits=8, debug=debug, silent=silent)
      (*sub.dynamic_e_high)[j] = val

      ; flux: read 8 bits
      val = tmr->read(1, bits=8, debug=debug, silent=silent)
      (*sub.dynamic_tot_counts)[j] = val
      
      ; n detectors: read 8 bits
      n_det = tmr->read(1, bits=8, debug=debug, silent=silent)
      (*sub.dynamic_number_detectors)[j] = n_det   
      
      detector_id = bytarr(n_det)
      vis_real = ULONARR(n_det)
      vis_imaginary = ULONARR(n_det)
            

      ; counts: read 8 bits each
      for idx_D = 0, n_det -1 do begin
          val = tmr->read(1, bits=8, debug=debug, silent=silent)
          detector_id[idx_D] = val
          
          val = tmr->read(1, bits=8, debug=debug, silent=silent)
          vis_real[idx_D] = val
          
          val = tmr->read(1, bits=8, debug=debug, silent=silent)
          vis_imaginary[idx_D] = val
      endfor
      
      (*sub.dynamic_detector_id).add, detector_id
      (*sub.dynamic_vis_real).add, vis_real
      (*sub.dynamic_vis_imaginary).add, vis_imaginary
      
    endfor

    ; add subheader to list
    subheaders.add, sub

  endfor

  ; attach list to sd_xray_packet
  sd_xray_packet.dynamic_subheaders = ptr_new(subheaders)

  return, sd_xray_packet
end