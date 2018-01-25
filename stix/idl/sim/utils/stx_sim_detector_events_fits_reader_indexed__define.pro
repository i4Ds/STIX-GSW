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
;       end time for desired sequence
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
;     21-Nov-2014 - Laszlo I. Etesi (FHNW), - bugfixes with indexing, and array growing
;     21-Nov-2014 - Nicky Hochmuth  (FHNW), - add more index values
;     30-Nov-2014 - Laszlo I. Etesi (FHNW), - bugfix: if statement was using size(data, /dim) incorrectly and caused
;                                             the loop to terminate prematurely
;                                           - implemented "real" safe mode with original reader (no caching)
;     01-Dec-2014 - Laszlo I. Etesi (FHNW), - bugfix: problematic use off fxpar (return value zero for exit, but zero may be valid)
;                                           - bugfix: incorrect boundary checks (if-statements)
;     01-Dec-2014 - Laszlo I. Etesi (FHNW), - bugfix: script was reading all FITS files and failes in case it had no header; this is fixed
;     14-Jan-2015 - Laszlo I. Etesi (FHNW), - bugfix: a loop variable was changed outside inside an inner loop
;     15-Jan-2015 - Laszlo I. Etesi (FHNW), - bugfix: handling empty bins properly now
;     05-Feb-2015 - Laszlo I. Etesi (FHNW), added functionality to request duration of a scenario
;     24-Jul-2015 - Laszlo I. Etesi (FHNW), added a check before sorting; only sorting if necessary
;
;  :todo:
;     04-Dec-2014 - Laszlo I. Etesi (FHNW), - check the FITS contents to make sure it is a valid detector counts file
;-

function stx_sim_detector_events_fits_reader_indexed::init, directory, cachesize=cachesize
  default, cachesize, 5

  if ~dir_exist(directory) then begin
    message, directory + " does not exist", /continue
    return, 0
  end

  self.data_directory = directory
  files = find_file(concat_dir(directory, '*.fits'), count=n)
  dataindex = replicate({stx_sim_detector_events_fits_reader_index_entry}, n)
  dataindex.filename = files
  to_remove = list()

  for i=0L,n-1 do begin
    index_entry = hash()
    header = headfits(files[i],EXTEN=1)

    ; do this to ignore sources.fits, etc.
    if(is_number(header[0]) && header[0] eq -1) then continue

    dataindex[i].t_start = double(fxpar(header,'TIME0'))
    bins = list()
    t_bin_nr=0L

    repeat begin
      tbin_kw='TBIN'+trim(string(t_bin_nr, Format='(i3.3)'))
      tbin=long(fxpar(header,tbin_kw,count=count))
      
      ; count eq 0 means entry not found
      if(count eq 0) then break

      t_bin_nr++
      bins->add, tbin
    endrep until count eq 0

    n_bins = n_elements(bins)

    if n_bins eq 0 then begin
      to_remove->add, i
      continue
    end

    dataindex[i].t_end = dataindex[i].t_start + (n_bins * 4d)
    ; TODO single array for precision
    t_bin_start = dataindex[i].t_start + findgen(n_bins) * 4d
    t_bin_end = t_bin_start + 4d
    dataindex[i].t_bin_start =  ptr_new(t_bin_start)
    dataindex[i].t_bin_end =  ptr_new(t_bin_end)
    dataindex[i].bins = ptr_new(bins->toarray())
  end

  if n_elements(to_remove) gt 0 then remove, to_remove->toarray(), dataindex

  self.cache = ptr_new( replicate({stx_sim_detector_events_fits_reader_cache_entry}, cachesize))
  self.dataindex = ptr_new(dataindex)

  return, 1
end

pro stx_sim_detector_events_fits_reader_indexed::getproperty, $
  data_directory=data_directory
  
  if arg_present(data_directory) then data_directory = self.data_directory
end

function stx_sim_detector_events_fits_reader_indexed::total_time_span
  return, (min((*self.dataindex).t_start) + max((*self.dataindex).t_end))
end

