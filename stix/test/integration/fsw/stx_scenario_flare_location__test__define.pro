;+
; :file_comments:
;   This is a test class for scenario-based testing; specifically the flare location test
;
; :categories:
;   data simulation, flight software simulator, software, testing
;
; :examples:
;   iut_test_runner('stx_scenario_flare_location__test', keep_detector_eventlist=0b, show_fsw_plots=0b)
;   iut_test_runner('stx_scenario_flare_location__test')
;
; :history:
;   05-Feb-2015 - Laszlo I. Etesi (FHNW), initial release
;   10-may-2016 - Laszlo I. Etesi (FHNW), minor updates to accomodate structure changes
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
function stx_scenario_flare_location__test::init, _extra=extra
  self.test_name = 'flare_location'
  self.test_type = 'basic'
  
  return, self->stx_scenario_test::init(_extra=extra)
end

;+
; :description:
;   this tests if the location values are not infinite during the time of the flare (it will normally be when there is no source)
;-

pro stx_scenario_flare_location__test::test_location_isnot_infinite
  self.fsw->getproperty, stx_fsw_m_coarse_flare_location=coarse_flare_location, /complete, /combine
  cfl = dblarr(n_elements(coarse_flare_location.x_pos), 2)
  cfl[*, 0] = coarse_flare_location.x_pos
  cfl[*, 1] = coarse_flare_location.y_pos

  number_or_not = finite(cfl)
  not_inf = where(number_or_not eq 1)
  mess = 'CFL TEST FAILURE: all values of coarse flare location are infinite or NaN'
  assert_true, (n_elements(not_inf) ne 1) OR (not_inf[0] ne (-1)), mess
end

;+ 
; :description:
;   This module tests if we have the right number of time intervals where we have a coarse flare location
;-

pro stx_scenario_flare_location__test::test_number_intervals
  inf = 0
  right_number = 1 
  
  self.fsw->getproperty, stx_fsw_m_coarse_flare_location=coarse_flare_location, /complete, /combine
  cfl = dblarr(n_elements(coarse_flare_location.x_pos), 2)
  cfl[*, 0] = coarse_flare_location.x_pos
  cfl[*, 1] = coarse_flare_location.y_pos
  
  is_a_number = finite(cfl)

  not_inf = where(is_a_number eq 1, n_not_inf) ; not_inf is the subset of indices where flare location is not NAN
  
  IF (n_not_inf eq 0) THEN BEGIN
    ; here we eliminate the case where there is no flare location at all during the test (all values are NAN)
    inf = 1
    mess = 'CFL TEST FAILURE: all values of CFL are not finite numbers'
  ENDIF ELSE BEGIN
    ; separate intervals where the location of the source is known (we can have successive sources)
    sep = not_inf[0:n_elements(not_inf)/2-1] - shift(not_inf[0:n_elements(not_inf)/2-1],1) ; to know if the indices in not_inf are consecutive or not, calculation of the separation between two succesive indices
    sep = sep[1:n_elements(sep)-1] ; get rid of the first and last values of this
    separation = where(sep ne 1, n_separation)
    IF (n_separation ne 1) THEN BEGIN
      mess = 'CFL TEST FAILURE: there are ' + strjoin(string(n_separation)) + ' different intervals with coarse flare location instead of 2'
      print,mess
      right_number = 0
    ENDIF  
  ENDELSE

assert_true, (inf eq 0) AND (right_number eq 1), mess
END

;+ 
; :description:
;   This module tests if the value of the location is stable during the flare, ie if it shows always the same value or a close one (+- 2 arcmin)
;   To do so we calculate the mean value of the flare location, then calculate the difference between the values and the mean, found the maximum of difference 
;   if the max of difference between one value and the mean in inf to 2 arcmin, the location is said to be stable.
;-

