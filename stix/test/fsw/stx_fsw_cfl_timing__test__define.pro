;+
; :file_comments:
;   This is a test class for scenario-based testing; specifically the flare location test
;
; :categories:
;   data simulation, flight software simulator, software, testing
;
; :examples:
;   iut_test_runner('stx_fsw_cfl_timing__test', keep_detector_eventlist=0b, show_fsw_plots=0b)
;   iut_test_runner('stx_fsw_cfl_timing__test')
;
; :history:
;   30-11-2018 - Nicky Hochmuth  initial release
;-


function stx_fsw_cfl_timing__test::init, _extra=extra

  self.sequence_name = 'stx_scenario_cfl_timing_test'
  self.test_name = 'AX_QL_TEST_CFL_TIMING'
  self.configuration_file = 'stx_flight_software_simulator_ql_fd.xml'
  self.offset_gain_table = "" ;use default
  self.delay = 2 

  return, self->stx_fsw__test::init(_extra=extra)
end


pro stx_fsw_cfl_timing__test::beforeclass

  self->stx_fsw__test::beforeclass
  self.exepted_range = 0.05
  
  self.show_plot = 1
  
  self.fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  
  if self.show_plot then begin
    lc_plot = obj_new('stx_plot')
    a = lc_plot.create_stx_plot(stx_construct_lightcurve(from=lightcurve), /lightcurve, /add_legend, title="Lightcurve SIM", ylog=1)
    self.plots->add, lc_plot
  
  endif
  
  lc =  total(lightcurve.accumulated_counts,1)
  start = min(where(lc gt 100))
  self.t_shift_sim = start

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
  self.t_shift = start
  
  if self.show_plot then begin
    lc_plot = obj_new('stx_plot')
    a = lc_plot.create_stx_plot(stx_construct_lightcurve(from=ql_lightcurve), /lightcurve, /add_legend, title="Lightcurve AX", ylog=1)
    self.plots->add, lc_plot
  endif


end


function stx_fsw_cfl_timing__test::_estimate_scenario_locations

   n = 33

  true_cfl = dblarr(n, 3)
  true_cfl[*, 0] =    [0,   0,   4,   0, -10,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  30,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  -4]
  true_cfl[*, 1] =    [0,   0,   4,   0, -8,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  30,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  -4]
  true_cfl[*, 2] = indgen(n) * 4 
  return, true_cfl
end



;+
; :description:
;   This module tests the values of the location if not infinite and will be true only if the location is right (with precision of 2 arcmin)
;-
pro stx_fsw_cfl_timing__test::test_value_location

  self.fsw->getproperty, stx_fsw_m_coarse_flare_location=coarse_flare_location, /complete, /combine
  
  time = stx_time_diff( coarse_flare_location.TIME_AXIS.time_start, coarse_flare_location.TIME_AXIS.time_start[0]) + ((self.t_shift_sim)  * 4)
  
  self->_value_location, coarse_flare_location.x_pos, coarse_flare_location.y_pos, time, self.t_shift_sim, "SIM"
  
end

;+
; :description:
;   This module tests the values of the location if not infinite and will be true only if the location is right (with precision of 2 arcmin)
;-
pro stx_fsw_cfl_timing__test::test_value_location_tm

  self.tmtc_reader->getdata, asw_ql_flare_flag_location=ffl_tm, solo_packet=solo_packets
  ffl_tm = ffl_tm[0]
  
  x = ffl_tm.x_pos
  y = ffl_tm.y_pos
  time = stx_time_diff( ffl_tm.TIME_AXIS.time_start, ffl_tm.TIME_AXIS.time_start[0]) + (self.delay * 4)
  
  tc = (self.conf->get(/cfl_update_frequency)).update_frequency / (self.conf->get(/fd_update_frequency)).update_frequency  
  idxs = indgen(N_ELEMENTS(x)/tc) * tc
  
  x=x[idxs]
  y=y[idxs]
  
  self->_value_location, x, y, time, self.t_shift, "AX"

end

;+
; :description:
;   This module tests the values of the location if not infinite and will be true only if the location is right (with precision of 2 arcmin) 
;-
pro stx_fsw_cfl_timing__test::_value_location, x, y, time, t_shift, title
  inf = 0
  value = 1
  
  true_cfl = self->_estimate_scenario_locations()
  t_bins = n_elements(true_cfl[*,0])

  cfl = dblarr(t_bins, 2)
  
  idx_spots = t_shift + ((indgen(t_bins)))
  
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

   
    x_true = true_cfl[self.delay:-1,0]
    y_true = true_cfl[self.delay:-1,1]
    time_true = true_cfl[self.delay:-1,2]

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
   
   p1 = plot(time_true, x_true, symbol ='*', line = '-', COLOR="b", title=title, NAME="X-True", dimensions = [1200,600])
   p2 = plot(time_true, y_true, symbol ='*', line = '-', COLOR="r", NAME="Y-True", /over )
   p3 = plot(time, x, symbol ='*', line = ':', COLOR="b", NAME="X", /over)
   p4 = plot(time, y, symbol ='*', line = ':', COLOR="r", NAME="Y", /over )
   
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
; cleanup at object destroy
;-
pro stx_fsw_cfl_timing__test::afterclass
  v = stx_offset_gain_reader(/reset)
  destroy, self.tmtc_reader
end



pro stx_fsw_cfl_timing__test__define
  compile_opt idl2, hidden

  void = { $
    stx_fsw_cfl_timing__test, $
    delay : 0, $
  inherits stx_fsw__test }
    
end
