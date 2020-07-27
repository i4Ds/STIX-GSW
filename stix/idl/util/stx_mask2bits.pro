;+
; :description:
;    This routine converts bitsmaks to byte array mask and vice versa 
;    
; :categories:
;    STIX, UTILS
;
; :examples:
;    b = bytarr(32)
;    b[[1,6,7,8,30]]=1
;    print, b, stx_mask2bits(stx_mask2bits(b), /reverse)
;     
; :history:
;    11-Seb-2014 - Nicky Hochmuth (FHNW), initial release
;    02-Oct-2014 - Nicky Hochmuth (FHNW), add script keyword
;    
; :params:
;    in : in, required, type="bytearray | ulong"
;        a byte array with 0 or 1 entries in case of reverse=0
;        a ulong bitmask in case of reverse=1
;        
; :keywords:
;    reverse : in, optional, type="flag 0|1", default=0
;        if not set: byte array mask -> bit mask 
;        if set: bit mask -> byte array mask
;    
;    script : out, optional, type="int_array", default=-1
;        all indexes where the mask is gt 0
;    
;     mask_length : in, optional, type="flag 0|1", default=32 (detectors)
;       the length of byte array
;       12 for pixel mask
;       ignored if reverse is not set
;        
;
; :returns:
;   a bit mask or byte array mask
;   
; :history:
;     09-Oct-2016, Simon Marcin (FHNW), changed type to ulong64 in order to support
;                  33 bit long energy_bin_masks
;-

function stx_mask2bits, in, reverse=reverse, mask_length=mask_length, script=script
  default, mask_length, 32
   
  if keyword_set(reverse) then begin
    bytes = byte(ishft(in, -indgen(mask_length)) and 1b)
    if arg_present(script) then script = where(bytes gt 0)
    return, bytes
  end
  ;else
  if arg_present(script) then script = where(in gt 0)
  return, ulong64(total(in * ( ulong64(2)^indgen(n_elements(in)) ), /int))
end