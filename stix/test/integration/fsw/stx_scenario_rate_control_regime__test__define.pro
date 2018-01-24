;+
; :file_comments:
;   This is a test class for scenario-based testing; specifically the rate control regime test
;
; :categories:
;   data simulation, flight software simulator, software, testing
;
; :examples:
;   iut_test_runner('stx_scenario_rate_control_regime__test', keep_detector_eventlist=0b, show_fsw_plots=0b)
;   iut_test_runner('stx_scenario_rate_control_regime__test')
;
; :history:
;   05-Feb-2015 - Laszlo I. Etesi (FHNW), initial release
;   10-Feb-2016 - ECMD (Graz), minor changes to reflect updated scenario file
;   10-may-2016 - Laszlo I. Etesi (FHNW), minor updates to accomodate structure changes
;   12-Sep-2016 - ECMD (Graz), changes to test_trigger_rate:
;                              removed bkg and cfl counts, 
;                              expected rates now estimated for each adg channel,
;                              expected rcr times fixed,
;                              tolerance increased to avoid failures due to statistics
;   5-Oct-2016 - ECMD (Graz), changes to test_trigger_rate: now looking at bin before expected rate reaches threshold 
;    
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
function stx_scenario_rate_control_regime__test::init, _extra=extra
  self.test_name = 'rate_control_regime'
  self.test_type = 'basic'
  
  return, self->stx_scenario_test::init(_extra=extra)
end

;+
; :description:
;   this test if verifying if the configuration file used is the right one
;-
;pro stx_scenario_rate_control_regime__test::test_configuration_file
 ; print,dss->(module='stx_fsw_module_rate_control_regime',/PARAMETER)
;  assert_true, 1
;end

; This test verify that we reach a sufficient number of triggers per pair of detector to trigger the change of RCR (at different times)

pro stx_scenario_rate_control_regime__test::test_trigger_rate
  self.fsw->getproperty, stx_fsw_m_archive_buffer_group=archive_buffer_group, /complete, /combine
  triggers_arch = archive_buffer_group.triggers
  triggers = transpose(triggers_arch.triggers)

adg = stx_adg_sc_table()
subc_str = stx_construct_subcollimator()

cfl_idx =  where(subc_str.label eq 'cfl')
bkg_idx =  where(subc_str.label eq 'bkg')

adg_det_order =  (adg[sort( adg.sc )].adg_idx)[1:-1]

 cfl_adg = adg_det_order[cfl_idx]
 bkg_adg = adg_det_order[bkg_idx]
 
ixd_use = where((lindgen(16) + 1 ne (cfl_adg[0])) and  (lindgen(16) + 1 ne (bkg_adg[0])) )
 n_use = n_elements(ixd_use)
  s = size(triggers)
  triggers_persec_arch = fltarr(s[1],n_use)
 
  for i=0, n_use-1 do begin 
    triggers_persec_arch[*,i] = triggers[*,ixd_use[i]]/archive_buffer_group.time_axis.duration[*] 
  endfor

  relat_expected_time = [20L,40L,60L,80L,100L]  
  
   grid_factors = [ 0.296523,  0.272489,  0.271148,  0.305652,  0.140743,  0.256276,  0.252688,  0.252745,  0.252228,  0.256354,  0.255723,  0.257636,  0.282680,  0.305471,  0.261196,  0.272450]
  expected_adc_counts =(grid_factors/median(grid_factors))*4875.
  expected_adc_counts = expected_adc_counts[ixd_use]
  
  duration = archive_buffer_group.time_axis.duration
  
  n = n_elements(duration)
  incre_duration = fltarr(n)
  incre_duration[0] = duration[0]
  for i = 1, n-1 do begin
    incre_duration[i] = incre_duration[i-1]+duration[i]
  endfor
  
  m = n_elements(relat_expected_time)
  a = indgen(m)
  difference = fltarr(m,n_use)
  for i = 0, m-1 do begin
     temp = where(incre_duration gt relat_expected_time[i] )
     for k = 0,n_use-1 do begin
       difference[i,k] = triggers_persec_arch[temp[0]-1L,k] - expected_adc_counts[k]
     endfor
  endfor
  
  low = where(difference lt -400L, nl)
  high = where(difference gt 400L, nh)
  mess = ''
  if (nl gt 0) then begin
    indice = array_indices(difference,low)
    time_indice = fltarr(nl)
    trig_indice = indgen(nl)
    for i=0,nl-1 do begin
      time_indice[i] = relat_expected_time[indice[0,i]]
      trig_indice[i] = indice[1,i]
    endfor
    mess = mess + 'RCR TEST FAILURE: trigger counts are too low at times ' + strjoin(string(time_indice)) + ' and for pair of det number ' + strjoin(string(trig_indice))
  endif else if (nh gt 0) then begin
    indice = array_indices(difference,high)
    time_indice = fltarr(nh)
    trig_indice = indgen(nh)
    for i=0,nh-1 do begin
      time_indice[i] = relat_expected_time[indice[0,i]]
      trig_indice[i] = indice[1,i]
    endfor
    mess = mess + 'RCR TEST FAILURE: trigger counts are too high at times ' + strjoin(string(time_indice)) + ' and for pair of det number ' + strjoin(string(trig_indice))
  endif
  
  assert_true, ((nl eq 0) AND (nh eq 0)), mess
