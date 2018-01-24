; 27-May-2015, Laszlo I. Etesi (FHNW), check to see if we are not loosing too much precision
function stx_time2scet, time
  ppl_require, in=time, type='stx_time'
  return, ulong(stx_time2any(time))
end