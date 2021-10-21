;+
; :Name:
;   STX_KM_COMPRESS_RANGE
;   Valid_Range = stx_km_compress_range( k, m, s, error = error )
; :Description:
;    This function returns the valid range for compression of integer data. See STX_KM_COMPRESS() for more information
; :Params:
;    
;    k - number of bits for the exponent, default is 4
;    m - number of bits for the mantissa, default is 8-k
;    s - if set, then both positive and negative integers can be compressed, default is 0
;
; :Keywords:
;    error - returns 0 if successful, 1 for early termination
;
; :Author: richard.schwartz@nasa.gov
;
; :History: 4-oct-2016, initial version
; 8-dec-2016, fixed error in max_value computation that affected computation for s = 1
; 
;-
function stx_km_compress_range, k, m, s, error = error

  error = 1
  
  default, k, 4
  default, m, 8 - k
  default, s, 0
  kms = k + m + s
  if kms gt 8 then begin
    print, 'k, m, s must total le 8 to be valid '
    print, 'Their total is ', kms
    return, -1 ; error condition
  endif
  max_value = 2LL^(2LL^K-2)  * (2LL^(M+1) -1)
  abs_range = s eq 0 ? [0, max_value] : [-1, 1] * max_value
  ;real max values
  
  return, abs_range
  end