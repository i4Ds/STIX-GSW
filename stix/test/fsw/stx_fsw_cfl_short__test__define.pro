;+
; :file_comments:
;   This is a test class for scenario-based testing; specifically the flare location test
;
; :categories:
;   data simulation, flight software simulator, software, testing
;
; :examples:
;   iut_test_runner('stx_fsw_cfl_short__test', keep_detector_eventlist=0b, show_fsw_plots=0b)
;   iut_test_runner('stx_fsw_cfl_short__test')
;
; :history:
;   05-Feb-2015 - Laszlo I. Etesi (FHNW), initial release
;   15-Mar-2019 - Nicky Hochmuth (FHNW), initial release
;-


function stx_fsw_cfl_short__test::init, _extra=extra

  self.sequence_name = 'stx_scenario_cfl_short_test'
  self.test_name = 'AX_QL_TEST_CFL'
  self.configuration_file = 'stx_flight_software_simulator_cfl.xml'
  self.offset_gain_table = "offset_gain_table_cfl.csv" 
  self.delay = 20 / 4 

  return, self->stx_fsw__test::init(_extra=extra)
end


pro stx_fsw_cfl_short__test::beforeclass

  self->stx_fsw__test::beforeclass
  self.exepted_range = 0.05
  
  self.show_plot = 1
  
  
  if self.show_plot then begin
    self.fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
    stx_plot, lightcurve, plot=plot
    self.plots->add, plot
  endif
  
  lc =  total(lightcurve.accumulated_counts,1)
  start = min(where(lc gt 100))
  peak = max(lc[start:start+3], peak_idx)
  self.t_shift_sim = start + peak_idx

  if ~file_exist('ax_tmtc.bin') then begin
    tmtc_data = {$
      QL_LIGHT_CURVES : 1,$
      ql_flare_flag_location: 1 $
    }

    print, self.fsw->getdata(output_target="stx_fsw_tmtc", filename='ax_tmtc.bin', _extra=tmtc_data)
  end


  self.tmtc_reader = stx_telemetry_reader(filename = "ax_tmtc.bin", /scan_mode, /merge_mode)
  self.tmtc_reader->getdata, statistics = statistics
  self.statistics = statistics






  self.tmtc_reader->getdata, asw_ql_lightcurve=ql_lightcurves,  solo_packet=solo_packets
  ql_lightcurve = ql_lightcurves[0]

  default, directory , getenv('STX_DET')
  default, og_filename, 'offset_gain_table.csv'
  default, eb_filename, 'EnergyBinning20150615.csv'

  stx_sim_create_elut, og_filename=og_filename, eb_filename=eb_filename, directory = directory
  
  stx_sim_create_ql_tc, self.conf
  
  skyFile = self.fsw->get(/cfl_cfl_lut)
  stx_sim_create_cfl_lut, CFL_LUT_FILENAMEPATH=skyFile
  
  get_lun,lun
  openw, lun, "test_custom.tcl"
  printf, lun, 'syslog "running custom script for CFL test"'
  printf, lun, 'source [file join [file dirname [info script]] "TC_237_7_16_SkyTab.tcl"]'
  printf, lun, 'TURN OFF RCR'
  printf, lun, 'execTC "ZIX37010  {PIX00401 Disabled}  {PIX00402 4095} {PIX00403 8191} {PIX00404 7951} {PIX00405 4351} {PIX00406 6671} {PIX00407 5391} {PIX00408 4271} {PIX00409 4191} {PIX00410 6159} {PIX00411 5135} {PIX00412 4623} {PIX00413 4367} {PIX00414 4239} {PIX00415 4175} {PIX00416 4143} {PIX00417 4127} {PIX00418 4111} {PIX00419 4106} {PIX00420 4101} {PIX00421 4104} {PIX00422 4100} {PIX00423 4098} {PIX00424 4097} {PIX00425 8191} {PIX00426 2031} {PIX00427 1487} {PIX00428 1487} {PIX00429 1487} {PIX00430 1487} {PIX00431 1487} {PIX00432 1487} {PIX00433 65535} {PIX00434 350} {PIX00435 700} {PIX00436 1050} {PIX00437 1400} {PIX00438 2000} {PIX00439 0} {PIX00440 1} {PIX00441 2} {PIX00442 3} {PIX00443 4} {PIX00444 5} {PIX00445 6} {PIX00446 7}"'
  free_lun, lun
  
  lc =  total(ql_lightcurve.counts,1)
  start = min(where(lc gt 100))
  peak = max(lc[start:start+3], peak_idx)
  self.t_shift = start + peak_idx


