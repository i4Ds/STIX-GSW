;+
; :Name:
;   stx_demo_telemetry_hc_regular_mini
;
; :Description:
;    Demo of the telemetry hc_regular_mini routines.
;
; :Categories:
;    simulation, reader, telemetry, house keeping
;
; :Params:
;
; :Examples:
; This is working example :) stx_demo_telemetry_hc_regular_mini
;
; :Keywords:
;    error - returns 0 if successful, 1 for early termination
;
; :History:
;     24-Aug-2016 - Simon Marcin (FHNW), initial release
;-

pro stx_demo_telemetry_esc

  ; create the telemetry reader object
  tmr = stx_telemetry_reader(filename='hktm_2016_08_10.bin')

  ; getdata
  tmr->getdata, asw_hc_regular_mini= asw_hc_regular_mini, solo_packets = solo_packets, $
    asw_hc_heartbeat=asw_hc_heartbeat, statistics = statistics

  ; destroy reader object
  destroy, tmr
    
  stop
  
end