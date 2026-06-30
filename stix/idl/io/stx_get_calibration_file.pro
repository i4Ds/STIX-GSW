;+
;
; name:
;       stx_get_calibration_file
;
; :description:
;    This procedure checks the STIX data archive within a time window around a given observation and downloads the calibration file closest to the input time. 
;    Files with a livetime below a specific threshold are excluded.
;
; :params:
;    start_time : in, required, type="string"
;                the start time of the observation
;    end_time : in, required, type="string"
;                the end time of the observation
;
; :keywords
;   out_dir: path of the folder where the STIX calibration FITS files are saved. Default is the current directory
;   
;   live_time_thresh: in, type="float"
;                     Files with livetime lower than 'live_time_thresh' are discarded
;                     
;   window_days: in, type="integer"
;                This routine searches for calibration files within a time window of ± window_days around the input flare time
;
; :returns:
;   Path of the downloaded STIX calibration FITS file
;
; :examples:
;    out_file = stx_get_calibration_file('09-May-23 06:14:37.094', '09-May-23 06:36:12.194')
;
; :history:
;    24-Mar-2026 - Massa P. (FHNW), first release
;    13-Apr-2026 - Massa P. (FHNW), updated to search for calibration files the day before or after the input date (in case there are no files for the input date)
;    22-Jun-2026 - Massa P. (FHNW), download files within ± window_days, read livetime, and dicard files with livetime less than 30K s
;-
function stx_get_calibration_file, start_time, end_time, out_dir=out_dir, live_time_thresh=live_time_thresh, window_days = window_days

  cd, current=current

  default, out_dir, current
  default, clobber, 0
  default, live_time_thresh, 3e4
  default, window_days, 10
  
  if window_days le 0. then message, "The number of days around the flare time used to download calibration files must be positive"
  window_days = round(window_days)

  day_in_s = 86400.d ;; Number of seconds in a day. To be used later to identify the most appropriate calibration file

  site = 'http://dataarchive.stix.i4ds.net'
  date_path = get_fid(start_time,end_time,/full,delim='/')

  ;; Concatenate files from the input date and from the day before/after
  type_path = '/fits/CAL/'
  filter = '*stix-cal-energy*.fits'

  ;; Load the ELUT file for the iput time (it is used later for checks)
  elut_input_time = stx_date2elut_file(start_time)
  
  ;; Search for files in the time range ± window_days around the observation time
  found_files_array=[]
  for i=-window_days,window_days do begin
    
    this_start_time = anytim(anytim(start_time) + i * day_in_s, /vms)
    this_end_time   = anytim(anytim(end_time) + i * day_in_s, /vms)

    this_path = get_fid(this_start_time,this_end_time,/full,delim='/')

    path = type_path + this_path[0] +'/CAL'
    found_files=sock_find(site,filter,path=path,count=count)
    
    if count gt 0 then found_files_array = [found_files_array, found_files]
    
  endfor
  
  ;;***********************************************************************

  len_path = STRLEN(site+path)

  if n_elements(found_files_array) eq 0 then begin

    message, "No STIX calibration file was found within "+num2str(window_days)+" days before or after "+$
       date_path[0]+". Please, download an appropriate calibration file manually."

  endif else begin

    start_time_file = []
    end_time_file = []
    elut_check = []

    ;; Extract file names
    for i = 0,n_elements(found_files_array)-1 do begin

      len_full_path = STRLEN(found_files_array[i])
      filename = STRMID(found_files_array[i], len_path+1, len_full_path)

      string_dates = STRMID(filename, STRLEN('solo_CAL_stix-cal-energy_'), STRLEN(filename)-STRLEN('solo_CAL_stix-cal-energy_')-9) ;; 9 is the number of characters in the string '_V02.fits'

      mid_part = STRPOS(string_dates, '-')

      this_start_time_file = STRMID(string_dates, 0, mid_part)
      year  = STRMID(this_start_time_file, 0, 4)
      month = STRMID(this_start_time_file, 4, 2)
      day   = STRMID(this_start_time_file, 6, 2)
      hour  = STRMID(this_start_time_file, 9, 2)
      min   = STRMID(this_start_time_file, 11, 2)
      sec   = STRMID(this_start_time_file, 13, 2)

      this_start_time = anytim(year + '-' + month + '-' + day + 'T' + hour + ':' + min + ':' + sec)
      start_time_file = [start_time_file, this_start_time]

      this_end_time_file = STRMID(string_dates, mid_part+1, STRLEN(string_dates))
      year  = STRMID(this_end_time_file, 0, 4)
      month = STRMID(this_end_time_file, 4, 2)
      day   = STRMID(this_end_time_file, 6, 2)
      hour  = STRMID(this_end_time_file, 9, 2)
      min   = STRMID(this_end_time_file, 11, 2)
      sec   = STRMID(this_end_time_file, 13, 2)
      end_time_file = [end_time_file, anytim(year + '-' + month + '-' + day + 'T' + hour + ':' + min + ':' + sec)]

      elut_check = [elut_check, (elut_input_time eq stx_date2elut_file(this_start_time))]

    endfor

    ;; Compute mid point of the time interval of the calibration file
    mid_time_file = (start_time_file + end_time_file) / 2.

    ;; Compute duration file
    duration = end_time_file - start_time_file

    ;; ELUT check
    idx_elut = where(elut_check, n_elut_check)

    if n_elut_check eq 0 then begin

      message, "Available STIX calibration files within "+num2str(window_days)+" before or after "+$
                date_path[0]+" have been registered with an onboard ELUT different from that used during the input time range. Please, download an appropriate calibration file manually."

    endif else begin

      ;; Select calibration files recorded with the same ELUT as the one that was onboard during the input time range
      found_files = found_files_array[idx_elut]
      duration = duration[idx_elut]
      start_time_file = start_time_file[idx_elut]
      end_time_file = end_time_file[idx_elut]
      mid_time_file = mid_time_file[idx_elut]

      ;; Select calibration file with duration larger than a predefined threshold
      idx_duration = where(duration ge live_time_thresh, n_duration)

      if n_duration eq 0 then begin

        message, "Available STIX calibration files within "+num2str(window_days)+" days before or after "+$
                  date_path[0]+" have a duration shorter than 30K sec and should not be used. Please, download an appropriate calibration file manually."

      endif else begin

        found_files = found_files[idx_duration]
        duration = duration[idx_duration]
        start_time_file = start_time_file[idx_duration]
        end_time_file = end_time_file[idx_duration]
        mid_time_file = mid_time_file[idx_duration]
        
      endelse
    
    endelse    
  
  endelse
      
  ;; Download calibration files to read live time
  
  out_name = []
  livetime = []
  file_exist_check = []
  for i=0,n_elements(found_files)-1 do begin
    
    ;; Extract file name
    string_parts = STRSPLIT(found_files[i], '/', /EXTRACT)
    filename = concat_dir(out_dir,string_parts[-1])
    
    out_name = [out_name, filename]

    if file_exist(filename) then begin
      
      file_exist_check = [file_exist_check, 1]
      
    endif else begin
      
      sock_copy, found_files[i], this_out_name, out_dir = out_dir
      file_exist_check = [file_exist_check, 0]
      
    endelse
        
    !null = stx_read_fits(filename, 0, primary_header,  mversion_full = mversion_full, /silent)
    
    this_livetime = sxpar(primary_header,'LIVETIME', count = count) 
    livetime = [livetime, this_livetime]
    
  endfor
  
  

  idx_livetime = where(livetime ge live_time_thresh, n_livetime)  
  
  if n_livetime eq 0 then begin
    
    for i=0,n_elements(out_name)-1 do begin

      if not file_exist_check[i] then  file_delete, out_name[i]

    endfor
    
    message, "Available STIX calibration files within "+num2str(window_days)+" days before or after "+$
              date_path[0]+" have a livetime shorter than 30K sec and should not be used. Please, download an appropriate calibration file manually."
  
  endif


  ;; Remove files with low livetime
  idx_low_livetime = where(livetime lt live_time_thresh, n_low_livetime)

  if n_low_livetime gt 0 then begin

    for i=0,n_low_livetime-1 do file_delete, out_name[idx_low_livetime[i]]

  endif

    
  out_name = out_name[idx_livetime]
  livetime = livetime[idx_livetime]
  
  file_exist_check = file_exist_check[idx_livetime]
  
  start_time_file = start_time_file[idx_livetime]
  end_time_file = end_time_file[idx_livetime]
  mid_time_file = mid_time_file[idx_livetime]

  ;; If multiple files have livetime larger than the threshold, select the closest one to the input time range
  if n_livetime gt 1 then begin

    ;; Select the file closest in time to input time range
    mid_time_input = (anytim(start_time) + anytim(end_time)) / 2.
    time_diff = abs(mid_time_file - mid_time_input)

    idx_time_diff = sort(time_diff)

    idx_file = idx_time_diff[0]

    selected_file = out_name[idx_file]
    selected_file_time_start = start_time_file[idx_file]
    selected_file_time_end = end_time_file[idx_file]
    
    idx_rm_file = idx_time_diff[1:*]
    
    for i=0,n_elements(idx_rm_file)-1 do begin
      
      if not file_exist_check[idx_rm_file[i]] then  file_delete, out_name[idx_rm_file[i]]
    
    endfor

  endif else begin

    selected_file = out_name
    selected_file_time_start = start_time_file
    selected_file_time_end = end_time_file

  endelse

  ;; Download file
  print
  print
  print, "Downloaded STIX calibration file recorded between " +anytim(selected_file_time_start, /vms)+$
    " and "+anytim(selected_file_time_end, /vms)
  print
  print

  return, selected_file

end
