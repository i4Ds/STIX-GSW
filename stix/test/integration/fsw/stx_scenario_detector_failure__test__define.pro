;+
; :file_comments:
;   This is a test class for scenario-based testing; specifically the detector failure test
;
; :categories:
;   data simulation, flight software simulator, software, testing
;
; :examples:
;   iut_test_runner('stx_scenario_detector_failure__test', keep_detector_eventlist=0b, show_fsw_plots=0b)
;   iut_test_runner('stx_scenario_detector_failure__test')
;
; :history:
;   05-Feb-2015 - Laszlo I. Etesi (FHNW), initial release
;   02-Mar-2015 - Aidan O'Flannagain (TCD), added first simple test case of alternating detectors
;   04-Mar-2015 - Aidan O'Flannagain (TCD), added tests listed below:
;                                           test_uniform_flux_4_reaction
;                                           test_uniform_flux_5_reaction
;                                           test_uniform_flux_6_reaction
;                                           test_uniform_flux_4_remainoff
;                                           test_uniform_flux_5_remainoff
;                                           test_uniform_flux_6_remainoff
;                                           test_oscillating_flux_40_reaction
;                                           test_oscillating_flux_80_reaction
;                                           test_oscillating_flux_40_remainoff
;                                           test_oscillating_flux_80_remainoff
;                                           test_co_oscillating_flux_40_sourcea_reaction
;                                           test_co_oscillating_flux_40_sourceb_reaction
;                                           test_co_oscillating_flux_40_sourcea_remainoff
;                                           test_co_oscillating_flux_40_sourceb_remainoff
;                                           test_co_oscillating_flux_80_sourcea_reaction
;                                           test_co_oscillating_flux_80_sourceb_reaction
;                                           test_co_oscillating_flux_80_sourcea_remainoff
;                                           test_co_oscillating_flux_80_sourceb_remainoff
;   06-Aug-2015 - Aidan O'Flannagain (TCD)
;     - remain_off: small bugfix. Now correctly handles situations when there are multiple noisy intervals
;     but one flagged interval
;     - test_uniform_flux_4_reaction: removed due to 4x and 5x mean flux both being below the default
;     requirement for a detector to be flagged.
;     - test_uniform_flux_5_reaction: removed
;     - test_uniform_flux_4_remainoff: removed
;     - test_uniform_flux_5_remainoff: removed
;   11-Aug-2015 -Aidan O'Flannagain (TCD)
;     - reaction_time: same bugfix as remain_off.
;   10-may-2016 - Laszlo I. Etesi (FHNW), minor updates to accomodate structure changes
;   28-sep-2016 - ECMD (Graz), minor bugfixes to restore previous functionality 
;-

;+
; :description:
;    this function initializes this module; make sure to adjust the variables "self.test_name" and "self.test_type";
;    they will control, where in $STX_SCN_TEST to look for this test's scenario and configuration files
;    (e.g. $STX_SCN_TEST/basic/calib_spec_acc)
;
; :keywords:
;   extra : in, optional
;     extra parameters interpreted by the base class (see stx_scenario_test__define)
;
; :returns:
;   this function returns true or false, depending on the success of initializing this object
;-
function stx_scenario_detector_failure__test::init, _extra=extra
  self.test_name = 'detector_failure'
  self.test_type = 'basic'
  
  return, self->stx_scenario_test::init(_extra=extra)
end

;+
; :description:
;   this function will return the amount of time (in miliseconds) between the step-function increase in background
;   noise levels and the switching of the detector state from active to yellow-flagged (if there is
;   a switch in detector state).
; :keywords:
;   detnum - the index of the detector being inspector [0-31]
;-

