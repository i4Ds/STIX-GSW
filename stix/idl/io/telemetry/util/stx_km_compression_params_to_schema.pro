;+
; :DESCRIPTION:
;   this functions generates a schema (16bit value) from the 3 compression parameters k, m and s to be writen to telemetry
;;  
; :CATEGORIES:
;   simulation, writer, telemetry, compression
;
; :PARAMS:
;   k : in, required, type="byte"
;     the k parameter
;
;   m : in, required, type="byte"
;     the m parameter
;
;   s : in, required, type="byte"
;     the s parameter
;
; :HISTORY:
;    10-Oct-2015 - Nicky Hochmuth (FHNW), initial release
;-
function stx_km_compression_params_to_schema, k, m, s, config=config
  
  if keyword_set(config) then begin
    default, k, config[1]
    default, m, config[2]
    default, s, config[0]
  endif

  return, ishft(s, 6) or ishft(k, 3) or m
end