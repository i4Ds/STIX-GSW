;+
; :description:
;    Create a new stx_telemetry_writer object
;
; :returns:
;   the new stx_telemetry_writer
;-
function stx_telemetry_writer, size=size, filename=filename
  return , obj_new('stx_telemetry_writer',size=size, filename=filename)
end