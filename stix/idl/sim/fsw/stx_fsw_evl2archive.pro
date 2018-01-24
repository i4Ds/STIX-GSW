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
;   t_min: in, optional, type="float", default = 1.0
;          minimum duration of an accumulation time bin in 100 ms
;   n_min: in, optional, type="integer", default = 1
;          minimum number of counts in a time bin
;   nbase: in, type="integer", default = 1
;          minimum size of accumulation bins in units 0.1 sec, base time bin
;          size. t_max and t_min must be integer multiples of ntmin
;   m_acc: in, optional, type="byte_array", default="bytarr(32)+1b : all detectors"
;          32-bit mask selecting detectors to be used in count n_min
;          calculation
;   
;
; :returns:
;   archive_buffer: out, type="array"
;                   flat array of type stx_sim_archive_buffer
;
; :history:
;   16-May-2016 - rschwartz70@gmail.com, written, based on stx_sim_eventlist2archive
;   18-may-2016 - rschwartz70@gmail.com, pass CLOSE_LAST_TIME_BIN to stx_sim_find_accum_boundaries
;   25-may-2016 - rschwartz70@gmail.com, in CLOSE_LAST_TIME_BIN not set, then the last bin must be open as
;   we haven't seen a time past the last time
;   31-may-2016 - rschwartz70@gmail.com, on close_last, check last time range to be sure
;   it is >= t_min * 0.1 (in seconds), now we include all detectors in building the archive buffer
;   and rely on the original mask to eliminate those that aren't included
;   3-jun-2016 - rschwartz70@gmail.com, We now allocate the archive_buffer and add the rel_time more efficiently in the
;   next line. Here we only have to build the single time archive_buffer once and then
;   reuse it.  Smarter!
;   7-jun-2016 - rschwartz70@gmail.com, make sure time bins are finite
;   11-oct-2016 - Laszlo I. Etesi (FHNW), minor bugfix for histogram (for when only one element is passed in)
;   29-nov-2016 - rschwartz70@gmail.com, code added to support problem in 8.2 with single element ktbin
; :todo:
;
;-

