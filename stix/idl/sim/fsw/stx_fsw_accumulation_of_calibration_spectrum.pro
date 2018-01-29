;+
; :description
;    This procedure create a calibration spectrum by accumulation of photons, and calculate the live time associated with this accumulation.
;    The criteria for selecting 'background photons' to accumulate is a criteria on the time interval between the considered event and the previous one.
;    This time interval has to be smaller than the value specified by Tq.
;    NB: This routine may not be able to deal properly with data gaps greather than t_bin_width (due to relative time scaling)
;
; :categories:
;   STIX flight software simulator
;
;
; :params:
;   eventlist : in, required, type='stx_sim_detector_eventlist'
;     the temperature-corrected detector eventlist
;
; :keywords:
;   calibration_spectrum : in, optional, type='stx_sim_calibration_spectrum', default='stx_sim_calibration_spectrum()'
;     contains the result of the previous run of this procedure : calibration spectrum, livetime, and the time of gate opening
;     This is reset if the value passed isn't a structure with a type name of 'stx_sim_calibration_spectrum'
;
;   tq : in, optional, type='float', default='0.001'
;     the quiet time (tq gate) in seconds
;
;   ts : in, optional, type='float', default='0.0'
;     the software readout time (ts gate) in seconds; currently one fixed value, should
;     later maybe become a probability or an array that triggers an extensive readout timeout
;
;   t_bin_width : in, optional, type='double', default='4.0d0'
;     the width in seconds of the data range in time between the first and last event (specifically
;     added to handle the FSW SIM 4-second processing interval)
;     eventlist.relative_time is changed to time mod t_bin_width
;
;   livetime : out, optional, type='double'
;     this is the accumulated livetime for this data bin; this is NOT a global livetime accumulator, which is
;     attached to the calibration spectrum structure; livetime is always calculated over the maximum possible
;     time for this bin (i.e. from t_start to t_start + t_bin_width); there is special livetime handling at the
;     end of every data bin: if TQ is open at the end of this time bin, t_start + t_bin_width - event.relative_time is accumulated
;     as "partial" livetime to this bin.
;   active_detectors :   default, active_detectors, bytarr(32) + 1b, 1 active, 0 inactive
;     only the counts from active detectors are accumulated and if EXCLUDE_BAD_DETECTORS is set then the inactive detectors
;     are removed from the gating logic as well
;     use EXCLUDE_BAD_DETECTORS to condition output
;
;
;   exclude_bad_detectors : default, exclude_bad_detectors, 1b
;
; :returns:
;   an updated calibration spectrum
;
; :example:
;   calibration_spectrum = stx_fsw_accumulation_of_calibration_spectrum(eventlist)
;
; :history:
;   25-Feb-2014 - Sophie Musset (LESIA), initial release
;   25-Feb-2014 - Laszlo I. Etesi (FHNW), renamed file and applied minor corrections, using new stx_sim_calibrated_spectrum structure
;   18-Apr-2014 - Sophie Musset (LESIA), change order of indices in 'accumulation_counts'
;   28-Jul-2014 - Sophie Musset (LESIA), add old_calibration_spectrum as keyword and addition of current accumulated counts and old counts before returning the result
;                                        change 'accumulation_counts' to 'new_calibration_spectrum.accumulated_counts'
;   24-Mar-2015 - Laszlo I. Etesi (FHNW), - bugfix: for loop 'i' set to LONG
;                                         - speed improvements (loop replaced by inc operator)
;   20-May-2015 - Laszlo I. Etesi (FHNW), major overhaul of the routine to allow for using ts for the software readout time; also
;                                         handling FSW SIM data bin boundaries properly
;   26-May-2015 - Laszlo I. Etesi (FHNW), accumulating livetime instead of deadtime
;   27-May-2015 - rschwartz70@nasa.gov, refactored using tq_open concept
;   28-May-2015 - Laszlo I. Etesi (FHNW), - added a comment to the description header
;                                         - changed test of calibration spectrum at the very beginning of routine
;   29-Jul-2015 - richard schwartz (gsfc) - added active_detectors mask (1 include) and exclude_bad_detectors (1 means exclude)
;   31-Mar-2016 - Laszlo I. Etesi (FHNW), - updated implementation to match the actual FPGA/ASW implementation (different TS and TQ gate handling)
;   10-May-2016 - Laszlo I. Etesi (FHNW), - minor updates to accomodate new structures
;   25-Jan-2017 - Laszlo I. Etesi (FHNW), added code (commented out) used during the FPGA testing (exact tracking of events)
;-

