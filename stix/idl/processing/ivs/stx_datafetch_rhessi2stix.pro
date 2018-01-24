;---------------------------------------------------------------------------
; Document name: stx_datafetch_rhessi2stix.pro
; Created by:    Nicky Hochmuth, 2012/02/10
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       rhessi2stix
;
; PURPOSE:
;       Rhessi to Stix data format converter
;
; CATEGORY:
;       STIX TESTING
;
; CALLING SEQUENCE:
;       hsp_spectrogram = stx_datafetch_rhessi2stix(obs_time, max_count, min_max_t, histerese=0.8)
;
; HISTORY:
;       2012/02/10, nicky.hochmuth@fhnw.ch, initial release
;       2012/02/20, marina.battaglia@fhnw.ch, changed plot
;       routines. Added obj keyword
;
;-

;+
; :description:
;   Rhessi to Stix data format converter
; :kewords:
;    histerese: threshold for switching off a shutter or pixelstate
;    plotting: create some charts
;    obj: if set, returns a ssw spectrogram object (use obj->plotman) for plotting
; :params:
;    obs_time: the time interval '2002/02/20 ' + ['11:02:00', '11:12:00']
;    RCR_max_count: the maximum number of counts per second (over all energies over all detectors) for switching the RCR-Mode
;	 max_count: the maximum number of counts (over all energies over all detectors) for a good time_bin_duration
;    min_max_t: the minimum and maximum time bin size [0.1,4] in seconds
;
;
; :returns:
;    a hsp_spectrogram structure with total counts per time per energy
;-
function stx_datafetch_rhessi2stix, obs_time, RCR_max_count, max_count, min_max_t, histerese=histerese, plotting=plotting,obj=obj, local_path=local_path, file_name=file_name, rate_control_state=rate_control_state

  default, obj, 1
  default, histerese, 0.8

  ;get a stix energy axis
  e_axis = stx_construct_energy_axis()
  n_e = n_elements(e_axis.mean)

  ;set of different configurations
  n_c = 8

  ;get time structures from the input
  startdate = anytim(obs_time[0],/utc_ext)
  times = anytim(obs_time,/second)
  
  if ~keyword_set(file_name) then begin
    ;create the path to the data file
    file_name =  "stx_rhessi_model_crate_" + string(FORMAT='(I04)',startdate.YEAR)+string(FORMAT='(I02)',startdate.MONTH)+'01.sav'
    local_path = exist(local_path) && dir_exist(local_path) ? local_path : concat_dir(get_environ('SSWDB'),"rhessi2stix")
  end

  ;old
  net_path = "http://soleil.i4ds.ch/stix/rhessi2stix/"

  ;temp
  ;net_path = "http://soleil-int.cs.technik.fhnw.ch/stix/rhessi2stix/"

  
  file = concat_dir(local_path,file_name)

  ;copy the file from the server if not allready exist local
  if ~FILE_TEST(file) THEN BEGIN
   file_mkdir, local_path
   sock_copy,net_path+file_name,file_name,out_dir=local_path,/verbose
  endif

  ;read the data file
  restore,file,/verb
  
  ;crate*=100
  
  ;todo handle events over two month

  ;find the event in the month data file
  event = where((UT ge times[0]) AND (UT le times[1]),count)

  if count le 0 then message, "Could not find data for the specified time!", /block

  event_min_max = minmax(event)
  event_min_max[1]++

  if (event_min_max[0] lt 0) || (event_min_max[1] ge n_elements(UT)-1) then message, "Event may lay on data file borders", /block

  event = [event,event_min_max[1]+1]

  ;read the event from the month data file
  data_read = crate[*,*,event]
  time_read = UT[event]

  ;free the data file data
  UT=0
  crate =0

  chunkSize = 100000
  event_time_pos = 0L

  event_time = make_array(chunkSize,/double)
  event_data = make_array(n_e,n_c,chunkSize,/float)
  
  new_column_idx = 0l
  
  
  n_t=0l
  ;interpolate the read data
  for t=0l, count-1 do begin
    
    if ((t*1000) mod count) eq 0 then print, t, count, t/double(count)
     
    ;get the time column
    column = double(data_read[*,*,t:t+1])

    ;calculate the numbers of time bin needed with the new duration of min_max_t[0]
    timescale = round((time_read[t+1]-time_read[t])/min_max_t[0])

    ;do the interpolation
    new_column = rebin(column,n_e,n_c,2*timescale)
    new_column = new_column[*,*,0:timescale-1]

    ;convert counts/s in total count
    ;new_column = new_column * min_max_t[0]

    if n_elements(event_data[0,0,*]) lt (new_column_idx+timescale) then event_data = [[[event_data]],[[make_array(n_e,n_c,chunkSize,/float)]]]
    
    ;append the new columns to the interpolatet event_data
    event_data[*,*,new_column_idx:new_column_idx+timescale-1] = new_column  
    
    new_column_idx += timescale
    
    ;append the new time columns to the interpolatet event_time

    add_event_time = (rebin(time_read[t:t+1],2*timescale))[0:timescale-1]
    add_event_time_length = n_elements(add_event_time)

    if add_event_time_length gt (n_elements(event_time)-event_time_pos) then begin
      event_time = [event_time, make_array(chunkSize,/double)]
    end

    event_time[event_time_pos:event_time_pos+add_event_time_length-1] = add_event_time
    event_time_pos += add_event_time_length
    n_t+=timescale

  end

  event_time = event_time[0:event_time_pos-1]

  event_data = event_data[*,*,0:n_t-1]


  stix_data = make_array(n_e,n_t,/float)
  data_c = make_array(n_t,/byte)
  time_axis = make_array(n_t,/double)

  ;the write pointer for the stix event
  appandPointer = 0L

  ;the current time
  t=long(0)

  ;the current shutter/pixel state
  laststate = 0

  while t lt  n_t do begin
      ;reduce the count by shutter and pixels
      if total(event_data[*,laststate,t]) gt RCR_max_count then laststate = min([laststate+1,7]) $
      else if laststate ge 1 && total(event_data[*,laststate-1,t]) lt RCR_max_count*histerese then laststate--

      ;merge time_bins in the current shutter/pixel state until max_count
      t_end = t+1
      while (t_end lt n_t) && ((total(event_data[*,laststate,t:t_end])*min_max_t[0]) lt max_count) && ((event_time[t_end]-event_time[t]) lt min_max_t[1]) do t_end ++
      t_end--
	  ;* min_max_t[0]: change the counts/s to total count per bin
      new_c = t lt t_end ? total(reform(event_data[*,laststate,t:t_end]),2) * min_max_t[0] : reform(event_data[*,laststate,t:t_end]) * min_max_t[0]

      stix_data[*,appandPointer] = new_c
      data_c[appandPointer] = laststate
      time_axis[appandPointer] = event_time[t_end]

      appandPointer++

      t=t_end+1

  end

  appandPointer-=2

  ;crop the stax_data
  stix_data = stix_data[*,0:appandpointer]
  data_c = data_c[0:appandPointer]
  time_axis = time_axis[0:appandPointer+1]

  ;do some plotting
  if keyword_set(plotting) then begin
    !p.charsize=2.3
     !P.Multi=[0,1,3]
     !P.position = 0
     !X.MARGIN=[10,10]
    linecolors
    window, XSIZE=1200, YSize=800, /free, title="RHESSI 2 STIX: RATE CONTROL REGIME"
    
    duration = time_axis-shift(time_axis,1)
    duration[0]=duration[1]
    
    ;readdata
    yrange=[(total(data_read[*,0,*],1))[min(where(total(data_read[*,0,*],1) gt 0))],max(total(data_read[*,0,*],1)*1.2)]

    utplot,time_read-time_read[0],total(data_read[*,0,*],1),time_read[0],ytitle='Original data [counts/s]',/ylog,ystyle=9,yrange=yrange,xstyle=1
    ;axis,yaxis=1,/ylog,yrange=yrange,/save,color=2,ytitle='Interpolated data [counts]'
    
    outplot,event_time-event_time[0],total(event_data[*,0,*],1),time_read[0], color=2
	
    xyouts,!x.crange[0]+10d,yrange[1]*0.7,'Interpolated data 0.1s [counts/s]',color=2,charsize=1.2

    ;rebin data
    utplot,time_axis-time_axis[0],total(stix_data[*,*],2),time_read[0], color=2, psym=10 $
    ,ytitle='instrument counts / time bin', ystyle=9,xstyle=1
    yrangecd = minmax(total(stix_data[*,*],2)/duration)
    axis,yaxis=1,/save,yrange=yrangecd,/ystyle,color=9,ytitle='Counts/Duration',/ylog
    ;rebin data / duration 
    outplot,time_axis-time_axis[0],total(stix_data[*,*],2)/duration,time_read[0], color=9, psym=10
    xyouts,!x.crange[0]+10d,yrangecd[1],'instrument counts / time bin duration [counts/s]',charsize=1.2,color=9

    ;chanell
    utplot,time_axis-time_axis[0],data_c,time_read[0], yrange=[0,7] $
           ,ytitle='STIX attenuation state',ystyle=9,thick=3,xstyle=1
    xyouts,!x.crange[0]+10d,6.5,'Time bin size [s]',charsize=1.2,color=7

    ;interpoldata to 0.1
    axis,yaxis=1,/save,yrange=[0,max(duration)*1.2],/ystyle,color=7,ytitle='Duration'

    ;duration
    outplot,time_axis-time_axis[0],duration,time_read[0], color=7, psym=10
    

    

    !P.Multi=0

  endif ;Plot

  ;create a lifetime dummy array
  ltime = stix_data
  ltime[*]=1

