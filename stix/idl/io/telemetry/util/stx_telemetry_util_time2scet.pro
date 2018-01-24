; converts a stx_time() to scet and vice-versa
; ignores the MJD value which comes with stx_construct_time

pro stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, stx_time_obj=stx_time_obj, reverse_step=reverse_step
  
  ; define value of fine_time mask
  fine_bits=(2.0D^((indgen(16)+1)*(-1)))
  
  if KEYWORD_SET(reverse_step) then begin
    ; create a stx_time out of SCET
    stx_time_obj=stx_construct_time()
    
    ; get fine time value
    fine_mask = reverse(stx_mask2bits(fine_time,mask_length=16, /reverse))
    sub_second_value = total(fine_mask*fine_bits)
    
    ; add seconds and subseconds
    stx_time_obj=stx_time_add(stx_time_obj,seconds=coarse_time)
    stx_time_obj=stx_time_add(stx_time_obj,seconds=sub_second_value)
    
  endif else begin
    
    ; create coarse and fine time
    time_in_seconds = stx_time_obj.value.time / 1000.0d 
    coarse_time = ulong(time_in_seconds)
    time_in_sub_second=time_in_seconds-coarse_time
    
    fine_mask=bytarr(16)
    for i=0,15 do begin
      if(time_in_sub_second-fine_bits[i] ge 0.0) then begin
        time_in_sub_second-=fine_bits[i]
        fine_mask[i]=1
      endif
    endfor
    
    fine_time =  stx_mask2bits(reverse(fine_mask),mask_length=16)
    
  endelse
    
  
end
