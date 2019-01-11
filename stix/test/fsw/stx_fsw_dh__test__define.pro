;+
; :file_comments:
;   This is a test class for scenario-based testing; specifically the detector health monitor
;
; :categories:
;   data simulation, flight software simulator, software, testing
;
; :examples:
;  iut_test_runner('stx_fsw_dh__test')
;
; :history:

;   08-jan-2019 - Nicky Hochmuth (FHNW) initial release
;-


function stx_fsw_dh__test::init, _extra=extra

  self.sequence_name = 'stx_scenario_detector_failure_test'
  self.test_name = 'AX_DH_TEST'
  self.configuration_file = 'stx_flight_software_simulator_dh.xml'
  self.offset_gain_table = "offset_gain_table.csv"
  setenv, 'WRITE_CALIBRATION_SPECTRUM=false'
  
  return, self->stx_fsw__test::init(_extra=extra)
end
  

pro stx_fsw_dh__test::beforeclass
  
  
  self->stx_fsw__test::beforeclass
  
  self.exepted_range = 0.05
  self.plots = list()
  self.show_plot = 1
 
    
  self.fsw->getproperty, reference_time = reference_time, $
       current_time  = current_time, $
       stx_fsw_m_detector_monitor = detector_monitor, $
       stx_fsw_m_flare_flag = flare_flag, $
       stx_fsw_ql_lightcurve=lightcurve, $
       /complete, /combine
  
  lc =  total(lightcurve.accumulated_counts,1)
  start = min(where(lc gt 100))
  self.t_shift_sim = start
  
  stx_plot, lightcurve, plot=plot
  self.plots->add, plot
  
  dh_plot = obj_new('stx_detector_health_plot')
  dh_plot.plot, detector_monitor=detector_monitor, flare_flag=flare_flag, $
    start_time=reference_time, current_time=current_time, $
    dimensions=[1300,1300], position=[0.1,0.2,0.9,0.9]

  self.plots->add, dh_plot

  
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
    
  default, directory , getenv('STX_DET')
  default, og_filename, 'offset_gain_table.csv'
  default, eb_filename, 'EnergyBinning20150615.csv'
  
  stx_sim_create_elut, og_filename=og_filename, eb_filename=eb_filename, directory = directory
  
  stx_sim_create_ql_tc, self.conf
  
  get_lun,lun
  openw, lun, "test_custom.tcl"
  printf, lun, 'source D:\\Tools\\scripts\\procedures.tcl'
  printf, lun, 'syslog "running custom script for DH test"'
  printf, lun, '#source [file join [file dirname [info script]] "TC_???.tcl"]'
  free_lun, lun
  
   
  lc =  total(ql_lightcurve.counts,1)
  start = min(where(lc gt 100))
  self.t_shift = start

end


pro stx_fsw_dh__test__define
  compile_opt idl2, hidden

  void = { $
    stx_fsw_dh__test, $
    inherits stx_fsw__test }
end