function stx_scenario_detector_failure__test::reaction_time, detnum

  ;extract quicklook spectrum to identify noisy intervals
  self.fsw->getproperty, stx_fsw_ql_spectra=ql_spectrum, /combine, /complete
  time_ql = ql_spectrum.time_axis.time_start.value.time
  detector_flux = total(ql_spectrum.accumulated_counts,1)
  detector_flux = total(detector_flux[detnum, *],1)
  
  ;extract active detector structure for checking when detectors are switched off
  self.fsw->getproperty, stx_fsw_m_detector_monitor=detector_monitor, /complete, /combine
  time_ad = detector_monitor.time_axis.time_start.value.time
  detmask = detector_monitor.active_detectors
  noise   = detector_monitor.noisy_detectors
  detmask = reform(detmask[detnum, *]) + 10.*reform(1-noise[detnum, *])
  detmask = detmask[1:*] ; remove first entry (additional T0)
  
  not_on = where(detmask ne 1)
  ;if there are no changes from a state of 1, return an error message
  if not_on[0] eq -1 then return, "Detector was never switched from on state."
  ;if there are multiple switches from the on state, determine the indexes at which each occur
  not_on_starts = not_on[(where(not_on - shift(not_on, 1) ne 1)) mod n_elements(not_on)]
  
  ;calculate each time when the noise begins (currently assumes a step function in the scenario file)
  noise_intervals = where(detector_flux gt 250.)
  noise_starts = noise_intervals[(where(noise_intervals - shift(noise_intervals, 1) ne 1)) mod n_elements(noise_intervals)]
  time_noisebegin = time_ql[noise_starts]
  
  ;calculate the time when the detectors switch from eq 1 to ne 1 (expected to be yellow-flag state)
  time_switchoff = time_ad[not_on_starts]
  
  ;check if there are the same number of noise state starts and switches to off state
  if n_elements(noise_starts) eq n_elements(not_on_starts) then begin
    return, time_switchoff - time_noisebegin  ;returns an array of times between start of noise interval and switchoff [ms]
  ;if there are more switches from the on state than there are noise intervals, return an error message
  endif else if n_elements(noise_starts) lt n_elements(not_on_starts) then begin
    return, "Detector changed state "+strcompress(n_elements(not_on_starts))+" times for "+$
      strcompress(n_elements(noise_starts))+" noise interval(s)."
  ;if there were more noise intervals than not_on intervals, check if this is because the detector remained off
  ;for the full remainder of the scenario. If so, return the array of time differences up to the point the detector
  ;is switched off. Otherwise, return an error message.
  endif else begin
    remain_off_check = where(detmask[not_on_starts[-1]:-1] eq 1, num)
    if num eq 0 then begin
      return, time_switchoff - time_noisebegin[0:n_elements(not_on_starts)]
    endif else return, "Detector changed state "+strcompress(n_elements(not_on_starts))+" times for "+$
      strcompress(n_elements(noise_starts))+" noise interval(s)."
  endelse
  
end

;+
; :description:
;   This function will return a number of 1 or 0. 1 if the given detector remains in the yellow or off
;   state for the duration of the noise interval, and 0 if it does not.
; :keywords:
;   detnum - the index of the detector being inspector [0-31]
;-

function stx_scenario_detector_failure__test::remain_off, detnum

  ;extract quicklook spectrum to identify noisy intervals
  self.fsw->getproperty, stx_fsw_ql_spectra=ql_spectrum, /combine, /complete
  time_ql = ql_spectrum.time_axis.time_start.value.time
  detector_flux = total(ql_spectrum.accumulated_counts,1)
  detector_flux = total(detector_flux[detnum, *],1)
  
  ;extract active detector structure for checking when detectors are switched off
  self.fsw->getproperty, stx_fsw_m_detector_monitor=detector_monitor, /complete, /combine
  time_ad = detector_monitor.time_axis.time_start.value.time
  detmask = detector_monitor.active_detectors
  noise   = detector_monitor.noisy_detectors
  detmask = reform(detmask[detnum, *]) + 10.*reform(1-noise[detnum, *])
  detmask = detmask[1:*]
  
  not_on = where(detmask ne 1 and detmask ne 11)
  ;if there are no changes from a state of 1, return an error message
  if not_on[0] eq -1 then return, "Detector was never switched from on state."
  
  ;determine the indexes at which the detectors are switched to the on state
  not_on_ends = not_on[(where((shift(not_on, -1) - not_on) ne 1))]
  time_not_on_ends = time_ad[not_on_ends]
  
  ;calculate each time when the noise begins (currently assumes a step function in the scenario file)
  noise_intervals = where(detector_flux gt 250.)
  noise_ends = (where((shift(noise_intervals,-1) - noise_intervals) ne 1))
  time_noise_ends = time_ql[noise_ends]
  
  ;these checks are all already done in the reaction_time function, so may benefit from being linked somehow
  ;check if there are the same number of noise state starts and switches to off state
  if n_elements(noise_ends) eq n_elements(not_on_ends) then begin
    ;return the time between end of noise interval and the end of the detector not-on interval [ms]
    return, time_not_on_ends - time_noise_ends
  ;if there are more switches from the on state than there are noise intervals, return an error message
  endif else if n_elements(noise_ends) lt n_elements(not_on_ends) then begin
    return, "Detector changed state "+strcompress(n_elements(not_on_ends))+" times for "+$
      strcompress(n_elements(noise_ends))+" noise interval(s)."
  ;if there were more noise intervals than not_on intervals, check if this is because the detector remained off
  ;for the full remainder of the scenario. If so, return the array of time differences up to the point the detector
  ;is switched off. Otherwise, return an error message.
  endif else begin
    remain_off_check = where(detmask[not_on_ends[-1]:-1] eq 1, num)
    if num eq 0 then begin
      return, time_not_on_ends - time_noise_ends[0:n_elements(not_on_ends)]
    endif else return, "Detector changed state "+strcompress(n_elements(not_on_ends))+" times for "+$
      strcompress(n_elements(noise_ends))+" noise interval(s)."
  endelse
