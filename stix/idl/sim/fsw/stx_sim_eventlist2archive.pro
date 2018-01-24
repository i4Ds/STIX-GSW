;+
; :description:
;   Converts a fully populated stx_sim_calibrated_detector_eventlist
;   to a flat array of stx_sim_archive_buffer. The routine makes a number
;   of assumptions concerning the input event list as follows:
;   1. The event list is fully populated with valid data. An unpopulated
;      event list entry will result in the archive_buffer[0].counts being
;      incremented. This could be incorrectly interpreted by any routine
;      making use of the archive_buffer as a valid count in time bin 0,
;      detector 0, pixel 0 and energy bin 0
;   2. The earliest time bin starts at start_time passed into the function. The
;      function updates this value to the end_time of the last complete time
;      bin found in the data. This value should be used as the start_time of
;      the first time bin on the next invocation of the function
;   3. The latest time bin is defined so that it contains the time in
;      eventlist.detector_events[no_events-1].relative_time i.e. the
;      eventlist entries are ordered by time - earliest to latest
;
; :params:
;   eventlist:  in, required, type="structure"
;                fully populated stx_sim_calibrated_detector_eventlist
;   start_time:  in/out, required, type="integer"
;                start time of the first time bin in integer ms from T0.
;                on exit, contains the start time of the first bin to be used
;                on the next invocation of this function
;   next_event:  out, required, type="integer"
;                eventlist.detector_event[next_event] to be processed on
;                next call to this routine
;
; :keywords:
;   t_max: in, optional, type="float", default = 1.0
;          maximum length of an accumulation time bin in units of 100ms
;   t_min: in, optional, type="float", default = 0.1
;          minimum duration of an accumulation time bin in seconds
;   n_min: in, optional, type="integer", default = 1
;          minimum number of counts in a time bin
;   m_acc: in, optional, type="byte_array", default="bytarr(32)+1b : all detectors"
;          32-bit mask selecting detectors to be used in count n_min
;          calculation
;
; :returns:
;   archive_buffer: out, type="array"
;                   flat array of type stx_sim_archive_buffer
;
; :history:
;   14-Feb-2014 - Mel Byrne (TCD), created routine
;   26-Feb-2014 - Mel Byrne (TCD), updated to account for t_min, t_max and
;                 n_min parameters described in the specification doc
;                 FSWaccumulationTiming20130618.docx
;   12-Mar-2014 - Mel Byrne (TCD), updated index variables n1,n2,n3,n4 and
;                 data structure dimension variables D1,D2,D3,D4 and count
;                 variable to ulong to support large data structures
;   29-Jul-2014 - Mel Byrne (TCD), updated so that time bin calculations are
;                 performed in units of integer ms.
;   30-Jul-2014 - Mel Byrne (TCD), updated so that the last time bin is not
;                 closed i.e. the events later than the end of the last complete
;                 time bin are removed from archive buffer. Parameter next_event
;                 returns the eventlist.detector_events index of the first
;                 entry to be processed on the next invocation of this function
;   20-Aug-2014 - Mel Byrne (TCD), bug fix, value of next_event passed back
;                 to the calling routine was being computed incorrectly
;   18-May-2015 - Mel Byrne (TCD), added /null keyword to where statement used in
;                 the calculation of in_events and out_events to fix double counting
;                 of the last event in eventlist evident when the last time bin
;                 is to be closed
;   24-sep-2015 - Mel Byrne (TCD), re-engineered the routine to make use of
;                 histogram reverse indices to bin events into the smallest
;                 possible time bins and then coalesce the fine bins into larger
;                 bins as required/allowed. The entire time range is now covered
;                 with bins so that events with masked out energies are not lost
;                 when we come to bin them. Added m_channel keyword which allows
;                 events from specified energy channels to be masked out of the
;                 binning processed. These masked out events get binned and added
;                 to the archive buffer but do not contribute to the
;                 time binning decision process.
;   01-oct-2015 - Laszlo I. Etesi (FHNW), removed info message
;   07-oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;   12-oct-2015 - Laszlo I. Etesi (FHNW), bugfix in case where we have data in every bin (remove
;                                         on archive buffer checks first if there is anything to remove)
;   10-dec-2015 - Laszlo I. Etesi (FHNW), minor bugfix: array brackets in call to histogram
;   25-jan-2016 - Mel Byrne (TCD), bugfix, added det_in_events variable so that m_acc and m_channel
;                                  filtering work from the same list of events from good detectors
;   16-Feb-2015 - Laszlo I. Etesi (FHNW), change behaviour of nmin from lookahead to current value
;   10-May-2016 - Laszlo I. Etesi (FHNW), fixed a time-related round-off error
;   
; :todo:
;   17-dec-2015 - Laszlo I. Etesi (FHNW), - n_min should actually be n_max (maximum counts per bin)
;                                         - m_channel only defines which energies to include in comparing
;                                           to n_max, not actually removes counts!
;                                         
;-

