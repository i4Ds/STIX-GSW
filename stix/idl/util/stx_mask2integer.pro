;+
; :Description:
;    Sets the bits in a l64 longword according to the bytes in the input
;    Works on mask arrays as well as single masks
;
; :Params:
;    inmsk - 2d mask array or single 1d byte mask 
;
; :Examples:
;    IDL> inmsk = bytarr(32)+1b
;    IDL> print, stx_mask2integer( inmsk )
;    % Compiled module: STX_MASK2INTEGER.
;    4294967295
;    IDL> inmsk = rebin( reform( inmsk, 32,1), 32,2)
;    IDL> print, stx_mask2integer( inmsk )
;    4294967295            4294967295
;
; :Author: rschwartz70@gmail.com
; :History: 6-aug-2020, Hirshima
;-
function stx_mask2integer, inmsk

  dim = size( inmsk, /dim)
  dim = n_elements( dim ) eq 1 ? [dim, 1] : dim
  ints = ulon64arr( dim[1] )
  nmask = dim[0]
  nmask = reproduce( indgen(nmask), dim[1])
  result = total( 2ul^nmask * inmsk, 1,/integer)
  return, result
end