rate_control_state = data_c


if keyword_set(obj) then $
  out=make_spectrogram(stix_data,time_axis=time_axis,spectrum_axis=e_axis.mean) $
else $
  out = stx_spectrogram(stix_data,stx_construct_time_axis(time_axis), e_axis,ltime,attenuator_state=data_c)

return, out


end



;while t lt  n_t do begin
;    ;enlarge the time
;    ;print, t, total(event_data[*,0,t])
;    if total(event_data[*,0,t]) lt max_count then begin
;      laststate=0
;      t_end = t+1
;      while (t_end lt n_t) && (total(event_data[*,0,t:t_end]) lt max_count) && ((event_time[t_end]-event_time[t]) lt min_max_t[1]) do t_end ++
;      t_end--
;      new_c = t lt t_end ? total(reform(event_data[*,0,t:t_end]),2) :reform(event_data[*,0,t:t_end])
;
;      data[*,appandPointer] = new_c
;      data_c[appandPointer] = laststate
;      time_axis[appandPointer] = event_time[t_end]
;
;      t=t_end+1
;    end else begin
;      laststate=max([1,laststate])
;      ;reduce the count by shutter and pixels
;      if total(event_data[*,laststate,t]) gt max_count then laststate = min([laststate+1,7]) $
;      else if laststate gt 1 && total(event_data[*,laststate-1,t]) lt max_count*histerese then laststate--
;
;      new_c = reform(event_data[*,laststate,t])
;      data[*,appandPointer] = new_c
;      data_c[appandPointer] = laststate
;      time_axis[appandPointer] = event_time[t]
;      t++
;    end
;    appandPointer++
;
;  end