pro stx_scenario_flare_location__test::test_location_stable
  inf = 0
  stable = 1
  
  self.fsw->getproperty, stx_fsw_m_coarse_flare_location=coarse_flare_location, /complete, /combine
  cfl = dblarr(n_elements(coarse_flare_location.x_pos), 2)
  cfl[*, 0] = coarse_flare_location.x_pos
  cfl[*, 1] = coarse_flare_location.y_pos
  is_a_number = finite(cfl)
  
  not_inf = where(is_a_number eq 1, n_not_inf) ; not_inf is the subset of indices where flare location is not NAN
  
  IF (n_not_inf eq 0) THEN BEGIN
    inf = 1
    mess = 'CFL TEST FAILURE: all values of CFL are not finite numbers'
  ENDIF ELSE BEGIN
    ; we consider only the first half of not_inf since we expect to have the first half of it concerning the x position and the second half concerns the y position
    ; separate intervals where the location of the source is known (we can have successive sources)
    sep = not_inf[0:n_elements(not_inf)/2-1] - shift(not_inf[0:n_elements(not_inf)/2-1],1) ; to know if the indices in not_inf are consecutive or not, calculation of the separation between two succesive indices
    sep = sep[1:n_elements(sep)-1] ; get rid of the first and last values of this
    separation = where(sep ne 1, n_separation)
    print,'there are ', n_separation +1, ' intervals where we have a coarse flare location'
    
    ; first iteration
    interval = not_inf[0:separation[0]]
    ;sub_cfl = fltarr(n_elements(interval),2)
    ;sub_cfl[*,0] = cfl[interval,0]
    ;sub_cfl[*,1] = cfl[interval,1]
    moy = fltarr(2)
    moy[0] = mean(cfl[interval,0]) ; mean value of the x position
    moy[1] = mean(cfl[interval,1]) ; mean value of the y position
    ecart = fltarr(n_elements(interval),2)
    ecart[*,0] = abs(cfl[interval,0] - moy[0])
    ecart[*,1] = abs(cfl[interval,1] - moy[1])
    help,ecart
    IF max(ecart) gt 2 THEN BEGIN
      stable = 0
      mess = 'CFL TEST FAILURE: location of source is not stable during one flare'
    ENDIF
    
    ;; old way to do it
    ;difference = sub_cfl.data - shift(cfl.data,1)
    ;loc = where(ABS(difference) gt 3) ; location of source can vary but if variation if greater than 3 arcmin we consider the location is not stable
    ;IF (n_elements(loc) eq 1) AND (loc[0] eq -1) THEN BEGIN
    ;  stable = 0
    ;  mess = 'CFL TEST FAILURE: location of source is not stable during one flare'
    ;ENDIF

    ; other iterations
    FOR i=1,n_separation -1 DO BEGIN
      interval = not_inf[separation[i-1]+1:separation[i]]
      moy = fltarr(2)
      moy[0] = mean(cfl[interval,0]) ; mean value of the x position
      moy[1] = mean(cfl[interval,1]) ; mean value of the y position
      ecart = fltarr(n_elements(interval),2)
      ecart[*,0] = abs(cfl[interval,0] - moy[0])
      ecart[*,1] = abs(cfl[interval,1] - moy[1])
      IF max(ecart) gt 2 THEN BEGIN
        stable = 0
        mess = 'CFL TEST FAILURE: location of source is not stable during one flare'
      ENDIF
    ENDFOR
    
    ; last iteration
    interval = not_inf[separation[n_separation -1]+1:n_elements(not_inf)/2-1]
    moy = fltarr(2)
    moy[0] = mean(cfl[interval,0]) ; mean value of the x position
    moy[1] = mean(cfl[interval,1]) ; mean value of the y position
    ecart = fltarr(n_elements(interval),2)
    ecart[*,0] = abs(cfl[interval,0] - moy[0])
    ecart[*,1] = abs(cfl[interval,1] - moy[1])
    help,ecart
    IF max(ecart) gt 2 THEN BEGIN
      stable = 0
      mess = 'CFL TEST FAILURE: location of source is not stable during one flare'
    ENDIF
  ENDELSE

  assert_true, (inf eq 0) AND (stable eq 1), mess

end

;+
; :description: 
;   This module tests the values of the location if not infinite and will be true only if the location is right (with precision of 2 arcmin) AT THE PEAK OF THE FLARE
;-
pro stx_scenario_flare_location__test::test_value_location
  inf = 0
  value = 1
  
  self.fsw->getproperty, stx_fsw_m_coarse_flare_location=coarse_flare_location, /complete, /combine
  cfl = dblarr(n_elements(coarse_flare_location.x_pos), 2)
  cfl[*, 0] = coarse_flare_location.x_pos
  cfl[*, 1] = coarse_flare_location.y_pos
  
  is_a_number = finite(cfl)
  not_inf = where(is_a_number eq 1, n_not_inf) ; not_inf is the subset of indices where flare location is not NAN
  
  IF (n_not_inf eq 0) THEN BEGIN
    inf = 1
    mess = 'CFL TEST FAILURE: all values of CFL are not finite numbers'
  ENDIF ELSE BEGIN
  ;We test here the value at the peak of the flare
    i_time1 = stx_time_value_locate(coarse_flare_location.time_axis.time_start, '1-Jan-2019 00:03:16.000')
    i_time2 = stx_time_value_locate(coarse_flare_location.time_axis.time_start, '1-Jan-2019 00:08:16.000') 
    ; the CFL values are in arcmin, and the following values are therefore also in arcmin     
    xvalue1 = 37.
    xvalue2 = -37.
    yvalue1 = 20.4
    yvalue2 = -20.4
  
    difference1 = (ABS(cfl[i_time1,*]-[xvalue1,yvalue1]) gt 2.)
    difference2 = (ABS(cfl[i_time2,*]-[xvalue2,yvalue2]) gt 2.)
    
    IF (total(difference1) + total(difference2)) ne 0. THEN BEGIN
      value = 0
      mess = 'CFL TEST FAILURE: values of CFL are not close enough to expected values at peak of the flare: '
      print, mess
      print, 'CFL value for first flare is ',cfl[i_time1,*], ' at the peak instead of ',[xvalue1,yvalue1]
      print, 'CFL value for second flare is ',cfl[i_time2,*], ' at the peak instead of ',[xvalue2,yvalue2]
    ENDIF
  ENDELSE

