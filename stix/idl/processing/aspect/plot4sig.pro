;+
; Description :
;   Procedure to plot the signals in the four arms as a function of time.
;
; Category    : analysis
;
; Syntax      : plot4sig, data, [unit, plot_dev, /ylog, yrange, yline, i_range]
;
; Inputs      :
;   data      = a structure as returned by read_sas_data
;
; Output      : None.
;
; Keywords    :
;   unit      = if set to 'h' then the X axis in the plots is in hours, otherwise in days
;   plot_dev  = if set to 'X' then the plots are optimised for X-window diplay, otherwise they will
;               look good on a postscipt file
;   ylog      = if non-zero, the Y-axis is plotted in logartithmic scale
;   yrange    = if given, all plots use the same fixed Y-range
;   yline     = if given, a dotted vertical line is overplotted in each panel at this X value
;   i_range   = if given, plot signals only between integration numbers in this range
;   t_range   = if given, plot signals only between this time range (in same unit as 'unit')
;   
; History     :
;   2020-05-13, F. Schuller (AIP) : created
;   2020-05-18, FSc (AIP) : added optional keywords yline and expected
;   2020-05-27, FSc (AIP) : added optional keyowrd i_range
;   2020-10-05, FSc (AIP) : added option zoom
;   2020-12-15, FSc (AIP) : added optional keyword gradient
;   2022-01-28, FSc (AIP) : adapted to STX_ASPECT_DTO structure; removed some options (expected, gradient, zoom, offsets)
;
;-
pro plot4sig, data, unit=unit, plot_dev=plot_dev, ylog=ylog, yrange=yrange, yline=yline, i_range=i_range, t_range=t_range
  if not is_struct(data) then begin
    print,"ERROR: input variable is not a structure."
    return
  endif

  ; define default values for optional parameters
  default, unit, 'h'
  default, plot_dev, 'X'
  default, ylog, 0
  if keyword_set(yrange) then fixed_Y = 1 else begin
    fixed_Y = 0
    yrange = []
  endelse
  nb_i = n_elements(data)
  if not keyword_set(i_range) then i_range = [0,nb_i-1]
  i_min = i_range[0]  &  i_max = min([i_range[1],nb_i-1])
  
  if unit eq 'h' or unit eq 'H' then begin
    divid = 1./3600.
    xtit = '!6Time [hours]'
  endif else if unit eq 'm' or unit eq 'M' then begin
    divid = 1./60.
    xtit = '!6Time [min.]' 
  endif else begin
    divid = 1./3600./24.
    xtit = '!6Time [days]'
  endelse
  
  ; Convert UTC time strings to numerical values
  num_times = anytim(data.time)
  dt = (num_times - num_times[i_min]) * divid
  
  if keyword_set(t_range) then begin
    tmp1 = where(dt ge t_range[0],found)
    if found gt 0 then i_min = tmp1[0] else i_min = 0
    tmp2 = where(dt le t_range[1],found)
    if found gt 0 then i_max = tmp2[-1] else i_max = nb_i-1
    ; update dt with new starting time
    dt = (num_times - num_times[i_min]) * divid
    ; print,i_min,i_max,format='("Info: plotting from #",I5," to #",I5)'
  endif

  if plot_dev eq 'X' or plot_dev eq 'x' then begin
    chs1 = 1.5  &  chs2 = 2.5
    xtext = 0.45
    xmar = [10,3]
  endif else begin
    chs1 = 1.0  &  chs2 = 1.5
    xtext = 0.44
    xmar = [8,2]
  endelse
  ytext = [0.94,0.46]
  
  !p.multi = [0,2,2]
  set_line_color

  ; Print start and end UTC time
  print,"UTC time from ",data[i_min].TIME," to ",data[i_max].TIME

  ; Reform all four signals in a 4xN array
  local_data = transpose([[data.CHA_DIODE0],[data.CHA_DIODE1],[data.CHB_DIODE0],[data.CHB_DIODE1]])

  ;;;;;
  ; here starts the plotting
  plot,dt[i_min:i_max],local_data[2,i_min:i_max]*1.e9,/ynoz,chars=chs1,ytit='!6current [nA]',$
       ymar=[2,1],xmar=xmar,ylog=ylog,yr=yrange,/ys,/xs
  xyouts,xtext,ytext[0],'!6C',chars=chs2,/norm
  if keyword_set(yline) then oplot,[yline,yline],!y.crange,li=1
  
  plot,dt[i_min:i_max],local_data[0,i_min:i_max]*1.e9,/ynoz,chars=chs1,ytit='!6current [nA]',$
       ymar=[2,1],xmar=xmar,ylog=ylog,yr=yrange,/ys,/xs
  xyouts,xtext+0.5,ytext[0],'!6A',chars=chs2,/norm
  if keyword_set(yline) then oplot,[yline,yline],!y.crange,li=1
  
  plot,dt[i_min:i_max],local_data[1,i_min:i_max]*1.e9,/ynoz,chars=chs1,ytit='!6current [nA]',$
       xtit=xtit,ymar=[3,0],xmar=xmar,ylog=ylog,yr=yrange,/ys,/xs
  xyouts,xtext,ytext[1],'!6B',chars=chs2,/norm
  if keyword_set(yline) then oplot,[yline,yline],!y.crange,li=1
  
  plot,dt[i_min:i_max],local_data[3,i_min:i_max]*1.e9,/ynoz,chars=chs1,ytit='!6current [nA]',$
       xtit=xtit,ymar=[3,0],xmar=xmar,ylog=ylog,yr=yrange,/ys,/xs
  xyouts,xtext+0.5,ytext[1],'!6D',chars=chs2,/norm
  if keyword_set(yline) then oplot,[yline,yline],!y.crange,li=1

end
