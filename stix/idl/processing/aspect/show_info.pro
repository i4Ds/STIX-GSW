pro show_info, data
  if not is_struct(data) then begin
    print,"ERROR: input variable is not a structure."
    return
  endif

  dt = data.times[1:-1] - data.times[0:-2]
  resol = median(dt)
  neg = where(dt lt 0,count)
  if count gt 0 then print,count,format='("WARNING - data contains ",I2," jump(s) back in time")'
  gaps = where(dt gt 1.5*resol, count)
  if count gt 0 then begin
    print,count,format='("WARNING - data contains ",I3," gaps:")'
    if count le 10 then for i=0,count-1 do $
      print,data.UTC[gaps[i]],data.UTC[gaps[i]+1],format='(" ... between ",A23," and ",A23)' else begin
      for i=0,9 do print,data.UTC[gaps[i]],data.UTC[gaps[i]+1],format='(" ... between ",A23," and ",A23)'
      print,count-10,format='(".... and ",I3," more.")'
    endelse 
  endif
  if resol lt 1. then print,resol*1000,format='("Data at resolution: ",F5.1," ms")' $
                 else print,resol,format='("Data at resolution: ",F6.1," s")'
  if tag_exist(data,'_calibrated') then begin
    if data._calibrated then print,"Data has been calibrated." $
                        else print,"Data NOT calibrated yet."
  endif
  print,n_elements(data.times),data.UTC[0],data.UTC[-1],format='(I," data points, from ",A23," to ",A23)'
end