assert_true, (inf eq 0) AND (value eq 1), mess

end

;+
; :description:
;   This module tests the values of the location if not infinite and will be true only if the location is right (with precision of 2 arcmin) IN AVERAGE
;-
pro stx_scenario_flare_location__test::test_value_location2
  inf = 0
  value = 1

  self.fsw->getproperty, stx_fsw_m_coarse_flare_location=coarse_flare_location, /complete, /combine
  cfl = dblarr(n_elements(coarse_flare_location.x_pos), 2)
  cfl[*, 0] = coarse_flare_location.x_pos
  cfl[*, 1] = coarse_flare_location.y_pos
  
  is_a_number = finite(cfl)
  not_inf = where(is_a_number eq 1, n_not_inf) ; not_inf is the subset of indices where flare location is not NAN
  
  IF (n_not_inf eq 0) THEN BEGIN
    inf = 1
    mess = 'CFL TEST FAILURE: all values of CFL are not finite numbers'
  ENDIF ELSE BEGIN
    ; we assume here that we have flare location in only two time intervals (if this is not the case the second test would have fail)
    ; we will calculate again the mean value of the flare location in those two intervals, as we did in the previous test (stability test)
    ; the CFL values are in arcmin, and the following values are therefore also in arcmin
    xvalue1 = 37.
    xvalue2 = -37.
    yvalue1 = 20.4
    yvalue2 = -20.4
    ; separate intervals where the location of the source is known (we can have successive sources)
    sep = not_inf[0:n_elements(not_inf)/2-1] - shift(not_inf[0:n_elements(not_inf)/2-1],1) ; to know if the indices in not_inf are consecutive or not, calculation of the separation between two succesive indices
    sep = sep[1:n_elements(sep)-1] ; get rid of the first and last values of this
    separation = where(sep ne 1, n_separation)
    print,'there are ', n_separation +1, ' intervals where we have a coarse flare location'
    
    ; at this point we assume that n_separation = 1
    
    ; first iteration
    interval = not_inf[0:separation[0]]
    moy = fltarr(2)
    moy[0] = mean(cfl[interval,0]) ; mean value of the x position
    moy[1] = mean(cfl[interval,1]) ; mean value of the y position
    difference = abs(moy - [xvalue1,yvalue1])
    big_diff = where(difference gt 2, n_big_diff)
    IF n_big_diff ne 0 THEN BEGIN
      value = 0
      mess = 'CFL TEST FAILURE: values of CFL are in average not close enough to expected values'
      print, '1st flare average location is x=', moy[0], '; y=', moy[1], ' instead of', xvalue1, yvalue1
    ENDIF
    
    ; last iteration
    interval = not_inf[separation[0]+1:n_elements(not_inf)-1]
    moy = fltarr(2)
    moy[0] = mean(cfl[interval,0]) ; mean value of the x position
    moy[1] = mean(cfl[interval,1]) ; mean value of the y position
    difference = abs(moy - [xvalue1,yvalue1])
    big_diff = where(difference gt 2, n_big_diff)
    IF n_big_diff ne 0 THEN BEGIN
      value = 0
      mess = 'CFL TEST FAILURE: values of CFL are in average not close enough to expected values'
      print, '2nd flare average location is x=', moy[0], '; y=', moy[1], ' instead of', xvalue2, yvalue2
    ENDIF

    
  ENDELSE

  assert_true, (inf eq 0) AND (value eq 1), mess

end

pro stx_scenario_flare_location__test__define
  compile_opt idl2, hidden

  void = { $
    stx_scenario_flare_location__test, $
    inherits stx_scenario_test }
end
