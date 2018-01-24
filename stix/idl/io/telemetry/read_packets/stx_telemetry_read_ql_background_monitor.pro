;+
; :description:
;   this routine reads the background_monitor specific information
;
; :categories:
;   simulation, reader, telemetry, quicklook, background_monitor
;
; :params:
;   background_monitor_packet_structure : in, required, type="stx_telemetry_packet_structure_ql_background_monitor"
;     the input background_monitor
;
;   tmr : in, required, type="stx_telemetry_reader"
;     an open telemerty_reader object
;
; :history:
;    10-Dec-2015 - Simon Marcin (FHNW), initial release
;    20-Sept-2016 - Simon Marcin (FHNW), added new fields according to TMTC I3R1
;-

function stx_telemetry_read_ql_background_monitor, solo_packet=solo_packet, tmr=tmr, _extra=extra
  ppl_require, in=solo_packet, type='stx_tmtc_solo_source_packet_header'

  ; create emtpy ql_background_monitor packet
  ql_background_monitor_packet = stx_telemetry_packet_structure_ql_background_monitor()

  ; auto fill packet
  tmr->auto_read_structure, packet=ql_background_monitor_packet, tag_ignore=['type', 'pkg_.*', 'dynamic_.*', 'header_.*', 'number_of_triggers']

  ; automatically override the default values with the read values
  tmr->auto_override_common_fields, solo_packet=solo_packet, data_packet=ql_background_monitor_packet

  ; set solo packet size to this packet header, to allow for calculating the dynamic packet size later
  ; 'stop' should never be encountered
  if(solo_packet.pkg_word_width.source_data gt 0) then stop $
  else solo_packet.pkg_word_width.source_data = ql_background_monitor_packet.pkg_word_width.pkg_total_bytes_fixed

  ; extract pixel, energy_bin and detector mask
   stx_telemetry_util_encode_decode_structure, input=ql_background_monitor_packet.energy_bin_mask, $
    energy_bin_mask=energy_bin_mask, number_energy_bins=number_energy_bins


  ; dynamic_nbr_of_data_points: read 16 bits
  val = tmr->read(size(uint(0), /type), bits=16, debug=debug, silent=silent)
  ql_background_monitor_packet.dynamic_nbr_of_data_points = val

  ; as we peeded 16 bits we have to skip these inside of the loop
  peeked=1

  ; prepare data pointers for background
  ql_background_monitor_packet.dynamic_background = ptr_new(bytarr(ql_background_monitor_packet.number_of_energies,ql_background_monitor_packet.dynamic_nbr_of_data_points)-1)

  ; process all lightcurves
  for j = 0L, ql_background_monitor_packet.number_of_energies-1 do begin
    if not peeked then begin
      ; dynamic_nbr_of_data_points: read 16 bits
      val = tmr->read(size(uint(0), /type), bits=16, debug=debug, silent=silent)
      ;ql_background_monitor_packet.dynamic_nbr_of_data_points = val
    endif
    peeked = 0
    ; read 8 bits for each dynamic_background
    for i = 0L, ql_background_monitor_packet.dynamic_nbr_of_data_points-1 do begin
      val = tmr->read(size(byte(0), /type), bits=8, debug=debug, silent=silent)
      (*ql_background_monitor_packet.dynamic_background)[j,i] = val
    endfor
  endfor


  ; number_of_triggers: read 16 bits
  val = tmr->read(size(uint(0), /type), bits=16, debug=debug, silent=silent)
  ql_background_monitor_packet.number_of_triggers = val
  ql_background_monitor_packet.dynamic_trigger_accumulator = ptr_new(bytarr(ql_background_monitor_packet.number_of_triggers)-1)
  ; read 8 bits for each trigger_accumulator
  for i = 0L, ql_background_monitor_packet.number_of_triggers-1 do begin
    val = tmr->read(size(byte(0), /type), bits=8, debug=debug, silent=silent)
    (*ql_background_monitor_packet.dynamic_trigger_accumulator)[i] = val
  endfor


  return, ql_background_monitor_packet
end