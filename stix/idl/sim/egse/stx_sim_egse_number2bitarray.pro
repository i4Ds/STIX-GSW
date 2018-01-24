;+
; :description:
;     This function converts a event data to the egse event format only integer numbers
;
; :params:
;     number            : in, required, integer number to be converted to the bit array    
;     number_of_bits    : in, optional, number of bits in the array, default: minimum number of necessary bits
;
;
; :keywords:
;     reverse           : return reverse table
; 
; :returns:
;     output            :  byte array with individual bits
; 
; :history:
;     06-Oct-2013 - Marek Steslicki (Wro), initial release
;
;-

function stx_sim_egse_number2bitarray, number, number_of_bits=number_of_bits, reverse=reverse

      if not keyword_set(number_of_bits) then number_of_bits=long(alog(number)/alog(2))+1
      
      bitarray=bytarr(number_of_bits)

      x=number
      for i=0,number_of_bits-1 do begin
            bitarray[i]=x mod 2
            x-=bitarray[i]
            x/=2
      endfor

      if not keyword_set(reverse) then return,bitarray else return,reverse(bitarray)
end
