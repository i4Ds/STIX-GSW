;+
; :description:
;     This procedure reads parameters of simulated events from array of structures,
;     and saves them into fits files.
;
; :params:
;     detector_events : in, required, type = 'array of stx_sim_detector_event structures'
;       array of structures containing parameters of the simulated events.
;       structures are defined by the procedure stx_sim_events_structure_define.pro
;     prefix : in, required, type='string'
;       base name of output fits file
;     reference_time : in, optional, type='double', default='min(detector_events.relative_time)'
;       value of T0 (generally encoded in relative_time)
;     file_4s_bins_number : in, optional, type='long', default='150'
;       number of 4sec bins to be saved in one fits file (default = 150)
;
; :keywords:
;     sort : in, optional, type='byte', default='0b'
;       sort the input array
;     base_dir : in, optional, type='string', default='.'
;       the base path to write out data
;     warn_not_empty : in, optional, type='byte', default='1b'
;       if set to 1, an error message will be shown if the directory is not empty
;       if set to 0, files will be added to the base_dir regardless if it is empty
;
;
; :history:
;     30-Jul-2014 - Marek Steslicki, Tomek Mrozek (Wro), initial release
;     01-Sep-2014 - Laszlo I. Etesi (FHNW), - changed from photons to detector events
;                                           - added base_dir, write_mode, and changed prefix to prefix
;                                           - using sxaddpar for FITS header writing (thus solving a bug)
;     04-Sep-2014 - Laszlo I. Etesi (FHNW), - bugfixing (correcting timing information and actual timing)
;     01-Dec-2014 - Laszlo I. Etesi (FHNW), - bugfixing: incorrect indexing (faulty start times, inconsistent number
;                                             of bins)
;                                           - added 'optimized' flag
;     12-Jan-2015 - Laszlo I. Etesi (FHNW), - bugfix: allowing time bins to be empty (continue)
;     15-Jan-2015 - Laszlo I. Etesi (FHNW), - bugfix: handling empty bins properly now
;     21-Jan-2015 - Laszlo I. Etesi (FHNW), - bugfix: handling time properly (incorrect reference time t0 applied)
;-
pro stx_sim_detector_events_fits_writer, detector_events, prefix, base_dir=base_dir, sort=sort, $
  reference_time=reference_time, file_4s_bins_number=file_4s_bins_number, warn_not_empty=warn_not_empty, $
  optimized=optimized

  default, base_dir, '.'
  default, sort, 0b
  default, reference_time, min(detector_events.relative_time)

  default, file_4s_bins_number, 150L
  default, warn_not_empty, 1b
  default, optimized, 0b

  if(~file_exist(base_dir)) then mk_dir, base_dir

  ; estimate start index
  files = file_search(base_dir, prefix + '_*.fits', count=files_count)

  if(files_count gt 0 and warn_not_empty) then begin
    stop
    message, "Base directory '" + base_dir + "' already contains data files for prefix '" + prefix + "'. Remove those files, or call this routine with 'write_mode' eq 0 or 2."
  end
  
  if(files_count gt 0) then begin
    ; crosscheck
    extract = stregex(files[-1], '([0-9]*)\.fits', /extract, /subexpr)
    start_idx = fix(extract[1], type=3) + 1
    if(start_idx ne files_count) then message, 'File numbering is off.'
  endif else start_idx = 0L

  ; copy detector_events
  detector_events_local = detector_events

  n=n_elements(detector_events_local)

  if sort then detector_events_local=detector_events_local[sort(detector_events_local[*].relative_time)]

  t_offset = reference_time mod 4

  fits_start_time=reference_time - t_offset

  t_start=min(detector_events_local.relative_time)
  t_end=max(detector_events_local.relative_time)

  delta_t=t_end-t_start+t_offset

  n_of_tbins=ceil(delta_t/4.d)

  tbins=lonarr(n_of_tbins)

  detector_events_local[*].relative_time-=fits_start_time
  times=detector_events_local[*].relative_time

  for i=0L,n_of_tbins-1 do tbins[i]=(reverse(where(times ge (i)*4L and times lt (i+1)*4L)))[0]
  last_points=where(times eq t_end+t_offset)
  if size(last_points,/dimensions) gt 0 then tbins[n_of_tbins-1]=(reverse(last_points))[0]

  t=0.d
  file_nr=0

  ; initialize empty header
  destroy, header

  ; added fits header info on optimization
  sxaddpar, header, 'OPTIMIZD', optimized

  sxaddpar, header, 'TIME0', trim(string(fits_start_time))
  
  ; keep the original fits start time separate
  new_fits_start_time = fits_start_time

  fbin_index=1L
  file_index=start_idx
  last_save_index=0L
  time0=0d

  for i=0L,n_of_tbins-1 do begin
    ; it is possible that bins are empty (depending on statistics and the scenario definition)
    ; in which case, the bin address is set to the previous address (if first bin, then zero)
    if(tbins[i]-last_save_index eq -1) then bin_addr = i gt 0 ? trim(string(bin_addr)) : '0' $
    else bin_addr = trim(string(tbins[i]-last_save_index))
    
    sxaddpar, header, 'TBIN' + trim(string(fbin_index-1, Format='(i3.3)')), bin_addr

    if fbin_index mod file_4s_bins_number eq 0 or i eq n_of_tbins-1 then begin
      if tbins[i] gt 0 then begin
        message,'events from '+trim(string(last_save_index))+' to '+trim(string(tbins[i]))+' ',/inf
        filename=concat_dir(base_dir, prefix+'_'+trim(string(file_index, Format='(i3.3)'))+'.fits')
        detector_events_local[last_save_index:tbins[i]].relative_time-=time0
        mwrfits, detector_events_local[last_save_index:tbins[i]], filename, header, /create
        message,'file '+trim(filename)+' saved',/inf
      endif
      file_index++
      last_save_index=tbins[i]+1

      ; reset header
      destroy, header

      new_fits_start_time += 4.d * (fbin_index)
      sxaddpar, header, 'TIME0', trim(string(new_fits_start_time))
      time0 = new_fits_start_time - fits_start_time
      fbin_index=0L

    endif
    fbin_index++
  endfor

end