end

;+
; :description:
;   This procedure will check if an interval with background level of 6 times the standard value causes
;   the detector failure identification module to switch the detector off in time. Currently, a delay in
;   response of eight seconds is allowed for the test to pass.
;
;   The scenario file is expected to include this level of flux in detector 1c, corresponding to detnum of 17.
;-

pro stx_scenario_detector_failure__test::test_uniform_flux_6_reaction

  delay_time = self.reaction_time(17)
  
  if (isa(delay_time, 'string')) then assert_true, 0, delay_time $
  else begin
  mess = ["Detector state was changed " , strcompress(-delay_time,/remove_all) ,$
    " ms after noise began."]
  mess = string(mess, /print)
  if n_elements(delay_time) eq 1 then assert_true, delay_time le 8000, mess $
  else assert_true, where((delay_time le 8000) ne 1) eq [-1], mess
endelse
end

;+
; :description:
;   This procedure will check if an interval with background level of 6 times the standard value incorrectly
;   causes the detector to return to the on state while the noise interval is still happening. If the value of
;   (time the detector turns back on - time the noise interval ends) is negative, the test is failed.
;
;   The scenario file is expected to include this level of flux in detector 1a, corresponding to detnum of 17.
;-

pro stx_scenario_detector_failure__test::test_uniform_flux_6_remainoff

  delay_time = self.remain_off(17)
  if (isa(delay_time, 'string')) then assert_true, 0, delay_time $
  else begin
  mess = ["Detector was turned on " , strcompress(-delay_time,/remove_all) ,$
    " ms before noise ended."]
  mess = string(mess, /print)
  if n_elements(delay_time) eq 1 then assert_true, delay_time ge -4000, mess $
  else assert_true, where((delay_time ge -4000) ne 1) eq [-1], mess
endelse
end

;+
; :description:
;   This procedure will check if a noise interval which oscillates between a background value of 1 and 6
;   times the standard level every 40 seconds causes the detector failure identification module to switch
;   the detector off in time.
;
;   The scenario file is expected to include this level of flux in detector 2a, corresponding to detnum of 11.
;-

pro stx_scenario_detector_failure__test::test_oscillating_flux_40_reaction

  delay_time = self.reaction_time(11)
  
  if (isa(delay_time, 'string')) then assert_true, 0, delay_time $
  else begin
  mess = ["Detector state was changed " , strcompress(-delay_time,/remove_all) ,$
    " ms after noise began."]
  mess = string(mess, /print)
  if n_elements(delay_time) eq 1 then assert_true, delay_time le 8000, mess $
  else assert_true, where((delay_time le 8000) ne 1) eq [-1], mess
endelse
end

;+
; :description:
;   This procedure will check if a noise interval which oscillates between a background value of 1 and 6
;   times the standard level every 40 seconds causes the detector to be switched on at any point during
;   a noise interval.
;
;   The scenario file is expected to include this level of flux in detector 2a, corresponding to detnum of 11.
;-

pro stx_scenario_detector_failure__test::test_oscillating_flux_40_remainoff

  delay_time = self.remain_off(11)
  if (isa(delay_time, 'string')) then assert_true, 0, delay_time $
  else begin
  mess = ["Detector was turned on " , strcompress(-delay_time,/remove_all) ,$
    " ms before noise ended."]
  mess = string(mess, /print)
  if n_elements(delay_time) eq 1 then assert_true, delay_time ge -4000, mess $
  else assert_true, where((delay_time ge -4000) ne 1) eq [-1], mess
