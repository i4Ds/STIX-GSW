;+
; :DESCRIPTION:
;   this functions tests if a given set or scalar of values has been compressed and uncompressed right (with the same parameters)
;   
;   the original value is compressed with the given parameters
;   that compressed value is in- and decremented by 1 and the decompression of that range defindes the band within the passed decompressed value should be 
;   
;   
; :CATEGORIES:
;   simulation, writer, telemetry, compression
;
; :PARAMS:
;   k : in, optional, type="byte", default=4
;     the k compression parameter
;
;   m : in, optional, type="byte", default=4
;     the m compression parameter
;
;   s : in, optional, type="byte", default=0
;     the s compression parameter
;
; :KEYWORDS:
;   all : in, optional, type="bool", default="0"
;     should the return value compressed to a global test or for each scalar separate 
;     
;   schema : in, optional, type="int"
;     all 3 compression parameters in a single telemetry format (schema)
;     will overrid k, m and s
;     
; :HISTORY:
;    10-Oct-2015 - Nicky Hochmuth (FHNW), initial release
;-
function stx_km_compress_test, original, decompressed, k, m, s, all=all, schema=schema
  
  default, all, 0
  
  default, k, 4
  default, m, 8 - k
  default, s, 0
  
  if keyword_set(schema) then begin
      stx_km_compression_schema_to_params, schema,  k=k, m=m, s=s
  endif
  
  compressed = stx_km_compress(original, k, m, s)
  decompressed_low_bound = stx_km_decompress(compressed - 1, k, m, s)
  
  decompressed_high_bound = stx_km_decompress(compressed + 1, k, m, s)
  
  test = original gt decompressed_low_bound AND original lt decompressed_high_bound
  
  return, all ? total(test) eq n_elements(test) : test
  
end