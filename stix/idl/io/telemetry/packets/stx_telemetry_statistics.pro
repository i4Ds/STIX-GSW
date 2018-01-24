;+
; :description:
;   structure that contains statistics about telemetry packets
;
; :categories:
;    telemetry
;
; :returns:
;    an uninitialized structure
;
; :history:
;     24-Aug-2016 - Simon Marcin (FHNW), init
;
;-
function stx_telemetry_statistics, packet_type, s_time

  return, { $
    type                             : 'stx_telemetry_statistics', $
    packet                           : packet_type, $
    start_time                       : s_time, $
    nbr_of_packets                   : ulong(0) $
  }

end