end


function stx_fsw_cfl_short__test::_estimate_scenario_locations

  x0 =40.
  y0 = -40.
  full_turns =2
  n = 24

  part_turns  = ((atan(y0,x0)/(2.*!pi) mod 1) + 1) mod 1
  turns =  full_turns + part_turns

  b= sqrt(x0^2. + y0^2.)/(turns*2.*!pi)

  t = findgen(n)/(n-1)*turns*2.*!pi
  x= b*t*cos(t)
  y= b*t*sin(t)

  true_cfl = dblarr(n, 2)
  true_cfl[*, 0] = x
  true_cfl[*, 1] = y

  return, true_cfl
end
;+
; :description:
;   this tests if the location values are not infinite during the time of the flare (it will normally be when there is no source)
;-
;+
; :description:
;   this tests if the location values are not infinite during the time of the flare (it will normally be when there is no source)
;-

pro stx_fsw_cfl_short__test::test_all_valid
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)
  self->_all_valid,flare_flag
end

pro stx_fsw_cfl_short__test::test_all_valid_tm
    self.tmtc_reader->getdata, asw_ql_flare_flag_location=ffl_tm, solo_packet=solo_packets
  flare_flag = (ffl_tm[0].flare_flag)[self.t_shift:-1]
  self->_all_valid, flare_flag
end

pro stx_fsw_cfl_short__test::_all_valid, flare_flag

  location_status_index = (ishft(flare_flag,-5) and 3B)
 
  not_valid = where(location_status_index eq 0, num_not_valid)
  
  mess = 'CFL TEST FAILURE: all values of coarse flare location are infinite or NaN'
  assert_true, (num_not_valid ne 0), mess
end

pro stx_fsw_cfl_short__test::test_all_new
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  flare_flag = (flare_flag_str.flare_flag)
  self->_all_new,flare_flag
end

pro stx_fsw_cfl_short__test::test_all_new_tm
  self.tmtc_reader->getdata, asw_ql_flare_flag_location=ffl_tm, solo_packet=solo_packets
  flare_flag = (ffl_tm[0].flare_flag)[self.t_shift:-1]
  self->_all_new, flare_flag
end

pro stx_fsw_cfl_short__test::_all_new, flare_flag
  
  location_status_index = (ishft(flare_flag,-5) and 3B)

  not_valid = where(location_status_index[1:-1] eq 1, num_not_valid)

  mess = 'CFL TEST FAILURE: all values of coarse flare location are infinite or NaN'
  assert_true, (num_not_valid ne 0), mess
end

;+
; :description:
;   This module tests if we have the right number of time intervals where we have a coarse flare location
;-

pro stx_fsw_cfl_short__test::test_number_intervals

  self.fsw->getproperty, stx_fsw_m_coarse_flare_location=coarse_flare_location, /complete, /combine
  self.fsw->getproperty, stx_fsw_m_flare_flag=flare_flag_str, /complete, /combine
  self->_number_intervals, coarse_flare_location.x_pos, coarse_flare_location.y_pos, flare_flag_str.flare_flag, self.t_shift_sim
end


pro stx_fsw_cfl_short__test::test_number_intervals_tm
self.tmtc_reader->getdata, asw_ql_flare_flag_location=ffl_tm, solo_packet=solo_packets
ffl_tm = ffl_tm[0]

x = ffl_tm.x_pos[self.t_shift:-1]
y = ffl_tm.y_pos[self.t_shift:-1]

tc = (self.conf->get(/cfl_update_frequency)).update_frequency / (self.conf->get(/fd_update_frequency)).update_frequency
idxs = indgen(N_ELEMENTS(x)/tc)*tc

