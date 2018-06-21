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
;    19-Jun-2018 - Nicky Hochmuth (FHNW) align with ICD    
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
  
  if ql_flare_list_packet.number_of_flares gt 0 then begin
  
    ; prepare data pointers for flare_list
     ql_flare_list_packet.dynamic_start_coarse = ptr_new(lon64arr(ql_flare_list_packet.number_of_flares))
     ql_flare_list_packet.dynamic_end_coarse   = ptr_new(lon64arr(ql_flare_list_packet.number_of_flares))
     ql_flare_list_packet.dynamic_high_flag    = ptr_new(bytarr(ql_flare_list_packet.number_of_flares))
     ql_flare_list_packet.dynamic_tm_volume    = ptr_new(lon64arr(ql_flare_list_packet.number_of_flares))
     ql_flare_list_packet.dynamic_avg_cfl_z    = ptr_new(intarr(ql_flare_list_packet.number_of_flares))
     ql_flare_list_packet.dynamic_avg_cfl_y    = ptr_new(intarr(ql_flare_list_packet.number_of_flares))
     ql_flare_list_packet.dynamic_processing_status  = ptr_new(bytarr(ql_flare_list_packet.number_of_flares))
     
     ; process all flares
     for i = 0L, ql_flare_list_packet.number_of_flares-1 do begin

       ; dynamic_start_coarse: read 32 bits
       val = tmr->read(size(long64(0), /type), bits=32, debug=debug, silent=silent)
       (*ql_flare_list_packet.dynamic_start_coarse)[i] = val

       ; dynamic_end_coarse: read 32 bits
       val = tmr->read(size(long64(0), /type), bits=32, debug=debug, silent=silent)
       (*ql_flare_list_packet.dynamic_end_coarse)[i] = val

       ; dynamic_high_flag: read 8 bits
       val = tmr->read(size(byte(0), /type), bits=8, debug=debug, silent=silent)
       (*ql_flare_list_packet.dynamic_high_flag)[i] = val

       ; dynamic_tm_volume: read 32 bits
       val = tmr->read(size(byte(0), /type), bits=32, debug=debug, silent=silent)
       (*ql_flare_list_packet.dynamic_tm_volume)[i] = val

       ; dynamic_avg_cfl_z: read 32 bits
       val = tmr->read(size(fix(0), /type), bits=8, debug=debug, silent=silent)
       (*ql_flare_list_packet.dynamic_avg_cfl_z)[i] = val

       ; dynamic_avg_cfl_y: read 32 bits
       val = tmr->read(size(fix(0), /type), bits=8, debug=debug, silent=silent)
       (*ql_flare_list_packet.dynamic_avg_cfl_y)[i] = val

       ; dynamic_processing_status: read 8 bits
       val = tmr->read(size(byte(0), /type), bits=8, debug=debug, silent=silent)
       (*ql_flare_list_packet.dynamic_processing_status)[i] = val

     endfor
  endif else begin
    ql_flare_list_packet.dynamic_start_coarse = ptr_new(ulong64(0))
    ql_flare_list_packet.dynamic_end_coarse   = ptr_new(ulong64(0))
    ql_flare_list_packet.dynamic_high_flag    = ptr_new(byte(0))
    ql_flare_list_packet.dynamic_tm_volume    = ptr_new(uint(0))
    ql_flare_list_packet.dynamic_avg_cfl_z    = ptr_new(fix(0))
    ql_flare_list_packet.dynamic_avg_cfl_y    = ptr_new(fix(0))
    ql_flare_list_packet.dynamic_processing_status  = ptr_new(byte(0))
  endelse

  ;  if(n_structs ne 0) then message, 'Incorrect alignment of expected number of structures and actual number of structures'
  ;  if(total_data_bytes_read ne data_dynlen) then message, 'Incorrect alignment of counted total bytes and calculated total byte length'

  return, ql_flare_list_packet
end