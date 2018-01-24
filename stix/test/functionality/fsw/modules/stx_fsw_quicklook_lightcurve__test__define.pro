;+
;  :description
;    Unit test for lightcurve product of the quicklook accumulator ["qla"] module in the flight software simulator.
;
;  :categories:
;    Flight Software Simulator, quicklook accumulator, testing
;
;  :examples:
;    res = iut_test_runner('stx_fsw_quicklook_lightcurve__test')
;   
;  :history:
;    10-may-2015 - Aidan O'Flannagain (TCD), initial release
;    19-may-2015 - Aidan O'Flannagain (TCD), updated to iut_test_runner format
;    01-jul-2015 - Aidan O'Flannagain (TCD), now use $SSW_STIX environment variable to get to config file
;    30-oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;    10-may-2016 - Laszlo I. Etesi (FHNW), using construct time
;-
pro stx_fsw_quicklook_lightcurve__test::beforeclass
  ;prepare input to detector failure module
  events = replicate(stx_sim_calibrated_detector_event(), 1000)

  ;prepare an energy array with a distinctive shape (gaussian) for the energy distribution test
  pos = 16.
  energy_science_channels = (randomu(seed, n_elements(events), /double, /normal)*4.) + pos
  ;simply move energy values outside of the range [1,32] to the centre of the gaussian
  energy_science_channels[where(energy_science_channels lt 0)] = pos
  energy_science_channels[where(energy_science_channels gt 32)] = pos
  
  events.energy_science_channel = energy_science_channels
  events.detector_index = fix(randomu(seed, n_elements(events)) * 32 + 1)
  events.pixel_index = fix(randomu(seed, n_elements(events)) * 12)
  relative_time = randomu(seed, n_elements(events)) * 4.
  ;time-order the events
  events.relative_time = relative_time[sort(relative_time)] 
  eventlist = ptr_new(stx_construct_sim_detector_eventlist(start_time=0, detector_events=events, sources=stx_sim_source_structure()))
  triggerlist = ptr_new(stx_construct_sim_detector_eventlist(start_time=0, detector_events=events, sources=stx_sim_source_structure()))
  
  ;set the list types to their "correct" names
  (*eventlist).type = 'stx_sim_calibrated_detector_eventlist'
  (*triggerlist).type = 'stx_sim_event_triggerlist'
  
  interval_start_time = stx_construct_time(time=0)
  
  ;finally, prepare the configuration parameters
  conf_file = getenv('SSW_STIX') + "/dbase/conf/qlook_accumulators.csv"
  quicklook_config_struct = stx_fsw_ql_accumulator_table2struct(conf_file)
  ;since we're only looking at the lightcurve, take the first element of the config struct
  quicklook_config = ptr_new(quicklook_config_struct[0])
  
  active_detectors = bytarr(32) + 1
  
  self.eventlist = eventlist
  self.triggerlist = triggerlist
  self.interval_start_time = interval_start_time
  self.active_detectors = active_detectors
  self.quicklook_config = quicklook_config

end

;+
; cleanup at object destroy
;-
pro stx_fsw_quicklook_lightcurve__test::afterclass


end

;+
; cleanup after each test case
;-
pro stx_fsw_quicklook_lightcurve__test::after


end

;+
; init before each test case
;-
pro stx_fsw_quicklook_lightcurve__test::before


end

;+
; :description:
;   Run the module script with no active detectors.
;   Output lightcurve product should have zero counts.
;-
pro stx_fsw_quicklook_lightcurve__test::test_no_active_detectors
  
  ;set all detector active states to zero
  active_detectors = intarr(32)
  active_detectors[*] = 0
  out = stx_fsw_eventlist_accumulator(*self.eventlist, interval_start_time=self.interval_start_time, _extra=*self.quicklook_config, active_detectors=active_detectors)
  
  flux_ne_zero = where(out.accumulated_counts ne 0, num_fail)
  
  mess = ''
  if num_fail[0] ne 0 then mess = strjoin(['Detectors inactive test: counts were accumulated in energy bands:', strarr(num_fail)] + strcompress(flux_ne_zero))
  assert_true, num_fail eq 0, mess
end

