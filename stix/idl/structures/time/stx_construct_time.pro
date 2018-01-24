function stx_construct_time, time=time
  default, time, 0
  ;if n_elements(time) eq 0 then message, 'Please set time keyword', /block
  
  if ppl_typeof(time, compareto="stx_time", /raw) then begin
    copy_time = time
    return, copy_time
  end
  temp = anytim(time,/mjd) 
  ;time_str = replicate(stx_time(), n_elements(time))
  time_str = replicate(stx_time(), size(/dimension, temp) )
  time_str.value = temp 
  return, time_str
end