;+
; Description :
;   Procedure to plot the signals in the four arms as a function of time.
;
; Category    : analysis
;
; Syntax      : plot4sig, data, [unit, plot_dev, /ylog, yrange, expected, yline, i_range]
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
;   expected  = a structure similar to input data conaining expected (simulated) signals. If given,
;               these are overplotted in red in each panel
;   yline     = if given, a dotted vertical line is overplotted in each panel at this X value
;   i_range   = if given, plot signals only between integration numbers in this range
;   t_range   = if given, plot signals only between this time range (in same unit as 'unit')
;   offsets   = (Nx2 array() if given, also plot X,Y offsets af fn. of time
;   
; History     :
;   2020-05-13, F. Schuller (AIP) : created
;   2020-05-18, FSc (AIP) : added optional keywords yline and expected
;   2020-05-27, FSc (AIP) : added optional keyowrd i_range
;   2020-10-05, FSc (AIP) : added option zoom
;   2020-12-15, FSc (AIP) : added optional keyword gradient
;   
;-
pro plot4sig, data, unit=unit, plot_dev=plot_dev, ylog=ylog, yrange=yrange, expected=expected, $
              yline=yline, i_range=i_range, t_range=t_range, offsets=offsets, zoom=zoom, gradient=gradient
  ; define default values for optional parameters
  if not is_struct(data) then begin
    print,"ERROR: input variable is not a structure."
    return
  endif

  default, unit, 'h'
  default, plot_dev, 'X'
  default, ylog, 0
  if keyword_set(yrange) then fixed_Y = 1 else begin
    fixed_Y = 0
    yrange = []
  endelse
  nb_i = n_elements(data.times)
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
  dt = (data.times - data.times[i_min]) * divid
  
  if keyword_set(t_range) then begin
    tmp1 = where(dt ge t_range[0],found)
    if found gt 0 then i_min = tmp1[0] else i_min = 0
    tmp2 = where(dt le t_range[1],found)
    if found gt 0 then i_max = tmp2[-1] else i_max = nb_i-1
    ; update dt with new starting time
    dt = (data.times - data.times[i_min]) * divid
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
  
  if keyword_set(offsets) then begin
    !p.multi = [0,2,3]
    ytext = [0.96,0.60]
    chs1 *= 2.
  endif else !p.multi = [0,2,2]
  
  if keyword_set(expected) then dt_exp = (expected.times - data.times[i_min])*divid
  set_line_color

  ; Print start and end UTC time
  print,"UTC time from ",data.UTC[i_min]," to ",data.UTC[i_max]

  ; if asked to plot gradients, store them in local data variable
  if keyword_set(gradient) then begin
    d_sig =  data.signal[*,1:-1] - data.signal[*,0:-2]
    local_data = {times:data.times[1:-1], UTC:data.utc[1:-1], signal:d_sig}
    if keyword_set(expected) then begin
      d_exp_data = expected.signal[*,1:-1] - expected.signal[*,0:-2]
      local_exp_data = {times:expected.times[1:-1], UTC:expected.utc[1:-1], signal:d_exp_data}
    endif
    i_max -= 1
  endif else begin
    local_data = data
    if keyword_set(expected) then local_exp_data = expected
  endelse

  ;;;;;
  ; here starts the plotting
  if keyword_set(expected) and not fixed_Y then begin
    mm = minmax([local_data.signal[2,i_min:i_max]*1.e9,local_exp_data.signal[2,i_min:i_max]*1.e9])
    m0 = mm[0] - 0.1*(mm[1]-mm[0])  &  m1 = mm[1] + 0.1*(mm[1]-mm[0])
    yrange = [m0,m1]
  endif
  plot,dt[i_min:i_max],local_data.signal[2,i_min:i_max]*1.e9,/ynoz,chars=chs1,ytit='!6current [nA]',$
       ymar=[2,1],xmar=xmar,ylog=ylog,yr=yrange,/ys,/xs
  xyouts,xtext,ytext[0],'!6C',chars=chs2,/norm
  if keyword_set(yline) then oplot,[yline,yline],!y.crange,li=1
  if keyword_set(expected) then oplot,dt_exp,local_exp_data.signal[2,*]*1.e9,li=2,col=3
  
  if keyword_set(expected) and not fixed_Y then begin
    mm = minmax([local_data.signal[0,i_min:i_max]*1.e9,local_exp_data.signal[0,i_min:i_max]*1.e9])
    m0 = mm[0] - 0.1*(mm[1]-mm[0])  &  m1 = mm[1] + 0.1*(mm[1]-mm[0])
    yrange = [m0,m1]
  endif
  plot,dt[i_min:i_max],local_data.signal[0,i_min:i_max]*1.e9,/ynoz,chars=chs1,ytit='!6current [nA]',$
       ymar=[2,1],xmar=xmar,ylog=ylog,yr=yrange,/ys,/xs
  xyouts,xtext+0.5,ytext[0],'!6A',chars=chs2,/norm
  if keyword_set(yline) then oplot,[yline,yline],!y.crange,li=1
  if keyword_set(expected) then oplot,dt_exp,local_exp_data.signal[0,*]*1.e9,li=2,col=3
  
  if keyword_set(expected) and not fixed_Y then begin
    mm = minmax([local_data.signal[1,i_min:i_max]*1.e9,local_exp_data.signal[1,i_min:i_max]*1.e9])
    m0 = mm[0] - 0.1*(mm[1]-mm[0])  &  m1 = mm[1] + 0.1*(mm[1]-mm[0])
    yrange = [m0,m1]
  endif
  plot,dt[i_min:i_max],local_data.signal[1,i_min:i_max]*1.e9,/ynoz,chars=chs1,ytit='!6current [nA]',$
       xtit=xtit,ymar=[3,0],xmar=xmar,ylog=ylog,yr=yrange,/ys,/xs
  xyouts,xtext,ytext[1],'!6B',chars=chs2,/norm
  if keyword_set(yline) then oplot,[yline,yline],!y.crange,li=1
  if keyword_set(expected) then oplot,dt_exp,local_exp_data.signal[1,*]*1.e9,li=2,col=3
  
  if keyword_set(expected) and not fixed_Y then begin
    mm = minmax([local_data.signal[3,i_min:i_max]*1.e9,local_exp_data.signal[3,i_min:i_max]*1.e9])
    m0 = mm[0] - 0.1*(mm[1]-mm[0])  &  m1 = mm[1] + 0.1*(mm[1]-mm[0])
    yrange = [m0,m1]
  endif
  plot,dt[i_min:i_max],local_data.signal[3,i_min:i_max]*1.e9,/ynoz,chars=chs1,ytit='!6current [nA]',$
       xtit=xtit,ymar=[3,0],xmar=xmar,ylog=ylog,yr=yrange,/ys,/xs
  xyouts,xtext+0.5,ytext[1],'!6D',chars=chs2,/norm
  if keyword_set(yline) then oplot,[yline,yline],!y.crange,li=1
  if keyword_set(expected) then oplot,dt_exp,local_exp_data.signal[3,*]*1.e9,li=2,col=3

  if keyword_set(offsets) then begin
    plot,dt[i_min:i_max],offsets[i_min:i_max,0]*1.e6,ytit='!6X!dSAS!n [!4l!6m]',/ynoz,chars=chs1,/xs
    plot,dt[i_min:i_max],offsets[i_min:i_max,1]*1.e6,ytit='!6Y!dSAS!n [!4l!6m]',/ynoz,chars=chs1,/xs
  endif
  
  ; Optionally define a range to zoom in
  if keyword_set(zoom) then begin
    print,"Select time range to zoom in..."
    xycursor,x1,y1,BUTTON=button1
    if button1 eq 1 then begin
      xycursor,x2,y2,BUTTON=button2
      if button2 eq 1 then begin
        if x1 gt x2 then begin
          x3 = x2
          x2 = x1
          x1 = x3
        endif

        if keyword_set(t_range) then begin
          x1 += t_range[0]
          x2 += t_range[0]
        endif
        print,"INFO: plotting signal in time range ",x1," to ",x2
        plot4sig,data, unit=unit, plot_dev=plot_dev, ylog=ylog, expected=expected, t_range=[x1,x2], /zoom, gradient=gradient 
      endif
    endif
  endif
end
