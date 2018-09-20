;+
; :file_comments:
;   This is a test class for scenario-based testing; specifically the rate control regime
;
; :categories:
;   data simulation, flight software simulator, software, testing
;
; :examples:
;  iut_test_runner('stx_fsw_rcr__test')
;
; :history:

;   06-jun-2018 - Nicky Hochmuth (FHNW) initial release
;-


function stx_fsw_rcr__test::init, _extra=extra

  self.sequence_name = 'RCR'
  self.test_name = 'AX_QL_TEST_RCR'
  self.configuration_file = 'stx_flight_software_simulator_ql_rcr.xml'
  setenv, 'WRITE_CALIBRATION_SPECTRUM=false'
  
  return, self->stx_fsw__test::init(_extra=extra)
end
  
  



pro stx_fsw_rcr__test::test_rcr
 

  self.fsw->getproperty, stx_fsw_m_rate_control_regime=stx_fsw_m_rate_control_regime, /complete, /combine

   self->_rcr, stx_fsw_m_rate_control_regime.rcr, self.t_shift_sim, title="SIM"

end

pro stx_fsw_rcr__test::test_rcr_tm

  self.tmtc_reader->getdata, asw_ql_lightcurve=ql_lightcurves,  solo_packet=solo_packets
  ql_lightcurve = ql_lightcurves[0]
  
  plot = obj_new('stx_plot')
  a = plot.create_stx_plot(stx_construct_lightcurve(from=ql_lightcurve), /lightcurve, /add_legend, title="TMTC Lightcurve Plot", ylog=1)

  self.plots->add, plot

    
  self->_rcr, ql_lightcurve.RATE_CONTROL_REGIME, self.t_shift, title="AX"

end

pro stx_fsw_rcr__test::_rcr, rcr, t_shift, title=title
  default, title, ""
  print, rcr
  
  ;expected = BYTE([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 3, 3, 2, 2, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]) 
  ;on 4 sec bounds
  expected = byte([0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 3, 4, 5, 5, 5, 6, 7, 7, 7, 6, 5, 4, 3, 2, 1, 2, 3, 2, 3, 2, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0])
  
  test_pos = indgen(N_ELEMENTS(expected)) * 2 + t_shift
  
    
  dif =  abs(fix(expected) - fix(rcr[test_pos])) 
  
  
  if self.show_plot then begin
    rcr_plot = stx_line_plot()
    a = rcr_plot._plot([transpose(indgen(N_ELEMENTS(expected))),transpose(indgen(N_ELEMENTS(expected)))], [transpose(expected),transpose(rcr[test_pos])], title=title, names=["expected","actual"], /add_legend, ylog=0, /histogram)
    self.plots->add, rcr_plot

  endif
  
  assert_true, total(dif) lt 5, "total rcr mismatch latger 5"
 
end


pro stx_fsw_rcr__test::beforeclass
  
  self->stx_fsw__test::beforeclass
  
  self.exepted_range = 0.05
  self.plots = list()
  self.show_plot = 1
 
    
  self.fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  
  lc =  total(lightcurve.accumulated_counts,1)
  start = min(where(lc gt 100))
  peak = max(lc[start:start+3], peak_idx)
  self.t_shift_sim = start+peak_idx
  
  stx_plot, lightcurve, plot=plot
  self.plots->add, plot
  
  if ~file_exist('ax_tmtc.bin') then begin
    tmtc_data = {$
      QL_LIGHT_CURVES : 1 $
    }

    print, self.fsw->getdata(output_target="stx_fsw_tmtc", filename='ax_tmtc.bin', _extra=tmtc_data)
  end
  
  
  self.tmtc_reader = stx_telemetry_reader(filename = "ax_tmtc.bin", /scan_mode, /merge_mode)
  self.tmtc_reader->getdata, statistics = statistics
  self.statistics = statistics
  
  


  self.tmtc_reader->getdata, asw_ql_lightcurve=ql_lightcurves,  solo_packet=solo_packets
  ql_lightcurve = ql_lightcurves[0]
  
  
  stx_sim_create_rcr_tc, self.conf
  
  default, directory , getenv('STX_DET')
  default, og_filename, 'offset_gain_table.csv'
  default, eb_filename, 'EnergyBinning20150615.csv'
  
  stx_sim_create_elut, og_filename=og_filename, eb_filename=eb_filename, directory = directory
  
   stx_sim_create_ql_tc, self.conf
  
  get_lun,lun
  openw, lun, "test_custom.tcl"
  printf, lun, 'syslog "running custom script for CFL test"'
  printf, lun, 'source [file join [file dirname [info script]] "TC_237_10_RCR.tcl"]'
  free_lun, lun
  
   
  lc =  total(ql_lightcurve.counts,1)
  start = min(where(lc gt 100))
  peak = max(lc[start:start+3], peak_idx)
  self.t_shift = start+peak_idx

end


pro stx_fsw_rcr__test__define
  compile_opt idl2, hidden

  void = { $
    stx_fsw_rcr__test, $
    inherits stx_fsw__test }
end
