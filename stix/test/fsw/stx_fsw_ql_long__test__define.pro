;+
; :file_comments:
;   This is a test class for scenario-based testing; specifically the rate control regime
;
; :categories:
;   data simulation, flight software simulator, software, testing
;
; :examples:
;  iut_test_runner('stx_fsw_ql_long__test')
;
; :history:

;   06-jun-2018 - Nicky Hochmuth (FHNW) initial release
;-


function stx_fsw_ql_long__test::init, _extra=extra

  self.test_name = 'AX_QL_TEST'
  self.configuration_file = 'stx_flight_software_simulator_default.xml'
  setenv, 'WRITE_CALIBRATION_SPECTRUM=false'
  
  return, self->stx_fsw__test::init(_extra=extra)
end
 

pro stx_fsw_ql_long__test::test_has_lc
 
  self.tmtc_reader->getdata, asw_ql_lightcurve=lc_tm,  solo_packet=solo_packets
  assert_true, N_ELEMENTS(lc_tm) gt 1

end


pro stx_fsw_ql_long__test::test_has_bg

  self.tmtc_reader->getdata, asw_ql_background_monitor=bg_tm,  solo_packet=solo_packets
  assert_true, N_ELEMENTS(bg_tm) gt 1

end

pro stx_fsw_ql_long__test::test_has_var

  self.tmtc_reader->getdata, asw_ql_variance=var_tm,  solo_packet=solo_packets
  assert_true, N_ELEMENTS(var_tm) gt 1

end

pro stx_fsw_ql_long__test::test_has_sp

  self.tmtc_reader->getdata, fsw_m_ql_spectra=sp_tm  ,  solo_packet=solo_packets
  assert_true, N_ELEMENTS(sp_tm) gt 1

end


pro stx_fsw_ql_long__test::test_has_ffl

  self.tmtc_reader->getdata, asw_ql_flare_flag_location=ffl_tm,  solo_packet=solo_packets
  assert_true, N_ELEMENTS(ffl_tm) gt 1

end



pro stx_fsw_ql_long__test::beforeclass

  stx_sim_fsw_prep, self.test_name, self.sequence_name, configuration_file=self.configuration_file, seed=self.seed, test_root=self.test_root,$
    version=self.version, original_dir=self.original_dir, original_conf=self.original_conf, dss=dss, fsw=fsw, OFFSET_GAIN_TABLE=self.offset_gain_table, INIT_ONLY=1


  
  self.plots = list()
  self.show_plot = 1
  
  self.tmtc_reader = stx_telemetry_reader(filename = "ax_tmtc_long.bin", /scan_mode)
  self.tmtc_reader->getdata, statistics = statistics
  self.statistics = statistics



end


pro stx_fsw_ql_long__test__define
  compile_opt idl2, hidden

  void = { $
    stx_fsw_ql_long__test, $
    inherits stx_fsw__test }
end