function stx_sim_eventlist2archive, eventlist, start_time, next_event, $
  t_max=t_max, t_min=t_min, n_min=n_min, m_acc=m_acc, $
  m_channel = m_channel, close_last_time_bin = close_last_time_bin

  default, t_max, 1.0d   ; maximum duration of accumulation, units 100ms
  default, t_min, 0.1d   ; minimum duration of accumulation, units seconds
  default, n_min, 1     ; minimum number of accumulated counts
  default, m_acc, bytarr(32)+1b      ; mask of detectors included in accumulation
  default, m_channel, bytarr(32)+1b  ; mask of energy channels included in accumulation
  
  ; compute the list of masked in events from m_acc
  masked_in_dets = m_acc * (indgen(32)+1)
  masked_in_dets = masked_in_dets[where(masked_in_dets ne 0)]

  in_events = [-1]
  for i=0, n_elements(masked_in_dets)-1 do $
    in_events  = [in_events, where(eventlist.detector_events.detector_index eq masked_in_dets[i])]

  in_events = in_events[where(in_events ne -1, /null)]
  det_in_events = eventlist.detector_events[in_events]
  masked_in_events = det_in_events
  
  ; compute the list of masked in events from m_channels
  masked_in_channels = m_channel * (indgen(32)+1)
  masked_in_channels = masked_in_channels[where(masked_in_channels ne 0)]

  in_events = [-1]
  for i=0, n_elements(masked_in_channels)-1 do $
    in_events  = [in_events, where(masked_in_events.energy_science_channel eq masked_in_channels[i] - 1)]
  in_events = in_events[where(in_events ne -1, /null)]

  if n_elements(in_events) ne 0 then begin
    masked_in_events = masked_in_events[in_events]
    masked_in_events.relative_time *= 1000d
  endif
  
  ; compute list of masked-out events from m_channel
  masked_out_channels = (~m_channel) * (indgen(32)+1)
  masked_out_channels = masked_out_channels[where(masked_out_channels ne 0)]
  
  out_events = [-1]
  for i=0, n_elements(masked_out_channels)-1 do $
    out_events = [out_events, where(det_in_events.energy_science_channel eq masked_out_channels[i] - 1)]
  out_events = out_events[where(out_events ne -1, /null)]

  if n_elements(out_events) ne 0 then begin
    masked_out_events = det_in_events[out_events]
    masked_out_events.relative_time *= 1000d
  endif
  
  ; convert t_min and t_max to ms - all time bin calculations in integer ms from here
  t_min_accum = ulong64(t_min * 1000.0d0)
  t_max_accum = ulong64(t_max * 100.0d0)
  n_max_bins = ceil(t_max_accum / t_min_accum)

  ; and this is where the magic happens...
  h = histogram([masked_in_events.relative_time], min = start_time, binsize = t_min_accum, reverse_indices = ri)
  
  ; compute largest possible archive_buffer
  n_time_bins = n_elements(h)  
  n_detectors = 32
  n_pixels = 12
  n_energies = 32

  ; use D1,D2,D3 and D4 as short-hand for the dimensions of the array
  D1 = ulong64(n_time_bins)
  D2 = ulong64(n_detectors)
  D3 = ulong64(n_pixels)
  D4 = ulong64(n_energies)

  ; allocate the archive_buffer array
  archive_buffer = replicate({stx_fsw_archive_buffer}, D1 * D2 * D3 * D4)
  ;message, /info, 'archive_buffer allocated'
  
  ; and now we count the masked_in_events from the h histogram into archive_buffer
  i = 0
  bin_pair = []
  
  ; compute bin_pair array - this is where most of the binning requirements are met
  repeat begin
    n_bins = 1

    while (i+n_bins-1 lt n_time_bins-1) and (total(h[i:i+n_bins-1]) le n_min) and (n_bins-1 lt n_max_bins) do $
      n_bins += 1

    n_bins = n_bins > 1

    bin_pair = [bin_pair, i, n_bins]
    i += n_bins
  endrep until (i ge n_time_bins-1)

  ; use bin_pair & ri arrays to compute events in each bin and
  ; package into the archive_buffer
  n1 = 0ul
  ; lie: workaround to avoid roundoff errors
  t_start = ulong64(float(start_time))
  bin_pair = reform(bin_pair, 2, n_elements(bin_pair)/2)
  
  for i=0,(size(bin_pair))[2]-1 do begin
    first_bin = bin_pair[0, i]
    last_bin = first_bin + bin_pair[1, i] - 1
    t_end = t_start + t_min_accum * bin_pair[1, i]
    
    if i eq (size(bin_pair))[2]-1 then last_bin += 1
    
    bin_events = []
    for j=first_bin, last_bin do begin
      if ri[j] lt n_elements(ri) then begin
        k = reverseindices(ri, j)
      
        if total(k) ne -1 then $
          bin_events = [bin_events, k]
      endif    
    endfor
    
    if n_elements(bin_events) ne 0 then begin
      n2 = ulong64(masked_in_events[bin_events].detector_index-1)
      n3 = ulong64(masked_in_events[bin_events].pixel_index)
      n4 = ulong64(masked_in_events[bin_events].energy_science_channel)
      
      j = n1 + D1*(n2 + D2*(n3 + D3*n4))
      archive_buffer[j].relative_time_range[0] = t_start
      archive_buffer[j].relative_time_range[1] = t_end 
      archive_buffer[j].detector_index = n2
      archive_buffer[j].pixel_index = n3
      archive_buffer[j].energy_science_channel = n4
      archive_buffer[j].counts++
    endif

    if masked_out_events ne !NULL then begin
      t = where(masked_out_events.relative_time ge t_start and masked_out_events.relative_time lt t_end)
      
      if (fix(total(t)) ne -1) then begin
        n2 = ulong64(masked_out_events[t].detector_index-1)
        n3 = ulong64(masked_out_events[t].pixel_index)
        n4 = ulong64(masked_out_events[t].energy_science_channel)
        
        j = n1 + D1*(n2 + D2*(n3 + D3*n4))
        archive_buffer[j].relative_time_range[0] = t_start
        archive_buffer[j].relative_time_range[1] = t_end
        archive_buffer[j].detector_index = n2
        archive_buffer[j].pixel_index = n3
        archive_buffer[j].energy_science_channel = n4
        archive_buffer[j].counts++

        if n_elements(masked_out_events) eq n_elements(t) then $
          masked_out_events = [] $
        else $
          remove, t, masked_out_events
      endif
    endif

    n1 += 1ul
    t_start_last_bin = t_start
    t_start = t_end
  endfor

  ; will we be removing all of the archive_buffer entries?
  remove_entries = where(archive_buffer.counts eq 0, rem_count1)
  if (n_elements(archive_buffer) eq n_elements(remove_entries)) then $
    return, [] $
  else if (rem_count1 gt 0) then $
    ; remove all archive_buffer entries which have not received a count
    remove, remove_entries, archive_buffer

  if keyword_set(close_last_time_bin) then begin
    start_time = t_end
    next_event = n_elements(eventlist.detector_events) + 1
  endif else begin
    ; consider the last time bin as incomplete - two steps as follows:
    ; - remove all entries from the archive buffer in the last time bin
    remove_entries = where(archive_buffer.relative_time_range[0] eq t_start_last_bin, rem_count2)
    if (n_elements(archive_buffer) eq n_elements(remove_entries)) then $
      return, [] $
    else if (rem_count2 gt 0) then $
      remove, remove_entries, archive_buffer

    ; - provide next event details to calling routine
    start_time = t_start_last_bin
    next_event = where(eventlist.detector_events.relative_time * 1000d ge start_time)
    next_event = next_event[0]
  endelse
  
  ; updating the archive_buffer to comply with subcollimator numbering scheme
  ; and to have time in seconds
  archive_buffer.detector_index += 1
  archive_buffer.relative_time_range /= 1000d
  
  return, archive_buffer
end
