;+
;  :description
;    Unit test for the background determination ["bgd"] module in the flight software simulator.
;
;  :categories:
;    Flight Software Simulator, background determination, testing
;
;  :examples:
;    res = iut_test_runner('stx_fsw_background_determination__test')
;   
;  :history:
;    28-apr-2015 - Aidan O'Flannagain (TCD), initial release
;    18-may-2015 - Aidan O'Flannagain (TCD), converted to IUT test runner format,
;                 changed location to stix/test/fsw/modules
;    17-jul-2015 - Aidan O'Flannagain (TCD), removed long trigger duration and short integration time tests.
;                 Added "disabled" and "flareflag" tests. 
;    30-oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;    01-mar-2016 - Laszlo I. Etesi (FHNW), updated test to work with new background structure
;-
;

pro stx_fsw_background_determination__test::beforeclass

  ;prepare input to detector failure module
  time_bin = [1262304000d, 1262304004d]
  spectrogram = reform( make_array(40, /LONG, value = 0), 5, 8, 1, 1) + rebin(lindgen(5)*10, 5, 8)
  channel_bin_use = [0, 3, 7, 12, 20, 32]
  is_trigger_event = byte(0)
  
  self.ql_bkgd_acc = ptr_new(stx_construct_fsw_ql_accumulator('stx_fsw_ql_bkgd_monitor', time_bin , ulong( spectrogram ), channel_bin_use=channel_bin_use, is_trigger_event = byte(0)))
  self.lt_bkgd_acc = ptr_new(stx_construct_fsw_ql_accumulator('stx_fsw_ql_bkgd_monitor_lt', time_bin , ulonarr(1) + ulong( total(spectrogram)*2. ), channel_bin_use=channel_bin_use, is_trigger_event = byte(1)))
  self.previous_bkgd = fltarr(5) + float(1)
  self.flare_flag = bytarr(1)
  self.int_time = double(32)
  
  self.conf_enable = byte(1)
  self.conf_default_background = fltarr(5) + float(1)
  self.conf_trigger_duration = 10^(-5.d)

end


;+
; cleanup at object destroy
;-
pro stx_fsw_background_determination__test::afterclass


end

;+
; cleanup after each test case
;-
pro stx_fsw_background_determination__test::after


end

;+
; init before each test case
;-
pro stx_fsw_background_determination__test::before


end

;+
; :description:
;   Compare the slope of the output background to that of the input accumulator product
;   Slope should be close within a margin.
;-
pro stx_fsw_background_determination__test::test_energy_distribution
  ;alter energy distribution and remake accumulator products
  altered_spectrum = lindgen(5)*10
  altered_spectrum[2] /=2
  altered_spectrum[-1] = 0.01
  
  time_bin = [1262304000d, 1262304004d]
  spectrogram = reform( make_array(40, /LONG, value = 0), 5, 8, 1, 1) + rebin(altered_spectrum*10, 5, 8)
  channel_bin_use = [0, 3, 7, 12, 20, 32]
  is_trigger_event = byte(0)
  ql_bkgd_acc = stx_construct_fsw_ql_accumulator('stx_fsw_ql_bkgd_monitor', time_bin , ulong( spectrogram ), channel_bin_use=channel_bin_use, is_trigger_event = byte(0))
  lt_bkgd_acc = stx_construct_fsw_ql_accumulator('stx_fsw_ql_bkgd_monitor_lt', time_bin , ulonarr(1) + ulong( total(spectrogram)*2. ), channel_bin_use=channel_bin_use, is_trigger_event = byte(1))
  
  out = stx_fsw_background_determination(ql_bkgd_acc,$
                                                lt_bkgd_acc,$
                                                self.previous_bkgd,$
                                                self.conf_enable,$
                                                self.flare_flag,$
                                                default_background=self.conf_default_background,$
                                                int_time=self.int_time,$
                                                trigger_duration=self.conf_trigger_duration)
  
  ratio = total(ql_bkgd_acc.accumulated_counts,2) / out.background
  std_dev = stddev(ratio[where(finite(ratio) eq 1)])
  mess = ''
  if std_dev gt 2 then mess = strjoin(["Energy distribution test: Standard deviation of in/out retio:" + strcompress(std_dev)])
  assert_true, std_dev lt 2, mess
end

;+
; :description:
;   Set input keyword background_determination_enable to 0, and ensure a pre-defined default background is returned by
;   the module. If not, the test is failed.
;-
pro stx_fsw_background_determination__test::test_disabled
  
  ;alter energy distribution and remake accumulator products
  new_conf_enable = 0
  new_default_background = [4.8, 1.5, 1.6, 2.3, 4.2]
  
  out = stx_fsw_background_determination(*self.ql_bkgd_acc,$
                                                *self.lt_bkgd_acc,$
                                                self.previous_bkgd,$
                                                new_conf_enable,$
                                                self.flare_flag,$
                                                default_background=new_default_background,$
                                                int_time=self.int_time,$
                                                trigger_duration=self.conf_trigger_duration)
  
  pass = where(out eq new_default_background, num_pass)
  mess = ''
  if num_pass ne 5 then mess = "Disabled test: default background not turn when module disabled."
  assert_true, num_pass eq 5, mess
end

;+
; :description:
;   Set input flare_flag to 1, which should cause the module to use the previous background. If it doesn't
;   the test is failed
;-
pro stx_fsw_background_determination__test::test_flareflag
  
  ;alter energy distribution and remake accumulator products
  new_flare_flag = 1
  new_previous_background = [4.8, 1.5, 1.6, 2.3, 4.2]*10.
  
  out = stx_fsw_background_determination(*self.ql_bkgd_acc,$
                                                *self.lt_bkgd_acc,$
                                                new_previous_background,$
                                                self.conf_enable,$
                                                new_flare_flag,$
                                                default_background=self.conf_default_background,$
                                                int_time=self.int_time,$
                                                trigger_duration=self.conf_trigger_duration)
  
  pass = where(out eq new_previous_background, num_pass)
  mess = ''
  if num_pass ne 5 then mess = "Flareflag test: Custom previous background not returned when flare flag on."
  assert_true, num_pass eq 5, mess
end

;+
; Define instance variables.
;-
pro stx_fsw_background_determination__test__define
  compile_opt idl2, hidden

  define = { stx_fsw_background_determination__test, $
    ql_bkgd_acc:ptr_new(),$
    lt_bkgd_acc:ptr_new(),$
    previous_bkgd:fltarr(5),$
    conf_enable:byte(1),$
    flare_flag:bytarr(1),$
    conf_default_background:fltarr(5),$
    int_time:double(32),$
    conf_trigger_duration:double(1e5),$
    inherits iut_test }
end