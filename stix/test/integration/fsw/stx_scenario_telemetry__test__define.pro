;+
; :file_comments:
;   This is a test class for scenario-based testing; specifically the variance calculation test
;
; :categories:
;   data simulation, flight software simulator, software, testing
;
; :examples:
;  res = iut_test_runner('stx_scenario_telemetry__test', keep_detector_eventlist=0b, show_fsw_plots=0b)
;  res = iut_test_runner('stx_scenario_telemetry__test')
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
function stx_scenario_telemetry__test::init, _extra=extra
  self.test_name = 'telemetry'
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
pro stx_scenario_telemetry__test::test_lightcurve
  
  filename = filepath("lightcurve.tel.bin",root_dir=self.test_output_dir) 
  
  self.fsw->getproperty, stx_fsw_m_lightcurve=lc_in, /COMPLETE, /comb
  
  tmtc_writer = stx_telemetry_writer(filename=filename, size=2L^24)
  
  tmtc_writer->setdata, ql_lightcurve=lc_in, solo_slices=solo_slices
  ; write to disk
  tmtc_writer->flushtofile
  destroy, tmtc_writer
    
  tmtc_reader = stx_telemetry_reader(filename=filename)
  tmtc_reader->getdata, asw_ql_lightcurve = lc_out, statistics=statistics, solo_packets=sp
  
  blocks = sp['stx_telemetry_packet_structure_ql_light_curves']
  
  lc_out = lc_out[0]
  
  assert_equals, lc_out.TIME_AXIS.duration, lc_in.TIME_AXIS.duration, "time axes durations do not match"
      
  assert_equals, size(lc_out.counts, /dimensions), size(lc_in.accumulated_counts, /dimensions), "count dimensions do not match"
  
  assert_true, stx_km_compress_test(lc_in.accumulated_counts, lc_out.counts, /all, schema=(*blocks[0,0].source_data).compression_schema_light_curves), "counts do not match the tollerated compression boundaries"
  
  assert_true, stx_km_compress_test(lc_in.triggers, lc_out.triggers, /all, schema=(*blocks[0,0].SOURCE_DATA).COMPRESSION_SCHEMA_TRIGGER), "trigger counts do not match the tollerated compression boundaries"
  
  assert_equals, lc_in.energy_axis.EDGES_2, lc_out.energy_axis.EDGES_2, "Energy axes do not match"
  
  assert_equals, stx_telemetry_util_get_length(blocks), tmtc_reader.filesize, "FileSize does not match DataSize"
  
  destroy, tmtc_reader
    
  
end


pro stx_scenario_telemetry__test__define
  compile_opt idl2, hidden
  
  void = { $
    stx_scenario_telemetry__test, $
    inherits stx_scenario_test }
end