pro _extract_subseconds_seconds_from_timestamp, timestamp, seconds, subseconds
  seconds_bits = 32
  subseconds_bits = 16

  ; extract seconds first
  t_seconds = ulong(timestamp)
  seconds = t_seconds and 2L^(seconds_bits)-1

  ; extract subseconds
  t_subseconds = timestamp - ulong(timestamp)
  subseconds = 0UL

  ; loop over all the fraction bits
  ; and add them up
  for i = 1L, subseconds_bits do begin
    binary_val = 2d^(-i)

    div = t_subseconds / binary_val

    if(div ge 1.0) then begin
      subseconds += 2UL^(subseconds_bits - i)
      t_subseconds -= binary_val
    endif
  endfor
end

pro stx_fsw_accumulation_of_calibration_spectrum, events_in, $
  calibration_spectrum=calibration_spectrum, $
  tq=tq, ts=ts, $
  livetime=livetime, $
  t_bin_width=t_bin_width, $
  active_detectors = active_detectors, $
  exclude_bad_detectors = exclude_bad_detectors

  ; test if calibration_spectrum is valid
  if(~ppl_typeof(calibration_spectrum, compareto='stx_fsw_m_calibration_spectrum')) then calibration_spectrum = stx_fsw_m_calibration_spectrum()

  default, tq, 0.001
  default, ts, 0.0
  default, t_bin_width, 4.0d
  default, active_detectors, bytarr(32) + 1b
  active_detectors = byte( ( active_detectors < 1b ) > 0b )
  default, exclude_bad_detectors, 1b
  events = events_in
  if exclude_bad_detectors && min( active_detectors ) eq 0 then begin
    good = where(  active_detectors[ events.detector_index -1 ], ngood )
    events = events [ good ]
  endif

  ; set livetime to zero for this set of events
  livetime = 0.0d

  ; read number of input events
  n_events = n_elements(events)

  ; check validity of t_bin_width and change to 0 for long eventlists
  t_bin_width =   (events[ n_events -1 ].relative_time - events[0].relative_time ) gt t_bin_width ? 0.0 : t_bin_width

  ; workaround for the FPGA testing, keep original resolution
  original_eadc = events.energy_ad_channel

  ; degrade energy ad channels
  events.energy_ad_channel = ishft(events.energy_ad_channel, -2)

  ; for FPGA and FSW testing, keep original times
;  original_relative_time = events.relative_time

  ; In case the caller hasn't removed the offset time from the t_bin_width long packet
  if t_bin_width gt 0 then events.relative_time = events.relative_time mod t_bin_width
  tq_open = calibration_spectrum.tq_open
  ts_open = calibration_spectrum.ts_open

  ;t_event = ts > tq ;set tq_open forward by t_event if we accumulate

  ; the basic idea here is to look back and compare the current event with the gate closing times from last bin

  ; special handling for FPGA and FSW testing
;  void = { stx_sim_fsw_single_calib_event, $
;    relative_time: 0d, $
;    pixel_index: 0b, $
;    detector_index: 0b, $
;    original_eadc: uint(0), $
;    energy_ad_channel: uint(0) $
;  }

;  s_calib_event_ptr = 0l

;  all_calib_events = replicate(void, n_events)

  for eid = 0L, n_events-1 do begin
    curr_event = events[eid]
    is_active = active_detectors[ curr_event.detector_index - 1 ]

    if(~is_active) then stop

    if curr_event.relative_time lt ts_open then continue $
      ; advance to the next event if not open and change tq_open if needed
    else if curr_event.relative_time lt tq_open && is_active then $
      ; if the gate isn't open, advance the opening time if necessary
      tq_open = (curr_event.relative_time + tq) > tq_open $
    else begin
      ; accumulate event
      calibration_spectrum.accumulated_counts[$
        curr_event.energy_ad_channel, $
        curr_event.pixel_index, $
        curr_event.detector_index - 1]++

      ; only used for FPGA testing
