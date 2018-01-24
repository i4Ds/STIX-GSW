;+
; :description:
;     
;
; :params:
;     array            : in, byte array with individual bits 
;
; :returns:
;     number           :  an ulong number
; 
; :history:
;     17-Jun-2015 - Marek Steslicki (Wro), initial release
;
;-


function stx_sim_egse_bitarray2number, array
 
 number=ulong(0)
 base=ulong(2)
 for i=0,n_elements(array)-1 do begin
  number+=array[i]*base^i
 endfor
 return,number
 
end
