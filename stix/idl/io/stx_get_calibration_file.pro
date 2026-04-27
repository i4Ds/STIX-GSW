;+
;
; name:
;       stx_get_calibration_file
;
; :description:
;    This procedure checks the STIX data archive for a given observation time and finds any
;    STIX CAL calibration file. If no file is present for the input date, the procedure searches for
;    the calibration file which is closest in time. If multiple files are present for that date,
;    this procedure downloads the one with largest duration.
;
; :categories:
;    template, example
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
;   clobber: 0 or 1. If set to 0, the code does not download the file again if it is already present in 'out_dir'.
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
;-
function stx_get_calibration_file, start_time, end_time, out_dir=out_dir, clobber=clobber

  cd, current=current

  default, out_dir, current
  default, clobber, 0

  day_in_s = 86400.d ;; Number of seconds in a day. To be used later to identify the most appropriate calibration file

  site = 'http://dataarchive.stix.i4ds.net'
  date_path = get_fid(start_time,end_time,/full,delim='/')

  ;; Concatenate files from the input date and from the day before/after
  type_path = '/fits/CAL/'
  filter = '*stix-cal-energy*.fits'
  
  ;; Load the ELUT file for the iput time (it is used later for checks)
  elut_input_time = stx_date2elut_file(start_time)
  
  
  found_files_array=[]
  
  ;; Input day
  path = type_path + date_path[0] +'/CAL'
  found_files=sock_find(site,filter,path=path,count=count)
  
  if count gt 0 then found_files_array=[found_files_array, found_files]
  
  ;; Day before
  this_start_time_before = anytim(anytim(start_time) - day_in_s, /vms)
  this_end_time_before   = anytim(anytim(end_time) - day_in_s, /vms)

  path_before = get_fid(this_start_time_before,this_end_time_before,/full,delim='/')
  
  path = type_path + path_before[0] +'/CAL'
  found_files=sock_find(site,filter,path=path,count=count)

  if count gt 0 then found_files_array=[found_files_array, found_files]
  
  ;; Day after
  this_start_time_after = anytim(anytim(start_time) + day_in_s, /vms)
  this_end_time_after   = anytim(anytim(end_time) + day_in_s, /vms)

  path_after = get_fid(this_start_time_after,this_end_time_after,/full,delim='/')

  path = type_path + path_after[0] +'/CAL'
  found_files=sock_find(site,filter,path=path,count=count)

  if count gt 0 then found_files_array=[found_files_array, found_files]
  
  
  ;;*********
  
  len_path = STRLEN(site+path)
  
  if n_elements(found_files_array) eq 0 then begin
    
    message, $
      [" ", " ", "No STIX calibration file was found within 1 day before or after " +date_path[0]+". Please, download an appropriate calibration file manually.", " ", " "]
    
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
      
      message, [" ", " ", "Available STIX calibration files within 1 day before or after " +date_path[0]+" have been registered with an onboard ELUT different from that used during the selected time range and cannot be used. Please, download an appropriate calibration file manually.", " ", " "]
    
    endif else begin
      
      ;; Select calibration files recorded with the same ELUT as the one that was onboard during the input time range 
      found_files = found_files_array[idx_elut]
      duration = duration[idx_elut]
      start_time_file = start_time_file[idx_elut]
      mid_time_file = mid_time_file[idx_elut]
      
      ;; Select calibration file with largest duration
      idx_duration = where(duration ge day_in_s / 2., n_duration)
      
      if n_duration eq 0 then begin
        
        message, [" ", " ", "Available STIX calibration files within 1 day before or after " +date_path[0]+" have a duration shorter than half a day and should not be used. Please, download an appropriate calibration file manually.", " ", " "]
        
      endif else begin
        
        found_files = found_files[idx_duration]
        duration = duration[idx_duration]
        start_time_file = start_time_file[idx_duration]
        mid_time_file = mid_time_file[idx_duration]
        
        ;; If multiple files have the largest duration, select the closest one to the input time range
        if n_duration gt 1 then begin

          ;; Select the file closest in time to input time range
          mid_time_input = (anytim(start_time) + anytim(end_time)) / 2.
          time_diff = abs(mid_time_file - mid_time_input)

          idx_time_diff = sort(time_diff)

          idx_file = idx_time_diff[0]

          selected_file = found_files[idx_file]
          selected_file_time = start_time_file[idx_file]
        
        endif else begin
          
          selected_file = found_files
          selected_file_time = start_time_file
          
        endelse
        
      endelse
         
    endelse
    
  endelse

  ;; Download file
  message, [" ", " ", "Download STIX calibration file recorded at " +anytim(selected_file_time, /vms), " ", " "], /continue
  sock_copy, selected_file, out_name, local_file=out_file, out_dir = out_dir, clobber=clobber

  return, out_file



end