x=x[idxs]
y=y[idxs]

flare_flag = ffl_tm.flare_flag[self.t_shift:-1]

self->_number_intervals, x, y, flare_flag, self.t_shift

end

;+
; :description:
;   This module tests if we have the right number of time intervals where we have a coarse flare location
;-

pro stx_fsw_cfl_short__test::_number_intervals, x, y, flare_flag, t_shift
  inf = 0
  right_number = 1
 
  true_cfl = self->_estimate_scenario_locations()
  t_bins = n_elements(true_cfl[*,0])

  cfl = dblarr(t_bins, 2)
  
  idx_spots = t_shift+self.delay + ((indgen(t_bins)+1)*2)
  
  x = x[idx_spots]
  y = y[idx_spots]
  
  cfl[*, 0] = x 
  cfl[*, 1] = y
  
  flare_flag = flare_flag[idx_spots]
  
  
  is_a_number = finite(cfl)


  location_status_index = (ishft(flare_flag,-5) and 3B)

  not_inv = where((is_a_number eq 1) and (location_status_index ne 0), n_vaid_loc) ; not_inf is the subset of indices where flare location is not NAN


  if (n_vaid_loc eq 0) then begin
    ; here we eliminate the case where there is no flare location at all during the test (all values are NAN)
    inf = 1
    mess = 'CFL TEST FAILURE: all values of CFL are not finite numbers'
  endif else begin
    ; separate intervals where the location of the source is known (we can have successive sources)

    
    x_true = true_cfl[*,0]

    n_true_locs= n_elements(x_true)

    if (n_true_locs ne n_vaid_loc) then begin
      mess = 'CFL TEST FAILURE: there are ' + strjoin(string(n_vaid_loc)) + ' different intervals with coarse flare location instead of '+ strjoin(string(n_true_locs))
      print,mess
      right_number = 0
    endif
  endelse

  assert_true, (inf eq 0) and (right_number eq 1), mess
end


;+
; :description:
;   This module tests the values of the location if not infinite and will be true only if the location is right (with precision of 2 arcmin)
;-
pro stx_fsw_cfl_short__test::test_value_location

  self.fsw->getproperty, stx_fsw_m_coarse_flare_location=coarse_flare_location, /complete, /combine
  self->_value_location, coarse_flare_location.x_pos, coarse_flare_location.y_pos, self.t_shift_sim, "SIM"
  
end

;+
; :description:
;   This module tests the values of the location if not infinite and will be true only if the location is right (with precision of 2 arcmin)
;-
pro stx_fsw_cfl_short__test::test_value_location_tm

  self.tmtc_reader->getdata, asw_ql_flare_flag_location=ffl_tm, solo_packet=solo_packets
  ffl_tm = ffl_tm[0]
  
  x = ffl_tm.x_pos
  y = ffl_tm.y_pos
  
  tc = (self.conf->get(/cfl_update_frequency)).update_frequency / (self.conf->get(/fd_update_frequency)).update_frequency  
  idxs = indgen(N_ELEMENTS(x)/tc)*tc
  
  x=x[idxs]
  y=y[idxs]
  
  self->_value_location, x, y, self.t_shift, "AX"

end