function stx_sim_detector_events_fits_reader_indexed::read, t_start=t_start, t_end=t_end, sort=sort, safemode=safemode
  default, sort, 1
  default, initial_data_size, 10000000L
  default, increase_data_size,10000000L
  default, safemode, 0

  ; initializing data_all with a big array that is extended later
  ; setting relative_time to -1 to ensure the efficient filtering will work
  tmp_data = {stx_sim_detector_event}
  tmp_data.relative_time = -1
  data_all = replicate(tmp_data, initial_data_size)
  data_all_ptr = 0L
  data_all_size = n_elements(data_all)
  t_start_all = (*self.dataindex).t_start
  t_end_all = (*self.dataindex).t_end
  file_hits = where(t_end gt t_start_all and t_start lt t_end_all, count_file_hits )

  for i=0L, count_file_hits-1 do begin
    entry = (*self.dataindex)[file_hits[i]]
    t0 =  entry.t_start
    bins = *entry.bins
    n_bins = n_elements(bins)

    if n_bins lt 1 then continue

    hit_bins = where(*entry.t_bin_start lt t_end and *entry.t_bin_end gt t_start, count_hits)

    for hit=0L, count_hits-1 do begin
      if hit_bins[hit] eq 0 then rows = [0,bins[0]] else rows = [bins[hit_bins[hit] - 1]+1, bins[hit_bins[hit]]]

      data_found = 0

      ;search the data in the cache
      if ~safemode then begin
        for cache_i=0, n_elements(*self.cache)-1 do begin
          if ((*self.cache)[cache_i].filename eq entry.filename) && array_equal(rows, *((*self.cache)[cache_i].range)) then begin
            data_found = 1
            data = *((*self.cache)[cache_i].data)
            break;
          end
        end
      endif

      if ~data_found then begin
        ;read the data from file
        data = mrdfits(entry.filename, 1, range = rows, structyp='stx_sim_detector_event', /silent)
        
       
        
        ; in this case there is a data gap and the bin is skipped
        if(rows[0] gt rows[1]) then continue

        if(size(data, /dim) gt 0) then data.relative_time += t0
        
        ;TODO N.H.: check with Laszlo
        ;allready do the timefiltering here to avoid to much data
        good_times = where(data.relative_time ge t_start and data.relative_time le t_end, gtc)
        if gtc gt 0 then data = data[good_times] else data = data[0]

        if ~safemode then begin
          ;add the data block to the cache
          destroy, (*self.cache)[self.cache_next_entry]
          new_entry = {stx_sim_detector_events_fits_reader_cache_entry}
          new_entry.filename = entry.filename
          new_entry.range = ptr_new(rows)
          new_entry.data = ptr_new(data)
          (*self.cache)[self.cache_next_entry] = new_entry
          self.cache_next_entry++
          if self.cache_next_entry ge n_elements(*self.cache) then self.cache_next_entry=0
        end
      endif

      ;print,'rows',rows, rows[1]-rows[0]
      
      if size(data, /dim) gt 0 then begin
        data_elements = n_elements(data)

        ; grow if necessary
        if(data_elements + data_all_ptr ge data_all_size) then begin
          actual_increase = data_elements gt increase_data_size ? data_elements + increase_data_size : increase_data_size
          data_all = temporary([temporary(data_all), replicate(tmp_data, actual_increase)])
          data_all_size += actual_increase
        endif

        data_all[data_all_ptr] = data
        data_all_ptr += n_elements(data)
      endif
    endfor; hits

  endfor ;files

  ; combine time filtering and array compacting
  data_all_idx = where(data_all.relative_time ge t_start and data_all.relative_time le t_end, data_all_cnt)
  data_all_array = data_all_cnt gt 0 ? data_all[data_all_idx] : []

  if(sort AND (data_all_cnt gt 0)) then begin
    ; only sort if necessrary
    if(n_elements(data_all_array) le 1 || max((data_all_array.relative_time - shift(data_all_array.relative_time, -1))[0:-2]) lt 0) then $
      return, data_all_array $
      else $
      return, data_all_array[bsort(data_all_array.relative_time)]
  endif $
  else return, data_all_array
end

function stx_sim_detector_events_fits_reader_indexed::countEstimate, t_start=t_start, t_end=t_end

  data_all_size = n_elements(data_all)
  t_start_all = (*self.dataindex).t_start
  t_end_all = (*self.dataindex).t_end
  file_hits = where(t_end gt t_start_all and t_start lt t_end_all, count_file_hits )

  tot_count = ulong64(0)

  for i=0L, count_file_hits-1 do begin
    entry = (*self.dataindex)[file_hits[i]]
    t0 =  entry.t_start
    bins = *entry.bins
    n_bins = n_elements(bins)

    if n_bins lt 1 then continue

    hit_bins = where(*entry.t_bin_start lt t_end and *entry.t_bin_end gt t_start, count_hits)
    

    
    for hit=0L, count_hits-1 do begin
      if hit_bins[hit] eq 0 then rows = [0,bins[0]] else rows = [bins[hit_bins[hit] - 1]+1, bins[hit_bins[hit]]]

      tot_count += rows[1]-rows[0]
      
      ;print,'rows',rows, rows[1]-rows[0]
    endfor; hits

  endfor ;files

 return, tot_count
end


pro stx_sim_detector_events_fits_reader_indexed::cleanup
  heap_free, self.dataindex
  heap_free, self.cache
end

pro stx_sim_detector_events_fits_reader_index_entry__define
  void = { stx_sim_detector_events_fits_reader_index_entry, $
    filename    : '', $
    t_start     : 0L, $
    t_end       : 0L, $
    t_bin_start : ptr_new(), $
    t_bin_end   : ptr_new(), $
    bins        : ptr_new() $
  }
end

pro stx_sim_detector_events_fits_reader_cache_entry__define
  void = { stx_sim_detector_events_fits_reader_cache_entry, $
    filename    : '', $
    range       : ptr_new(), $
    data        : ptr_new() $
  }
end

function stx_sim_detector_events_fits_reader_indexed::_overloadPrint
  tempString = "my print";
  return, tempString
end

function stx_sim_detector_events_fits_reader_indexed::_overloadImpliedPrint, varname
  return, self->stx_sim_detector_events_fits_reader_indexed::_overloadprint()
end


function stx_sim_detector_events_fits_reader_indexed::_overloadHelp, varname
  tempString = list()
  tempString->add, varname + ' <stx_sim_detector_events_fits_reader_indexed> '

  foreach  entry,  *self.dataindex do begin
    help, entry, output = dataindex_help
    tempString->add, dataindex_help, /extract
  endforeach

  tempString->add, "Total "+trim(n_elements(*self.dataindex))+" files indexed"
  return, tempString->toarray();
end

pro stx_sim_detector_events_fits_reader_indexed__define
  void = {stx_sim_detector_events_fits_reader_indexed, $
    cache_next_entry : 0, $
    cache            : ptr_new(), $
    dataindex        : ptr_new(), $
    data_directory   : '', $
    inherits idl_object }
end