endelse
end

;+
; :description:
;   This procedure will check if a noise interval which oscillates between a background value of 1 and 6
;   times the standard level every 80 seconds causes the detector failure identification module to switch
;   the detector off in time.
;
;   The scenario file is expected to include this level of flux in detector 2b, corresponding to detnum of 18.
;-

pro stx_scenario_detector_failure__test::test_oscillating_flux_80_reaction

  delay_time = self.reaction_time(18)
  
  if (isa(delay_time, 'string')) then assert_true, 0, delay_time $
  else begin
  mess = ["Detector state was changed " , strcompress(-delay_time,/remove_all) ,$
    " ms after noise began."]
  mess = string(mess, /print)
  if n_elements(delay_time) eq 1 then assert_true, delay_time le 8000, mess $
  else assert_true, where((delay_time le 8000) ne 1) eq [-1], mess
endelse
end

;+
; :description:
;   This procedure will check if a noise interval which oscillates between a background value of 1 and 6
;   times the standard level every 80 seconds causes the detector to be switched on at any point during
;   a noise interval.
;
;   The scenario file is expected to include this level of flux in detector 2b, corresponding to detnum of 18.
;-

pro stx_scenario_detector_failure__test::test_oscillating_flux_80_remainoff

  delay_time = self.remain_off(18)
  if (isa(delay_time, 'string')) then assert_true, 0, delay_time $
  else begin
  mess = ["Detector was turned on " , strcompress(-delay_time,/remove_all) ,$
    " ms before noise ended."]
  mess = string(mess, /print)
  if n_elements(delay_time) eq 1 then assert_true, delay_time ge -4000, mess $
  else assert_true, where((delay_time ge -4000) ne 1) eq [-1], mess
endelse
end

;+
; :description:
;
;   This pair of procedures will test two sources which oscillate completely out of phase between a value
;   of 1 and 6 every 40 seconds. It will be determined if the detector failure module successfully switches
;   the detectors to the yellow-flagged or off state <8000 ms following each noise interval.
;
;   The scenario file is expected to include this level of flux in detectors 2c and 3a, corresponding to
;   detnums of 6 and 16, respectively.
;-

pro stx_scenario_detector_failure__test::test_co_oscillating_flux_40_sourcea_reaction

  delay_time = self.reaction_time(6)
  
  if (isa(delay_time, 'string')) then assert_true, 0, delay_time $
  else begin
  mess = ["Detector state was changed " , strcompress(-delay_time,/remove_all) ,$
    " ms after noise began."]
  mess = string(mess, /print)
  if n_elements(delay_time) eq 1 then assert_true, delay_time le 8000, mess $
  else assert_true, where((delay_time le 8000) ne 1) eq [-1], mess
endelse
end

pro stx_scenario_detector_failure__test::test_co_oscillating_flux_40_sourceb_reaction

  delay_time = self.reaction_time(16)
  
  if (isa(delay_time, 'string')) then assert_true, 0, delay_time $
  else begin
  mess = ["Detector state was changed " , strcompress(-delay_time,/remove_all) ,$
    " ms after noise began."]
  mess = string(mess, /print)
  if n_elements(delay_time) eq 1 then assert_true, delay_time le 8000, mess $
  else assert_true, where((delay_time le 8000) ne 1) eq [-1], mess
endelse
end

;+
; :description:
;
;   This pair of procedures will test two sources which oscillate completely out of phase between a value
;   of 1 and 6 every 40 seconds. It will be determined if the detector failure module erroniously switches
;   the detector back on during a noisy interval. If it does so, the test is failed.
;
;   The scenario file is expected to include this level of flux in detectors 2c and 3a, corresponding to
;   detnums of 6 and 16, respectively.
;-

pro stx_scenario_detector_failure__test::test_co_oscillating_flux_40_sourcea_remainoff

  delay_time = self.remain_off(6)
  
  if (isa(delay_time, 'string')) then assert_true, 0, delay_time $
  else begin
  mess = ["Detector state was changed " , strcompress(-delay_time,/remove_all) ,$
    " ms after noise began."]
  mess = string(mess, /print)
  if n_elements(delay_time) eq 1 then assert_true, delay_time ge -4000, mess $
  else assert_true, where((delay_time ge -4000) ne 1) eq [-1], mess
