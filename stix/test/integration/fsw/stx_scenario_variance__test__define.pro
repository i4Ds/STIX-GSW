;+
; :file_comments:
;   This is a test class for scenario-based testing; specifically the variance calculation test
;
; :categories:
;   data simulation, flight software simulator, software, testing
;
; :examples:
;  res = iut_test_runner('stx_scenario_variance__test', keep_detector_eventlist=0b, show_fsw_plots=0b)
;  res = iut_test_runner('stx_scenario_variance__test')
;
; :history:
; 30-Nov-2015 - ECMD (Graz), initial release
; 10-may-2016 - Laszlo I. Etesi (FHNW), minor updates to accomodate structure changes
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
function stx_scenario_variance__test::init, _extra=extra
  self.test_name = 'variance'
  self.test_type = 'basic'
  
  return, self->stx_scenario_test::init(_extra=extra)
end

;+
;
; :description:
;
;   This procedure compares the variance of the interval with the fisrt spike with the expected value
;
;-
pro stx_scenario_variance__test::test_varience_spike1
  expected = 73920.
  lower_limit = 60612.5
  upper_limit = 88887.5
  
  self.fsw->getproperty, stx_fsw_m_variance=fsw_variance_str, /combine, /complete
  spike_variance = (fsw_variance_str.variance)[3]
  
  agree = ((spike_variance ge lower_limit ) and (spike_variance le upper_limit) )
  
  mess = 'Variance spike 1 test failure :' +$
    string(13B) + 'Expected variance:' + strjoin(trim(long(expected)),",") +$
    string(13B) + 'but found variance: ' + strjoin(trim(long(spike_variance)),",")
    
  assert_true, agree, mess
end



;+
;
; :description:
;
;   This procedure compares the variance of the interval with the second spike with the expected value
;
;-
pro stx_scenario_variance__test::test_varience_spike2
  expected =  787.500
  lower_limit = 550.
  upper_limit = 2002.50
  
  self.fsw->getproperty, stx_fsw_m_variance=fsw_variance_str, /combine, /complete
  spike_variance = (fsw_variance_str.variance)[6]
  
  agree = ((spike_variance ge lower_limit ) and (spike_variance le upper_limit) )
  
  mess = 'Variance spike 2 test failure :' +$
    string(13B) + 'Expected variance:' + strjoin(trim(long(expected)),",") +$
    string(13B) + 'but found variance: ' + strjoin(trim(long(spike_variance)),",")
    
  assert_true, agree, mess
end




;+
;
; :description:
;
;  This procedure compares the variance of the interval with the third spike with the expected value
;
;-
pro stx_scenario_variance__test::test_varience_spike3
  expected = 4130.
  lower_limit = 2323.00
  upper_limit =  6693.00

  self.fsw->getproperty, stx_fsw_m_variance=fsw_variance_str, /combine, /complete
  spike_variance = (fsw_variance_str.variance)[9]
  
  agree = ((spike_variance ge lower_limit ) and (spike_variance le upper_limit) )
  
  mess = 'Variance spike 3 test failure :' +$
    string(13B) + 'Expected variance:' + strjoin(trim(long(expected)),",") +$
    string(13B) + 'but found variance: ' + strjoin(trim(long(spike_variance)),",")
    
  assert_true, agree, mess
end





;+
;
; :description:
;
;   this procedure compares the variance of the intervals with only background counts with the expected value
;
;-
pro stx_scenario_variance__test::test_varience_background
  expected = 139.
  lower_limit = 77.
  upper_limit = 237.
  
  
  idx_spike = [3,6,9]
  idx_hist = histogram(idx_spike, min =0,max = 15)
  bkg_idx = where( idx_hist eq 0)
  self.fsw->getproperty, stx_fsw_m_variance=fsw_variance_str, /combine, /complete
  spike_variance = median((fsw_variance_str.variance)[bkg_idx])
  
  agree = ((spike_variance ge lower_limit ) and (spike_variance le upper_limit) )
  
  
  mess = 'Variance background test failure :' +$
    string(13B) + 'Expected variance:' + strjoin(trim(long(expected)),",") +$
    string(13B) + 'but found variance: ' + strjoin(trim(long(spike_variance)),",")
    
  assert_true, agree, mess
end




pro stx_scenario_variance__test__define
  compile_opt idl2, hidden
  
  void = { $
    stx_scenario_variance__test, $
    inherits stx_scenario_test }
end