end

; This test verify if the RCR state is changing as many times as it should (in the presente case, 5 times)

pro stx_scenario_rate_control_regime__test::test_number_rcr_changes
  self.fsw->getproperty, stx_fsw_m_rate_control_regime=rate_control_regime, /combine, /complete  
  expected_number = 5
  diff_rcr = rate_control_regime.rcr - shift(rate_control_regime.rcr,1)
  change = where(diff_rcr ne 0,n)
  mess = 'RCR TEST FAILURE: ' + strtrim(n-1,2) + ' changes of RCR during simulation when ' + strtrim(expected_number,2) + ' expected'
  assert_true, ((n-1) - expected_number) eq 0, mess
end

; If we have the expected number of RCR state changes, this test verify is the values of the RCR state are the good ones

pro stx_scenario_rate_control_regime__test::test_value_rcr
  self.fsw->getproperty, stx_fsw_m_rate_control_regime=rate_control_regime, /combine, /complete
  diff_rcr = rate_control_regime.rcr - shift(rate_control_regime.rcr,1)
  change = where(diff_rcr ne 0,n)
  rcr_values = rate_control_regime.rcr[change]
  expected_values = [0,1,2,3,4,5]
    
  if n_elements(rcr_values) ne n_elements(expected_values) then difference = rcr_values*0-1 $
    else difference = (rcr_values - expected_values)
    
  mess = 'RCR TEST FAILURE: value of RCR (' + string(rcr_values,/print) + ') do not match expected values (' + string(expected_values,/print) + ')'
  assert_true, total(difference) eq 0, mess
end

; If we have the expected number of RCR state changes, this test verify that the changes occurs at the right time (+- 4 seconds)

pro stx_scenario_rate_control_regime__test::test_time_rcr_changes
  self.fsw->getproperty, stx_fsw_m_rate_control_regime=rate_control_regime, /combine, /complete
  diff_rcr = rate_control_regime.rcr - shift(rate_control_regime.rcr,1)
  change = where(diff_rcr ne 0,n)

  IF (n gt 0) then begin
  relat_time = dblarr(n-1)
    FOR i = 0, (n-2) DO BEGIN
    relat_time[i] = total(rate_control_regime.time_axis.duration[change[i]:change[i+1]-1])
    ENDFOR
  print, 'time between each change of rcr: ', relat_time
  ENDIF

  expected_relat_time = [20,20,20,20,20]
  if n_elements(relat_time) ne n_elements(expected_relat_time) then begin
    n1 = -2
    n2 = -2
    mess = 'RCR TEST FAILURE: number of changes of RCR value do not match expected number'  
  endif else begin
     difference = relat_time - expected_relat_time
     extra = where(difference gt 4, n1)
     infra = where(difference lt -4, n2)
     mess = 'RCR TEST FAILURE: ' + strtrim(n1,2) + ' changes of RCR are happening to late (' + strtrim(extra,2) + ') and ' + strtrim(n2,2) + 'changes of RCR are happening too soon (' + strtrim(infra,2) + ')'
  endelse
  
  assert_true, ((n1 eq 0) AND (n2 eq 0)), arr2str(mess, delimiter=', ')
end



;pro stx_scenario_rate_control_regime__test::test_trigger_counts
;  total_triggers_arch = self.fsw.livetime
;  s = size(total_triggers_arch.data)
;  total_triggers_persec_arch = fltarr(s[1],16)
; 
;  for i=0,15 do begin &$
;    total_triggers_persec_arch[*,i] = total_triggers_arch.data[*,i]/total_triggers_arch.time_axis.duration[*] &$
;  endfor
;  
;  window,2
;  set_line_color_2
;  utplot,stx_time2any(total_triggers_arch.time_axis.time_start), total_triggers_persec_arch[*,0], title = 'total trigger counts in archive buffer time bins',xr=[stx_time2any(total_triggers_arch.time_axis.time_start[10]),stx_time2any(total_triggers_arch.time_axis.time_start[830])]
;  for i=0,15 do begin &$
;    oplot,stx_time2any(total_triggers_arch.time_axis.time_start), total_triggers_persec_arch[*,i],color=i &$
;  endfor
;  assert_true, 1
;end

pro stx_scenario_rate_control_regime__test__define
  compile_opt idl2, hidden

  void = { $
    stx_scenario_rate_control_regime__test, $
    inherits stx_scenario_test }
end
