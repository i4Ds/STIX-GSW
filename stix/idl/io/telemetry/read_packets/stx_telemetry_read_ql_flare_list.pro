;+
; :description:
;   this function reads the ql varaince specific information
;
; :categories:
;   simulation, reader, telemetry, quicklook, ql, variance
;
; :params:
;   light_curve_packet_structure : in, required, type="stx_telemetry_packet_structure_ql_flare_list"
;     the input ql variance
;
;   tmr : in, required, type="stx_telemetry_reader"
;     an open telemerty_reader object
;
; :history:
;    08-Dec-2015 - Simon Marcin (FHNW), initial release
;-

function stx_telemetry_read_ql_flare_list, solo_packet=solo_packet, tmr=tmr, _extra=extra
  ppl_require, in=solo_packet, type='stx_tmtc_solo_source_packet_header'

  ; create emtpy ql_flare_list packet
  ql_flare_list_packet = stx_telemetry_packet_structure_ql_flare_list()

  ; auto fill packet
  tmr->auto_read_structure, packet=ql_flare_list_packet, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*']

  ; automatically override the default values with the read values
  tmr->auto_override_common_fields, solo_packet=solo_packet, data_packet=ql_flare_list_packet

  ; set solo packet size to this packet header, to allow for calculating the dynamic packet size later
  ; 'stop' should never be encountered
  if(solo_packet.pkg_word_width.source_data gt 0) then stop $
  else solo_packet.pkg_word_width.source_data = ql_flare_list_packet.pkg_word_width.pkg_total_bytes_fixed * 8

  ; prepare data pointers for flare_list
   ql_flare_list_packet.dynamic_start_coarse = ptr_new(lon64arr(ql_flare_list_packet.number_of_flares))
   ql_flare_list_packet.dynamic_start_fine   = ptr_new(uintarr(ql_flare_list_packet.number_of_flares))
   ql_flare_list_packet.dynamic_end_coarse   = ptr_new(lon64arr(ql_flare_list_packet.number_of_flares))
   ql_flare_list_packet.dynamic_end_fine     = ptr_new(uintarr(ql_flare_list_packet.number_of_flares))
   ql_flare_list_packet.dynamic_high_flag    = ptr_new(bytarr(ql_flare_list_packet.number_of_flares))
   ql_flare_list_packet.dynamic_nbr_packets  = ptr_new(bytarr(ql_flare_list_packet.number_of_flares))
   ql_flare_list_packet.dynamic_spare        = ptr_new(bytarr(ql_flare_list_packet.number_of_flares))
   ql_flare_list_packet.dynamic_processed    = ptr_new(bytarr(ql_flare_list_packet.number_of_flares))
   ql_flare_list_packet.dynamic_compression  = ptr_new(bytarr(ql_flare_list_packet.number_of_flares))
   ql_flare_list_packet.dynamic_transmitted  = ptr_new(bytarr(ql_flare_list_packet.number_of_flares))

  ; process all lightcurves
  for i = 0L, ql_flare_list_packet.number_of_flares-1 do begin

    ; dynamic_start_coarse: read 32 bits
    val = tmr->read(size(long64(0), /type), bits=32, debug=debug, silent=silent)
    (*ql_flare_list_packet.dynamic_start_coarse)[i] = val

    ; dynamic_start_fine: read 16 bits
    val = tmr->read(size(uint(0), /type), bits=16, debug=debug, silent=silent)
    (*ql_flare_list_packet.dynamic_start_fine)[i] = val
    
    ; dynamic_end_coarse: read 32 bits
    val = tmr->read(size(long64(0), /type), bits=32, debug=debug, silent=silent)
    (*ql_flare_list_packet.dynamic_end_coarse)[i] = val
    
    ; dynamic_end_fine: read 16 bits
    val = tmr->read(size(uint(0), /type), bits=16, debug=debug, silent=silent)
    (*ql_flare_list_packet.dynamic_end_fine)[i] = val
    
    ; dynamic_high_flag: read 32 bits
    val = tmr->read(size(byte(0), /type), bits=8, debug=debug, silent=silent)
    (*ql_flare_list_packet.dynamic_high_flag)[i] = val
    
    ; dynamic_nbr_packets: read 32 bits
    val = tmr->read(size(byte(0), /type), bits=8, debug=debug, silent=silent)
    (*ql_flare_list_packet.dynamic_nbr_packets)[i] = val
    
    ; dynamic_spare: read 32 bits
    val = tmr->read(size(byte(0), /type), bits=4, debug=debug, silent=silent)
    (*ql_flare_list_packet.dynamic_spare)[i] = val
    
    ; dynamic_processed: read 32 bits
    val = tmr->read(size(byte(0), /type), bits=1, debug=debug, silent=silent)
    (*ql_flare_list_packet.dynamic_processed)[i] = val
    
    ; dynamic_compression: read 32 bits
    val = tmr->read(size(byte(0), /type), bits=2, debug=debug, silent=silent)
    (*ql_flare_list_packet.dynamic_compression)[i] = val
    
    ; dynamic_transmitted: read 32 bits
    val = tmr->read(size(byte(0), /type), bits=1, debug=debug, silent=silent)
    (*ql_flare_list_packet.dynamic_transmitted)[i] = val

  endfor

  ;  if(n_structs ne 0) then message, 'Incorrect alignment of expected number of structures and actual number of structures'
  ;  if(total_data_bytes_read ne data_dynlen) then message, 'Incorrect alignment of counted total bytes and calculated total byte length'

  return, ql_flare_list_packet
end