;+
; :description:
;   Run the module script with only the non-Fourier (the background monitor and course flare locator)
;   detectors in the active state.
;   Output lightcurve product should have zero counts.
;-
pro stx_fsw_quicklook_lightcurve__test::test_non_fourier_only
  
  ;set all detector active states to zero
  active_detectors = intarr(32)
  active_detectors[*] = 0
  ;re-set the non-Fourier detectors to active
  active_detectors[8:9] = 1
  out = stx_fsw_eventlist_accumulator(*self.eventlist, interval_start_time=self.interval_start_time, _extra=*self.quicklook_config, active_detectors=active_detectors)
  
  flux_ne_zero = where(out.accumulated_counts ne 0, num_fail)
  
  mess = ''
  if num_fail[0] ne 0 then mess = strjoin(['Detectors inactive test: counts were accumulated in energy bands:', strarr(num_fail)] + strcompress(flux_ne_zero))
  assert_true, num_fail eq 0, mess
end

;+
; :description:
;   Check that the total number of counts in the lightcurve product is equal to the number
;   of events in the eventlist that land on fourier detectors.
;-
pro stx_fsw_quicklook_lightcurve__test::test_total_counts
  
  out = stx_fsw_eventlist_accumulator(*self.eventlist, interval_start_time=self.interval_start_time, _extra=*self.quicklook_config, active_detectors=self.active_detectors)
  
  ;determine the number of events that recorded by detectors numbered all of 1-32 excluding 9 (bkg) and 10 (cfl)
  ;first prepare an array of fourier detectors
  fourier_dets = indgen(30)+1
  fourier_dets[8:-1] += 2
  num_fourier = 0
  for i = 0, 29 do begin
    where_fourier = where((*self.eventlist).detector_events.detector_index eq fourier_dets[i], num_fourier_i)
    num_fourier += num_fourier_i
  endfor
  
  ;check if total(out.accumulated_counts) eq num_fourier
  mess = ''
  if total(out.accumulated_counts ne num_fourier) then mess = $
    strjoin(['Total counts test: number of events in non-Fourier detectors: ', strcompress(num_fourier), ', number of accumulated events: ', strcompress(total(out.accumulated_counts))])
  assert_true, total(out.accumulated_counts) eq num_fourier, mess
  
end

;+
; :description:
;   Check that the energy distribution of counts in the lightcurve product is equal to that of
;   the input event list
;-
pro stx_fsw_quicklook_lightcurve__test::test_energy_distribution
  
  out = stx_fsw_eventlist_accumulator(*self.eventlist, interval_start_time=self.interval_start_time, _extra=*self.quicklook_config, active_detectors=self.active_detectors)
  
  ;take into account only events detected by fourier detectors
  fourier_dets = indgen(30)+1
  fourier_dets[8:-1] += 2
  energy_values = []
  for i = 0, 29 do begin
    valid_events = ((*self.eventlist).detector_events.energy_science_channel)[where((*self.eventlist).detector_events.detector_index eq fourier_dets[i])]
    energy_values = [energy_values, valid_events]
  endfor
  
  ;rebin the energy values to those of the lightcurve QL product
  edges = out.energy_axis.edges_1
  rebinned_spectrum = ulonarr(n_elements(out.accumulated_counts))
  for j = 0, n_elements(out.accumulated_counts)-1 do begin
    bin_total = energy_values[where(energy_values ge out.energy_axis.low_fsw_idx[j])]
    if (where(bin_total le out.energy_axis.high_fsw_idx[j]))[0] eq -1 then continue
    bin_total = bin_total[where(bin_total le out.energy_axis.high_fsw_idx[j])]
    rebinned_spectrum[j] = n_elements(bin_total)
  endfor
  
  mess = ''
  if ~array_equal(rebinned_spectrum, out.accumulated_counts) then mess = strjoin(['Energy distribution test: (Rebinned input spectrum) - (QL product spectrum) = ', strcompress(rebinned_spectrum - out.accumulated_counts)])
  assert_true, array_equal(rebinned_spectrum, out.accumulated_counts), mess
  
end

;+
; Define instance variables.
;-
pro stx_fsw_quicklook_lightcurve__test__define
  compile_opt idl2, hidden

  define = {stx_fsw_quicklook_lightcurve__test,$
    eventlist:ptr_new(),$
    triggerlist:ptr_new(),$
    interval_start_time:stx_time(),$
    active_detectors:bytarr(32),$
    quicklook_config:ptr_new(),$
    inherits iut_test}
end