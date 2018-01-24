function _str2hex, x
  x = strlowcase(x)

  if(is_number(x)) then return, fix(x) $
  else return, byte(x) - byte('a') + 10
end

pro stx_convert_ascii_tmtc_payload2byte_stream_file, file_ascii_in=file_ascii_in, file_byte_out=file_byte_out
  openu, lun_read, file_ascii_in, /get_lun
  
  x1 = 0b
  x2 = 0b
  
  i = 0
  
  
  openw, lun_write, file_byte_out, /get_lun

  while ~ eof(lun_read) do begin
    readu, lun_read, x1
    readu, lun_read, x2
    ;x1 = strmid(char, i, 1)
    ;x2 = strmid(char, i+1, 1)
    hex = byte(_str2hex(x1) * 16L^1 + _str2hex(x2) * 16L^0)
    writeu, lun_write, hex

    i++
  endwhile
  
  free_lun, lun_read
  free_lun, lun_write
end