function stx_fsw_evl2archive, eventlist, start_time, next_event, $
  t_max=t_max, t_min=t_min, n_min=n_min, m_acc=m_acc, $
  m_channel = m_channel, nbase = nbase, close_last_time_bin = close_last_time_bin

  default, t_max, 10.0d   ; maximum duration of accumulation, units 100ms
  default, t_min, 1.0d   ; minimum duration of accumulation, units 100ms
  default, n_min, 1      ; min bin threshold number of accumulated counts, form a grouped bin when it reaches n_min
  default, m_acc, bytarr(32)+1b      ; mask of detectors included in accumulation
  default, m_channel, bytarr(32)+1b  ; mask of energy channels included in accumulation
  default, nbase, 1      ;size of base accumulation bins in units 100ms
  ;t_max and t_min must be integer multiples of ntmin
  n_t_max = round( 1.0 * t_max / nbase ) ;number of base bins in t_max 
  n_t_min = round( 1.0 * t_min / nbase ) ;number of base bins in t_min 
  next_event = 0L ;if no bins are found, the next_event is the start of the current input
  ;first remove non-valid events based on m_acc
  dmask = m_acc[ eventlist.detector_events.detector_index -1 ]
  ;only include valid events
  events = eventlist.detector_events[ where( dmask ) ]
  ; reformat events to make everything integer arithmetic
  evnt = replicate( {tbin: 0L, det_id: 0b, pixel_index: 0b, energy_science_channel:0b, emask:0b}, n_elements(events))

  
  evnt.det_id                    = events.detector_index -1
  evnt.pixel_index               = events.pixel_index
  evnt.energy_science_channel    = events.energy_science_channel
  evnt.emask                     = m_channel[ evnt.energy_science_channel]
  start_time_sec = start_time / 1000.

  evnt.tbin = floor( 1L * (events.relative_time - start_time_sec) / (nbase* 0.1)) ;time in fundamental acc step
  ;find the evnt to use and find their time bin group ids
  ;evnt.tbin will change from the bin number to the group ids and
  ;will set the end of the used events
  cntbin = histogram( [evnt[ where( evnt.emask )].tbin], loc=tbin_st, min=0 ) ;total counts for masked in energies and dets per tbin
  ;if close_last_time_bin isn't set, then remove the last edge
  if ~close_last_time_bin then cntbin = cntbin[0:-2]

  ;now get the grouped bin boundaries. The first unused event is the
  ;first event after the last group bin
  ;inputs to boundary finder in units of fundamental time bin, fntmin, so it does need to be passed
  mincnt = n_min ;this variable name has more meaning
  ktbin = stx_sim_find_accum_boundaries( cntbin,  mincnt, n_t_min, n_t_max, close_last_time_bin = close_last_time_bin )
  if n_elements( ktbin ) eq 1 then return, -1 ;no grouped bins found
  ;add the final bin edge and form a 1d list of edges in units of tbin
  ktbin =  [ reform( ktbin[0,*]), ktbin[-1] + 1 ]

  ;remove any evnt not within the group bin time range
  include = where( evnt.tbin lt ktbin[-1], nuse, comp = comp, ncomp = ncomp)
  evnt = evnt[include]
  ;The gbin is the index of the grouped time bins. Every tbin (sub-time) has a gbin index starting at 0
  ;Be sure the bin edges are unique
  ktbin = get_uniq( ktbin )
  ;;;;;;;RAS, 29-nov-2016 added to support problem in 8.2 with single element ktbin
  ;gbin  = value_locate(ktbin[0:-2] , evnt.tbin)
  vktbin = n_elements( ktbin ) gt 2 ? ktbin[0:-2] : ktbin
  gbin  = value_locate( vktbin, evnt.tbin)
  ;;;;;;;;;;;RAS, 29-nov-2016, end changes
  evnt.tbin = gbin

  ;Make the rotating buffer, flat array
  n_energies = 32
  n_detectors = 32 
  n_pixels   = 12
  n_gbins    = gbin[-1] + 1
  
  ;Build the rotating buffer histogram
  rot_buffer = lonarr( n_energies, n_detectors, n_pixels, n_gbins )
  ;Build the count histograms into the rotating buffer with the next line
  ;in old FORTRAN, BASIC you'd have a do loop running thru every evnt and increment the counter in
  ;each bin based on the energy, det, pixel, and tbin address. This next line does the same thing but asap
  rot_buffer[ evnt.energy_science_channel, evnt.det_id, evnt.pixel_index, evnt.tbin ]++
  ;convert the time bins into rel time
  rel_time = 0.1*nbase * ktbin
  
  rel_time = get_edges( /edges_2, rel_time )
  if close_last_time_bin then begin
    ;make sure bin isn't shorter than t_min * 0.1
    rel_time[-1] >= rel_time[-2] + 0.1 * t_min
  endif
  ; allocate the archive_buffer array
;  archive_buffer = replicate({stx_fsw_archive_buffer}, n_energies, n_detectors, n_pixels, n_gbins )
;  for i = 0, n_energies  - 1 do archive_buffer[ i, *, *, * ].energy_science_channel = i
;  for i = 0, n_detectors - 1 do archive_buffer[ *, i, *, * ].detector_index = i + 1
;  for i = 0, n_pixels    - 1 do archive_buffer[ *, *, i, * ].pixel_index    = i
;  for i = 0, n_gbins     - 1 do archive_buffer[ *, *, *, i ].relative_time_range = rel_time[*,i]
; We now allocate the archive_buffer and add the rel_time more efficiently in the 
; next line. Here we only have to build the single time archive_buffer once and then
; reuse it.  Smarter!
  archive_buffer = stx_fsw_bld_archive_buffer( rel_time )
  
  archive_buffer.counts = rot_buffer
  archive_buffer.relative_time_range += start_time_sec

  ;remove 0 count bins
  z = where( archive_buffer.counts ge 1 )
  start_time_sec += rel_time[-1]
  next_event = (where( eventlist.detector_events.relative_time  ge start_time_sec, next ))[0]

  start_time = round( start_time_sec * 1000.d0 )
  ;return next index for input eventlist

  return, archive_buffer[z]
end


