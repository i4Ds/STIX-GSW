;+
; :file_comments:
;   Test routine for the FSW module routine for the accumulation of the calibration spectrum
;
; :categories:
;   Flight Software Simulator, archive buffer, testing
;
; :examples:
;   res = iut_test_runner('stx_sim_archive_buffer__test')
;
; :history:
;   11-may-2015 - ECMD (Graz), initial release
;   11-aug-2015 - ECMD (Graz), fixed excluded detectors in mask test
;                              using full range of detector indices
;   25-sep-2015 - ECMD (Graz), changed to reflect changes to archive buffer routine
;                              added test_energy_mask
;                              added test_below_min
;                              removed test_saturation                            
;   12-jul-2016 - Laszlo I. Etesi (FHNW), - using the new archive buffer routine by RAS
;-

;+
; :description:
;   Setup of this test. The testing is done with a predefined eventlist. The eventlist consists of 40 entries
;
;
;   The a/d channels, pixels indices, and detector indices are all assigned the same value which was chosen at random.
;-
pro stx_sim_archive_buffer__test::beforeclass
  default, t_max, 100.   ; maximum duration of accumulation, units ms
  
  default, t_min, 50.   ; minimum duration of accumulation, units ms
  
  default, m_acc,  bytarr(32)+1b
  
  ; construct event times
  relative_times = [ 0 , 0.95*t_min , t_min,$
    (t_max + t_min)/2., (t_max + t_min)/2., $
    t_max , 1.02*t_max, 2.*t_max + indgen(32) + 1 ,10.*t_max]
    
    
  t_max_hms = t_max/100.
  t_min_s =  t_min/1000.
  
  no_events = n_elements(relative_times)
  
  events = replicate(stx_sim_calibrated_detector_event(), no_events)
  
  events.relative_time = relative_times/1000.d
  
  events.detector_index = 23
  events.pixel_index = 10
  events.energy_science_channel = 3
  
  self.eventlist = ptr_new(stx_construct_sim_calibrated_detector_eventlist(start_time=0, detector_events=events, sources=stx_sim_source_structure()))
  self.t_max = t_max_hms
  self.t_min = t_min_s
  self.m_acc = m_acc
  
end


;+
; cleanup at object destroy
;-
pro stx_sim_archive_buffer__test::afterclass


end

;+
; cleanup after each test case
;-
pro stx_sim_archive_buffer__test::after


end

;+
; init before each test case
;-
pro stx_sim_archive_buffer__test::before


end


;+
; :description:
;
;The full initial eventlist is used.  The expected number of entries in the archive buffer is compared with
;the values found when the eventlist is passed to the routine stx_fsw_evl2archive.pro both with and
;without the close_last_bin keyword
;
;-
pro stx_sim_archive_buffer__test::test_number_entries

  test_eventlist = stx_construct_sim_calibrated_detector_eventlist(start_time=0, detector_events=(*self.eventlist).detector_events, $
    sources=(*self.eventlist).sources)
    
  archive_buffer = stx_fsw_evl2archive(test_eventlist, 0, nxeo, t_max = self.t_max, t_min = self.t_min)
  
  ;4 archive buffer entries should exist if it is not closed
  assert_equals, 4, n_elements(archive_buffer)
  
end



;+
; :description:
;
;The full initial eventlist is used.  The expected total counts in the archive buffer is compared with
;the values found when the eventlist is passed to the routine stx_fsw_evl2archive.pro
;
;-
pro stx_sim_archive_buffer__test::test_total_counts


  test_eventlist = stx_construct_sim_calibrated_detector_eventlist(start_time=0, detector_events=(*self.eventlist).detector_events, $
    sources=(*self.eventlist).sources)
    
  archive_buffer = stx_fsw_evl2archive(test_eventlist, 0, nxeo, t_max = self.t_max, t_min = self.t_min)
  
  ;the total count should be equal to the number off all events
  assert_equals, 39, total(archive_buffer.counts)
end

;+
; :description:
;
;The full initial eventlist is used  test_number_entries and  test_total_counts are rerun  with the close_last_bin keyword
;
;-
pro stx_sim_archive_buffer__test::test_close_last_bin


  test_eventlist = stx_construct_sim_calibrated_detector_eventlist(start_time=0, detector_events=(*self.eventlist).detector_events, $
    sources=(*self.eventlist).sources)
    
  archive_buffer = stx_fsw_evl2archive(test_eventlist, 0, nxeo, t_max = self.t_max, t_min = self.t_min,/close)
  
  ;the total count should be equal to the number off all events
  assert_equals, 40, total(archive_buffer.counts)
  
  
  ;5 archive buffer entries should exist
  assert_equals, 5, n_elements(archive_buffer)
end

