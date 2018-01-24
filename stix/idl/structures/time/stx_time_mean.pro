function stx_time_mean, left, right
  return, stx_construct_time(time=mean([[stx_time2any(left)],[stx_time2any(right)]]))
end
