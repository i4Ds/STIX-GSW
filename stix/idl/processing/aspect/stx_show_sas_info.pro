;+
; Description :
;   Procedure to display basic info about an SAS data structure.
;
; Syntax      : stx_show_sas_info, data
;
; Inputs      :
;     data    = an array of STX_ASPECT_DTO structures
;
; Output      : None.
;
; History   :
;   2020 - F. Schuller (AIP), initial version
;   2022-01-28 - FSc (AIP): adapted to STX_ASPECT_DTO structure
;   2023-10-27, FSc (AIP): changed name from show_info to stx_show_sas_info
;
;-

pro stx_show_sas_info, data
  if not is_struct(data) then begin
    print,"ERROR: input variable is not a structure."
    return
  endif

  dt = data.duration
  resol = median(dt)
  neg = where(dt lt 0,count)
  if count gt 0 then print,count,format='("WARNING - data contains ",I2," jump(s) back in time")'
  gaps = where(dt gt 1.5*resol, count)
  if count gt 0 then begin
    print,count,format='("WARNING - data contains ",I4," gaps:")'
    if count le 10 then for i=0,count-1 do $
      print,data[gaps[i]].time,data[gaps[i]+1].time,format='(" ... between ",A," and ",A)' else begin
      for i=0,9 do print,data[gaps[i]].time,data[gaps[i]+1].time,format='(" ... between ",A," and ",A)'
      print,count-10,format='(".... and ",I3," more.")'
    endelse 
  endif
  if resol lt 1. then print,resol*1000,format='("Data at resolution: ",F5.1," ms")' $
                 else print,resol,format='("Data at resolution: ",F6.1," s")'
  _calibrated = data[0].calib
  if _calibrated then print,"Data has been calibrated." $
                 else print,"Data NOT calibrated yet."
  print,n_elements(data),data[0].time,data[-1].time,format='(I," data points, from ",A," to ",A)'
end