;+
; :description:
;   This module tests the values of the location if not infinite and will be true only if the location is right (with precision of 2 arcmin) 
;-
pro stx_fsw_cfl_short__test::_value_location, x, y, t_shift, title
  inf = 0
  value = 1
  
  true_cfl = self->_estimate_scenario_locations()
  t_bins = n_elements(true_cfl[*,0])

  cfl = dblarr(t_bins, 2)
  
  idx_spots = t_shift + self.delay + ((indgen(t_bins)+1)*2)
  ;idx_spots = 3  + ((indgen(t_bins)+1))

  
  x = x[idx_spots]
  y = y[idx_spots]
  
  cfl[*, 0] = x 
  cfl[*, 1] = y


  is_a_number = finite(cfl)
  not_inf = where(is_a_number eq 1, n_not_inf) ; not_inf is the subset of indices where flare location is not NAN

  if (n_not_inf eq 0) then begin
    inf = 1
    mess = 'CFL TEST FAILURE: all values of CFL are not finite numbers'
  endif else begin

   
    x_true = true_cfl[*,0]
    y_true = true_cfl[*,1]

 if self.show_plot then begin
   dist   = 3.33
   rsun   = 0.696342  ; Solar radius [10^6 km]
   au     = 149.597871  ; 1AU [10^6 km]
   s_dist = 0.28


   points = (2 * !PI / 99.0) * findgen(100)

   ssize = atan(rsun/(s_dist*au))/!dtor*60.
   sxp = ssize * cos( points )
   syp = ssize * sin( points )

   ssize1 = atan(rsun/(1.0*au))/!dtor*60.
   sy1 = ssize1 * sin( points )
   sx1 = ssize1 * cos( points )

   p = plot(x_true, y_true, symbol ='*', line = '-', xrange = [-66,66], yrange =[-66,66], dimensions = [600,600], title=title)
   p = plot(sxp, syp, /over, line = ':')
   p = plot(sx1, sy1, /over, line = ':')
   p = plot(x,y, symbol ='D', line = '-', /over, sym_thick = 2, rgb_table = 3, vert_colors = findgen(24)/34.*255)
   
   p1 = plot(indgen(t_bins), x_true, symbol ='*', line = '-', COLOR="b", title=title, NAME="X-True", dimensions = [1200,600])
   p2 = plot(indgen(t_bins), y_true, symbol ='*', line = '-', COLOR="r", NAME="Y-True", /over )
   p3 = plot(indgen(t_bins), x, symbol ='*', line = ':', COLOR="b", NAME="X", /over)
   p4 = plot(indgen(t_bins), y, symbol ='*', line = ':', COLOR="r", NAME="Y", /over )
   
   leg = LEGEND(TARGET=[p1,p2,p3,p4], /AUTO_TEXT_COLOR)
   

 endif
    
    difference =  sqrt((x-x_true)^2 + (y-y_true)^2)
    loc_too_far = where(difference gt 5.0, count_too_far)

    if count_too_far gt 3 then begin
      value = 0
      mess = 'CFL TEST FAILURE: values of CFL are not close enough to expected values: '
      print, mess +string(10B) +'CFL value for is ',cfl[loc_too_far,*], ' instead of', true_cfl[loc_too_far,*]
      print, mess +string(10B) + 'Distance is ', difference[loc_too_far]
      print, mess
    endif
  endelse

  assert_true, (inf eq 0) and (value eq 1), mess

end

;+
; :description:
;   This module tests the values of the location if not infinite and will be true only if the location is right (with precision of 4 arcmin)
;-
pro stx_fsw_cfl_short__test::test_value_location2
  
  self.fsw->getproperty, stx_fsw_m_coarse_flare_location=coarse_flare_location, /complete, /combine
  self->_value_location2, coarse_flare_location.x_pos, coarse_flare_location.y_pos, self.t_shift_sim
   
end

pro stx_fsw_cfl_short__test::test_value_location2_tm

  self.tmtc_reader->getdata, asw_ql_flare_flag_location=ffl_tm, solo_packet=solo_packets
  ffl_tm = ffl_tm[0]
  
  x = ffl_tm.x_pos
  y = ffl_tm.y_pos
  
  tc = (self.conf->get(/cfl_update_frequency)).update_frequency / (self.conf->get(/fd_update_frequency)).update_frequency  
  idxs = indgen(N_ELEMENTS(x)/tc)*tc
  
  x=x[idxs]
  y=y[idxs]
  
  self->_value_location2, x, y , self.t_shift

end


