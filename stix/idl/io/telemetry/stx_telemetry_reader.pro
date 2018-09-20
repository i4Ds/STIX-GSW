;+
; :description:
;    Create a new stx_telemetry_reader object
;
; :returns:
;   the new stx_telemetry_reader
;-
function stx_telemetry_reader, stream=stream, filename=filename, buffersize=buffersize, scan_mode=scan_mode, merge_mode=merge_mode
  return , obj_new('stx_telemetry_reader',stream=stream, filename=filename, buffersize=buffersize, scan_mode=scan_mode, merge_mode=merge_mode)
end