endelse
end

pro stx_scenario_detector_failure__test::test_co_oscillating_flux_40_sourceb_remainoff

  delay_time = self.remain_off(16)
  
  if (isa(delay_time, 'string')) then assert_true, 0, delay_time $
  else begin
  mess = ["Detector state was changed " , strcompress(-delay_time,/remove_all) ,$
    " ms after noise began."]
  mess = string(mess, /print)
  if n_elements(delay_time) eq 1 then assert_true, delay_time ge -4000, mess $
  else assert_true, where((delay_time ge -4000) ne 1) eq [-1], mess
endelse
end

;+
; :description:
;
;   This pair of procedures will test two sources which oscillate completely out of phase between a value
;   of 1 and 6 every 80 seconds. It will be determined if the detector failure module successfully switches
;   the detectors to the yellow-flagged or off state <8000 ms following each noise interval.
;
;   The scenario file is expected to include this level of flux in detectors 3b and 3c, corresponding to
;   detnums of 28 and 0, respectively.
;-

pro stx_scenario_detector_failure__test::test_co_oscillating_flux_80_sourcea_reaction

  delay_time = self.reaction_time(28)
  
  if (isa(delay_time, 'string')) then assert_true, 0, delay_time $
  else begin
  mess = ["Detector state was changed " , strcompress(-delay_time,/remove_all) ,$
    " ms after noise began."]
  mess = string(mess, /print)
  if n_elements(delay_time) eq 1 then assert_true, delay_time le 8000, mess $
  else assert_true, where((delay_time le 8000) ne 1) eq [-1], mess
endelse
end

pro stx_scenario_detector_failure__test::test_co_oscillating_flux_80_sourceb_reaction

  delay_time = self.reaction_time(0)
  
  if (isa(delay_time, 'string')) then assert_true, 0, delay_time $
  else begin
  mess = ["Detector state was changed " , strcompress(-delay_time,/remove_all) ,$
    " ms after noise began."]
  mess = string(mess, /print)
  if n_elements(delay_time) eq 1 then assert_true, delay_time le 8000, mess $
  else assert_true, where((delay_time le 8000) ne 1) eq [-1], mess
endelse
end

;+
; :description:
;
;   This pair of procedures will test two sources which oscillate completely out of phase between a value
;   of 1 and 6 every 80 seconds. It will be determined if the detector failure module erroniously switches
;   the detector back on during a noisy interval. If it does so, the test is failed.
;
;   The scenario file is expected to include this level of flux in detectors 3b and 3c, corresponding to
;   detnums of 28 and 0, respectively.
;-

pro stx_scenario_detector_failure__test::test_co_oscillating_flux_80_sourcea_remainoff

  delay_time = self.remain_off(28)
  
  if (isa(delay_time, 'string')) then assert_true, 0, delay_time $
  else begin
  mess = ["Detector state was changed " , strcompress(-delay_time,/remove_all) ,$
    " ms after noise began."]
  mess = string(mess, /print)
  if n_elements(delay_time) eq 1 then assert_true, delay_time ge -4000, mess $
  else assert_true, where((delay_time ge -4000) ne 1) eq [-1], mess
endelse
end

pro stx_scenario_detector_failure__test::test_co_oscillating_flux_80_sourceb_remainoff

  delay_time = self.remain_off(0)
  
  if (isa(delay_time, 'string')) then assert_true, 0, delay_time $
  else begin
  mess = ["Detector state was changed " , strcompress(-delay_time,/remove_all) ,$
    " ms after noise began."]
  mess = string(mess, /print)
  if n_elements(delay_time) eq 1 then assert_true, delay_time ge -4000, mess $
  else assert_true, where((delay_time ge -4000) ne 1) eq [-1], mess
endelse
end

;pro stx_scenario_detector_failure__test::beforeclass
;  self->_setup_test
;
;  self->_setup_test_environment
;
;  restore, filename=filepath("fsw.sav",root_dir=self.test_output_dir), /ver
;  self.fsw = fsw
;end

pro stx_scenario_detector_failure__test__define
  compile_opt idl2, hidden
  
  void = { $
    stx_scenario_detector_failure__test, $
    inherits stx_scenario_test }
end