;+
; :description:
;   This module tests the values of the location if not infinite and will be true only if the location is right (with precision of 4 arcmin) 
;-
pro stx_fsw_cfl_short__test::_value_location2, x, y, t_shift
  inf = 0
  value = 1
   
  true_cfl = self->_estimate_scenario_locations()
  t_bins = n_elements(true_cfl[*,0])

  cfl = dblarr(t_bins, 2)
  
  idx_spots = t_shift+self.delay + ((indgen(t_bins)+1)*2)
  idx_spots = 3  + ((indgen(t_bins)+1))


  x = x[idx_spots]
  y = y[idx_spots]
  
  cfl[*, 0] = x 
  cfl[*, 1] = y


  is_a_number = finite(cfl)
  not_inf = where(is_a_number eq 1, n_not_inf) ; not_inf is the subset of indices where flare location is not NAN

  if (n_not_inf eq 0) then begin
    inf = 1
    mess = 'CFL TEST FAILURE: all values of CFL are not finite numbers'
  endif else begin

    x_true = true_cfl[*,0]
    y_true = true_cfl[*,1]

    difference =  sqrt(( x - x_true )^2 + ( y - y_true )^2)
    loc_too_far = where(difference gt 5.0, count_too_far)

    if count_too_far gt 3 then begin
      value = 0
      mess = 'CFL TEST FAILURE: values of CFL are not close enough to expected values at peak of the flare: '
      print, mess +string(10B) +'CFL value for is ',cfl[loc_too_far,*], ' instead of ', true_cfl[loc_too_far,*]
      print, mess +string(10B) + 'Distance is ', difference[loc_too_far]
      print, mess
    endif
  endelse

  assert_true, (inf eq 0) and (value eq 1), mess

end


pro stx_fsw_cfl_short__test::test_nearest_neighbour
 

  self.fsw->getproperty, stx_fsw_m_coarse_flare_location=coarse_flare_location, /complete, /combine

  self->_nearest_neighbour, coarse_flare_location.x_pos, coarse_flare_location.y_pos

end

pro stx_fsw_cfl_short__test::test_nearest_neighbour_tm

  self.tmtc_reader->getdata, asw_ql_flare_flag_location=ffl_tm, solo_packet=solo_packets
  ffl_tm = ffl_tm[0]

  x = ffl_tm.x_pos[self.t_shift:-1]
  y = ffl_tm.y_pos[self.t_shift:-1]

  tc = (self.conf->get(/cfl_update_frequency)).update_frequency / (self.conf->get(/fd_update_frequency)).update_frequency
  idxs = indgen(N_ELEMENTS(x)/tc)*tc

  x=x[idxs]
  y=y[idxs]

  
  self->_nearest_neighbour, x, y

end

pro stx_fsw_cfl_short__test::_nearest_neighbour, x, y
  inf = 0
  value = 1


  cfl = dblarr(n_elements(x), 2)

  cfl[*, 0] = x
  cfl[*, 1] = y


  is_a_number = finite(cfl)
  not_inf = where(is_a_number eq 1, n_not_inf) ; not_inf is the subset of indices where flare location is not NAN

  if (n_not_inf eq 0) then begin
    inf = 1
    mess = 'CFL TEST FAILURE: all values of CFL are not finite numbers'
  endif else begin

    true_cfl = self->_estimate_scenario_locations()

    x_true = true_cfl[*,0]
    y_true = true_cfl[*,1]

    yf = round(y/2. +32.)
    xf = round(x/2. +32.)
    xt = round(x_true/2. +32.)
    yt = round(y_true/2. +32.)

    df= [[abs(xf - xt)] , [abs(yf - yt)]]

    loc_too_far = where(max(df, dim = 2) ge 2.0, count_too_far)

    if count_too_far lt 1 then begin
      value = 0
      mess = 'CFL TEST FAILURE: values of CFL are not close enough to expected values: '
      print, mess +string(10B) +'CFL value for is ',cfl[loc_too_far,*], ' instead of ', true_cfl[loc_too_far,*]
      print, mess +string(10B) + 'Distance is ', df[loc_too_far,*]
      print, mess
    endif
  endelse

  assert_true, (inf eq 0) and (value eq 1), mess

end




;+
; cleanup at object destroy
;-
pro stx_fsw_cfl_short__test::afterclass
  v = stx_offset_gain_reader(/reset)
  destroy, self.tmtc_reader
end



pro stx_fsw_cfl_short__test__define
  compile_opt idl2, hidden

  void = { $
    stx_fsw_cfl_short__test, $
    delay : 0, $
  inherits stx_fsw__test }
    
end