;     ; write event data to file
;     all_calib_events[s_calib_event_ptr].relative_time = original_relative_time[eid]
;     all_calib_events[s_calib_event_ptr].pixel_index = curr_event.pixel_index
;     all_calib_events[s_calib_event_ptr].detector_index = curr_event.detector_index-1
;     all_calib_events[s_calib_event_ptr].original_eadc = original_eadc[eid]
;     all_calib_events[s_calib_event_ptr].energy_ad_channel = curr_event.energy_ad_channel
;;
;      s_calib_event_ptr++
;
;      header = ~file_exist('calibration_spectrum_events.csv')
;      openw, lun, 'calibration_spectrum_events.csv', /get_lun, /append
;      if(header) then printf, lun, 'RELATIVE TIME, PIXEL INDEX, DETECTOR INDEX, ENERGY AD CHANNEL, ENERGY AD CHANNEL SW'
;      printf, lun, curr_event.relative_time, ',', curr_event.pixel_index, ',', curr_event.detector_index-1, ',', original_eadc[eid], ',', curr_event.energy_ad_channel, $
;      format='(D32, A, I, A, I, A, I, A, I)'
;      free_lun, lun

      ; calculate livetime
      livetime += curr_event.relative_time - tq_open

      ; close the gate until t_event passes from the event time
      ts_open = (curr_event.relative_time + ts) > ts_open
      tq_open = (ts_open + tq) > tq_open
    endelse
  endfor

;  if(s_calib_event_ptr gt 0 and getenv('WRITE_CALIBRATION_SPECTRUM') eq 'true') then begin
;    all_calib_events = all_calib_events[0:s_calib_event_ptr-1]
;    ;header = ~file_exist('calibration_spectrum_events.csv')
;    ;openw, lun, 'calibration_spectrum_events.csv', /get_lun, /append
;    ;if(header) then printf, lun, 'RELATIVE TIME, PIXEL INDEX, DETECTOR INDEX, ENERGY AD CHANNEL, ENERGY AD CHANNEL SW'
;    
;    ; binary format for ESC
;    openw, lun_bin, 'calib_spectrum.bin', /get_lun, /append
;    
;    for curr_event_i = 0, n_elements(all_calib_events)-1 do begin
;      curr_event = all_calib_events[curr_event_i]
;
;      ; prepare and write binary
;      _extract_subseconds_seconds_from_timestamp, curr_event.relative_time, seconds, subseconds
;      
;      prep_seconds = ulong(seconds)
;      prep_subseconds = uint(subseconds)
;      prep_pixel = byte(curr_event.pixel_index)
;      prep_detector = byte(curr_event.detector_index)
;      prep_eadc = uint(original_eadc[curr_event_i])
;      
;      if (prep_seconds lt 0 || prep_seconds gt 410) then stop
;      if (prep_subseconds lt 0 || prep_subseconds gt 65535) then stop
;      if (prep_pixel lt 0 || prep_pixel gt 11) then stop
;      if (prep_detector lt 0 || prep_detector gt 31) then stop
;      if (prep_eadc lt 0 || prep_eadc gt 4096) then stop
;      
;
;      writeu, lun_bin, swap_endian(prep_seconds, /swap_if_little_endian)
;      writeu, lun_bin, swap_endian(prep_subseconds, /swap_if_little_endian)
;      writeu, lun_bin, swap_endian(prep_pixel, /swap_if_little_endian)
;      writeu, lun_bin, swap_endian(prep_detector, /swap_if_little_endian)
;      writeu, lun_bin, swap_endian(prep_eadc, /swap_if_little_endian)
;      ;printf, lun, curr_event.relative_time, ',', curr_event.pixel_index, ',', curr_event.detector_index-1, ',', original_eadc[curr_event_i], ',', curr_event.energy_ad_channel, format='(D32, A, I, A, I, A, I, A, I)'
;    endfor
;
;    free_lun, lun_bin
;    ;free_lun, lun
;
;    ;save, all_calib_events, filename='calibration_events_' + trim(string(all_calib_events[0].relative_time)) + '.sav', /compress
;  endif

  ; adjust live time and gate timestamps
  calibration_spectrum.live_time += livetime
  tq_open -= t_bin_width
  ts_open -= t_bin_width
  calibration_spectrum.tq_open = tq_open
  calibration_spectrum.ts_open = ts_open
end