;+
; :description:
;     This procedure reads simulated events for desired time range from fits files.
;
; :keyword:
;     directory : in, required, type='string'
;       fits files folder path
;     t_start : in, required, type='double'
;       start time for desired sequence
;     t_end : in, required, type='double'
;       end time for desired sequence, non-inclusive
;     sort : in, optional, type='byte', default='1b'
;       if set to 1, the detector counts are sorted before returning
;
; :history:
;     23-Aug-2014 - Marek Steslicki, Tomek Mrozek (Wro), initial release
;     01-Sep-2014 - Laszlo I. Etesi (FHNW), - using directory and file name properly
;                                           - fixed bug with internal addressing of bins
;                                           - fixed bug with reading back unsigned integers
;                                           - using structyp with mrdfits to preserve data types
;                                           - using list instead of growing array
;     02-Sep-2014 - Laszlo I. Etesi (FHNW), - bugfixed a problem with the list
;     
;  :todo:
;     02-Sep-2014 - Laszlo I. Etesi (FHNW), - get rid of the list since it is now much slower than the initial array-based
;                                             solution; probably wise to use a growing array that grows chunk-wise (not piece-wise)
;                                           - there probably is a problem reading data back in; in my test some files are empty (and they should not be)
;                                           - added sort keyword
;     04-Sep-2014 - Laszlo I. Etesi (FHNW), - bugfixing
;                                           - speed improvements
;     11-Sep-2014 - Laszlo I. Etesi (FHNW), - changed routine to treat t_end as a non-inclusive boundary
;-

function stx_sim_detector_events_fits_reader, directory=directory, t_start=t_start, t_end=t_end, sort=sort
  default, sort, 1
  default, initial_data_size, 10000000L 
  default, increase_data_size, 5000000L
  
  files = find_file(concat_dir(directory, '*.fits'), count=n)
  
  ; initializing data_all with a big array that is extended later
  ; setting relative_time to -1 to ensure the efficient filtering will work
  tmp_data = {stx_sim_detector_event}
  tmp_data.relative_time = -1
  data_all = replicate(tmp_data, initial_data_size)
  data_all_ptr = 0L
  data_all_size = n_elements(data_all)
  
  for i=0L,n-1 do begin
    header=headfits(files[i],EXTEN=1)
    ;print, "readheader: "+files[i] 
    t0=double(fxpar(header,'TIME0'))
    ;print, "read time0"
    t_bin_nr=0L
    tbin=0
    repeat begin
      tbin_kw='TBIN'+trim(string(t_bin_nr, Format='(i3.3)'))
      tbin=long(fxpar(header,tbin_kw))
      ;print, "read "+tbin_kw
      
      ; tbin eq 0 means that the parameter 'TBINXXX' was not found
      if(tbin eq 0) then continue
      
      if t_bin_nr eq 0 then bins = [tbin] else bins = [bins, tbin]
      t_bin_start=t0 + t_bin_nr*4d
      t_bin_end = t_bin_start+4d
      ; TODO: Check for validity of the next if statement
      if t_bin_start lt t_end and t_bin_end gt t_start then begin
        if t_bin_nr eq 0 then rows = [0,bins[0]] else rows = [bins[t_bin_nr - 1]+1, bins[t_bin_nr]]
        data = mrdfits(files[i], 1, range = rows, structyp='stx_sim_detector_event')
        if(rows[1] le 0) then stop
        print,'rows',rows
        if size(data, /dim) gt 0 then begin
          data.relative_time+=t0
          
          data_elements = n_elements(data)
          
          ; grow if necessary
          if(data_elements + data_all_ptr ge data_all_size) then begin
            
            actual_increase = data_elements gt increase_data_size ? data_elements + increase_data_size : increase_data_size
            
            data_all = [data_all, replicate(tmp_data, actual_increase)]
            data_all_size += actual_increase
          endif
          
          data_all[data_all_ptr] = data
          data_all_ptr += n_elements(data)
        endif
      endif
      
      t_bin_nr++
      
    endrep until tbin eq 0
  endfor

  ; combine time filtering and array compacting 
  data_all_array = data_all[where(data_all.relative_time ge t_start and data_all.relative_time lt t_end)]
    
  if(sort) then return, data_all_array[bsort(data_all_array.relative_time)] $
  else return, data_all_array
end

