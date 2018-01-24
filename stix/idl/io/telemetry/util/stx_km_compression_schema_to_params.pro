;+
; :DESCRIPTION:
;   this procedure generates a the 3 compression parameters k, m and s from a telemetry scheme (16bit value)
;;
; :CATEGORIES:
;   simulation, writer, telemetry, compression
;
; :PARAMS:
;   schema : in, required, type="int"
;     the telemetry schema 
;
; :KEYWORDS:
;   k : out, optional, type="byte"
;     the k parameter
;
;   m : out, optional, type="byte"
;     the m parameter
;
;   s : out, optional, type="byte"
;     the s parameter
;
; :HISTORY:
;    10-Oct-2015 - Nicky Hochmuth (FHNW), initial release
;-
pro stx_km_compression_schema_to_params, schema, k=k, m=m, s=s
    
  k = fix(ishft(schema,-3) and 7)
  m = fix(schema and 7)
  s = fix(ishft(schema,-6) and 3)
  
end