;+
; :description:
;
;
;
;-
pro stx_sim_archive_buffer__test::test_max_duration
  detector_events = (*self.eventlist).detector_events
  
  tmax = self.t_max
  t_max = tmax*100.
  
  ; expected that with the last bin LT t_max the maximum buffer time will be t_max
  ; above this they should fall into a new time bin
  expected_ends =  round([t_max, 2.*t_max, 2.*t_max, 3.*t_max])
  expected_entries = [1,2,2,2]
  
  
  for i = 0, 3  do begin
  
    use_indices = [0, i+4, 39]
    
    test_eventlist = stx_construct_sim_calibrated_detector_eventlist(start_time=0, detector_events=detector_events[use_indices], $
                     sources=stx_sim_source_structure())
      
    archive_buffer = stx_fsw_evl2archive(test_eventlist, 0, nxec, t_max = tmax, t_min = self.t_min, n_min = 10)
    print, detector_events[use_indices[1]].relative_time
    
    assert_equals,  expected_entries[i], n_elements(archive_buffer)
    assert_equals,  expected_ends[i], max(round(archive_buffer.relative_time_range[1]*1000.d))
    
  endfor
end

;+
; :description:
;
;
;
;-
pro stx_sim_archive_buffer__test::test_below_min
  detector_events = (*self.eventlist).detector_events
  
  use_indices = [0,1]
  
  test_eventlist = stx_construct_sim_calibrated_detector_eventlist(start_time=0, detector_events=detector_events[use_indices], $
                                                                   sources=(*self.eventlist).sources)
    
  archive_buffer_closed = stx_fsw_evl2archive(test_eventlist, 0, nxec, t_max = self.t_max, t_min = self.t_min, /close)
  
  archive_buffer_open = stx_fsw_evl2archive(test_eventlist, 0, nxec, t_max = self.t_max, t_min = self.t_min)
  
  assert_equals, 1, n_elements(archive_buffer_closed)
  assert_equals, 0, n_elements(archive_buffer_open)
  
  
  
end

;+
; :description:
;
;
;
;-
pro stx_sim_archive_buffer__test::test_min_duration
  detector_events = (*self.eventlist).detector_events
  
  tmax = self.t_max
  t_max = tmax*100.
  
  tmin = self.t_min
  t_min = tmin*1000.
  
  
  expected_ends =  round([t_min, t_max + t_min,  t_max + t_min ])
  expected_entries = [1,2,2]
  
  for i = 0, 2 do begin
  
    use_indices = [0,i+1,39]
    
    test_eventlist = stx_construct_sim_calibrated_detector_eventlist(start_time=0, detector_events=detector_events[use_indices], $
      sources=(*self.eventlist).sources)
      
      
    archive_buffer = stx_fsw_evl2archive(test_eventlist, 0, nxec, t_max = self.t_max, t_min = self.t_min)
    
    assert_equals, expected_entries[i], n_elements(archive_buffer)
    
    assert_equals, expected_ends[i],  max(round(archive_buffer.relative_time_range[1]*1000.d))
    
    
    
    
  endfor
end

;+
; :description:
;
;The final 32 entries in the initial eventlist are used. They are given randomly selected detector numbers and a detector mask
;The close_last_bin keyword is used to ensure the output distribution of energy channels matches the input
;
;-
pro stx_sim_archive_buffer__test::test_energy_mask
  detector_events = (*self.eventlist).detector_events
  
  change_energy_indices = indgen(3)
  det_indices =  detector_events.energy_science_channel
  det_indices[change_energy_indices] = 1
  detector_events.energy_science_channel = det_indices
  
  test_eventlist = stx_construct_sim_calibrated_detector_eventlist(start_time = 0, detector_events = detector_events, $
    sources=(*self.eventlist).sources)
    
  m_channel = bytarr(32)+1B
  m_channel[1] = 0B
  
  archive_buffer = stx_fsw_evl2archive(test_eventlist, 0, nxec, t_max = self.t_max, t_min = self.t_min, m_channel = m_channel, /close)
  
  assert_equals, 100, round((archive_buffer.relative_time_range)[1]*1000.d)
  
end

;+
; :description:
;
;The final 32 entries in the initial eventlist are used. They are given randomly selected detector numbers and a detector mask
;The close_last_bin keyword is used to ensure the output distribution of energy channels matches the input
;
;-
pro stx_sim_archive_buffer__test::test_det_mask
  use_indices = findgen(32)+7
  detector_events = (*self.eventlist).detector_events[use_indices]
  
  m_acc_ind = indgen(16)*2
  m_acc = bytarr(32)
  m_acc[m_acc_ind] = 1B
  m_ex  = where(m_acc ne 1)
  detector_indices = fix(randomu(seed, n_elements(use_indices)) * 32 + 1)
  detector_events.detector_index = detector_indices
  
  detector_histogram = histogram(detector_indices, min = 1, max = 32, bin = 1)
  detector_histogram[m_ex] = 0
  
  non_zero = where(detector_histogram ne 0, non_zero_count)
  if non_zero_count ne 0 then detector_histogram = detector_histogram[non_zero]
  
  test_eventlist = stx_construct_sim_calibrated_detector_eventlist(start_time = 0, detector_events = detector_events, $
    sources=(*self.eventlist).sources)
    
    
  archive_buffer = stx_fsw_evl2archive(test_eventlist, 0, nxec, t_max = self.t_max, t_min = self.t_min, m_acc = m_acc, /close)
  
  ;the counts should be equal to the distribution of non-masked detector numbers
  assert_equals, archive_buffer.counts, detector_histogram
  
