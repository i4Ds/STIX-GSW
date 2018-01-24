;+
; :description:
;   This function constructs a stix calibration spectra for use in the flight software simulation.
;
; :categories:
;    flight software, constructor, simulation
;
; :keywords:
;    accumulated_counts : in, optional, type='intarr(32,12,1024)'
;        this is the calibration spectrum
;        
;    live_time : in, optional, type='float'
;        the live time data
;                 
; :returns:
;    a stx_sim_archive_buffer structure
;
; :examples:
;    ab = stx_construct_sim_calibration_spectrum(...)
;
; :history:
;     25-feb-2014, Laszlo I. Etesi (FHNW), initial release
;     10-may-2016, Laszlo I. Etesi (FHNW), minor updates to accomodate structure changes
;
;-
function stx_construct_sim_calibration_spectrum, accumulated_counts=accumulated_counts, live_time=live_time
  calibration_spectrum = stx_fsw_m_calibration_spectrum()
  
  if(keyword_set(accumulated_counts)) then calibration_spectrum.accumulated_counts = accumulated_counts
  if(keyword_set(live_time)) then calibration_spectrum.live_time = live_time
  
  return, calibration_spectrum
end