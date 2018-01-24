; input: a number which could be negative gets converted to a byte()
; if negative the MSB will be 1 so therefore we add 128

function stx_telemetry_util_negative_byte, number, reverse=reverse

  ; convert the pseudo negative byte back to an uint
  if n_elements(reverse) ne 0 then begin
    ret_number = fix(number)
    if ret_number gt 127 then ret_number=(ret_number-128)*(-1)
    return, ret_number
  endif

  ;convert number to byte if negative: remove -1 and add 128.
  if abs(number)gt 127 then message, 'input number is to big to convert to a negative_byte.'
  if number lt 0 then number=(number*(-1))+128
  return, byte(number)

end