end


;+
; :description:
;
;The final 32 entries in the initial eventlist are used. They are given randomly selected pixel numbers.
; The close_last_bin keyword is used to ensure the output distribution of pixel numbers matches the input.
;
;-
pro stx_sim_archive_buffer__test::test_correct_pixel_numbers
  use_indices = findgen(32)+7
  detector_events = (*self.eventlist).detector_events[use_indices]
  
  pixel_indices = fix(randomu(seed, n_elements(use_indices)) * 12)
  detector_events.pixel_index = pixel_indices
  
  pixel_histogram = histogram(pixel_indices, min = 0, max = 12)
  non_zero = where(pixel_histogram ne 0, non_zero_count)
  if non_zero_count ne 0 then pixel_histogram = pixel_histogram[non_zero]
  
  test_eventlist = stx_construct_sim_calibrated_detector_eventlist(start_time = 0, detector_events = detector_events, sources=(*self.eventlist).sources)
  
  
  archive_buffer = stx_fsw_evl2archive(test_eventlist, 0, nxec, t_max = self.t_max, t_min = self.t_min, /close)
  
  ;the counts should be equal to the distribution of pixel numbers
  assert_equals, archive_buffer.counts, pixel_histogram
end


;+
; :description:
;
;The final 32 entries in the initial eventlist are used. They are given randomly selected detector numbers
;The close_last_bin keyword is used to ensure the output distribution of detector numbers matches the input
;
;-
pro stx_sim_archive_buffer__test::test_correct_detector_numbers
  use_indices = findgen(32)+7
  detector_events = (*self.eventlist).detector_events[use_indices]
  
  detector_indices = fix(randomu(seed, n_elements(use_indices)) * 32 + 1)
  detector_events.detector_index = detector_indices
  
  detector_histogram = histogram(detector_indices, min = 1, max = 32 )
  non_zero = where(detector_histogram ne 0, non_zero_count)
  if non_zero_count ne 0 then detector_histogram = detector_histogram[non_zero]
  
  test_eventlist = stx_construct_sim_calibrated_detector_eventlist(start_time = 0, detector_events = detector_events, $
    sources=(*self.eventlist).sources)
    
    
  archive_buffer = stx_fsw_evl2archive(test_eventlist, 0, nxec, t_max = self.t_max, t_min = self.t_min, /close)
  
  ;the counts should be equal to the distribution of detector numbers
  assert_equals, detector_histogram, archive_buffer.counts
end

;+
; :description:
;
;The final 32 entries in the initial eventlist are used. They are given randomly selected energy science channels.
;The close_last_bin keyword is used to ensure the output distribution of energy channels matches the input
;
;-
pro stx_sim_archive_buffer__test::test_correct_energy_channels
  use_indices = findgen(32)+7
  detector_events = (*self.eventlist).detector_events[use_indices]
  
  energy_channel_indices = fix(randomu(seed, n_elements(use_indices)) * 32)
  detector_events.energy_science_channel = energy_channel_indices
  
  energy_channel_histogram = histogram(energy_channel_indices, min = 0, max = 31)
  non_zero = where(energy_channel_histogram ne 0, non_zero_count)
  if non_zero_count ne 0 then energy_channel_histogram = energy_channel_histogram[non_zero]
  
  test_eventlist = stx_construct_sim_calibrated_detector_eventlist(start_time = 0, detector_events = detector_events, $
    sources=(*self.eventlist).sources)
    
  archive_buffer = stx_fsw_evl2archive(test_eventlist, 0, nxec, t_max = self.t_max, t_min = self.t_min, /close)
  
  ;the counts should be equal to the distribution of energy channels
  assert_equals, energy_channel_histogram, archive_buffer.counts
end

;+
; Define instance variables.
;-
pro stx_sim_archive_buffer__test__define
  compile_opt idl2, hidden
  
  define = { stx_sim_archive_buffer__test, $
    eventlist : ptr_new(), $
    tq : 0., $
    t_max : 0., $
    t_min : 0., $
    m_acc :bytarr(32), $
    inherits iut_test }
    
end

