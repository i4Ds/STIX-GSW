;+
;  :file_comments:
;    Test routine for the FSW QL data
;
;  :categories:
;    Flight Software, QL data, testing
;
;  :examples:
;    res = iut_test_runner('stx_fsw_ql_d1_low__test')
;
;  :history:
;    19-jan-2018 - Nicky Hochmuth (Ateleris), initial release
;   
;-


pro stx_fsw_ql_d1_low__test::test_variance_a_avaialable

  assert_true, self.statistics.haskey('stx_tmtc_ql_variance')

  assert_equals, 1, n_elements(self.statistics['stx_tmtc_ql_variance'])

end

pro stx_fsw_ql_d1_low__test::test_variance_b_settings

  self.tmtc_reader->getdata, asw_ql_variance  = variance_blocks, solo_packet=solo_packets

  sp = solo_packets["stx_tmtc_ql_variance",0,0]
  
  variance = variance_blocks[0]


  t_axis = variance.time_axis

  qla = self.conf->get(module="stx_fsw_module_quicklook_accumulation")
  va_c = self.conf->get(module="stx_fsw_module_variance_calculation")

  va_a = (*self.ql_acc)[where((*self.ql_acc).accumulator eq "variance")]


  det_mask = bytarr(32) & det_mask[ *va_a.det_index_list-1 ] = 1
  pix_mask = bytarr(12) & pix_mask[ *va_a.pixel_index_list] = 1
  
  tmtc_c = self.conf->get(module="stx_fsw_module_tmtc")
  assert_equals,  stx_km_compression_params_to_schema(config=tmtc_c.QL_VARIANCE_SPECTRUM_COMPRESSION_COUNTS) , (*sp.source_data).COMPRESSION_SCHEMA_ACCUM, "Compression schema for counts does not match"

  
  assert_equals, qla.RESET_FREQUENCY_STX_FSW_QL_VARIANCE , t_axis.duration[0], "Integration Time does not match"
  
  assert_array_equals, *va_a.channel_bin , [min(where(variance.energy_mask eq 1)),  max(where(variance.energy_mask eq 1))+1], "energy bands does not match"

  assert_array_equals, pix_mask,  variance.pixel_mask, "pixel mask does not match"

  assert_array_equals, det_mask,  variance.detector_mask, "detector mask does not match"


  assert_equals, va_c.NO_VAR,  variance.SAMPLES_PER_VARIANCE, "SAMPLES PER VARIANCE does not match"


end

pro stx_fsw_ql_d1_low__test::test_variance_c_data

  self.tmtc_reader->getdata, asw_ql_variance  = variance_blocks, solo_packet=solo_packets

  sp = solo_packets["stx_tmtc_ql_variance",0,0]

  variance = variance_blocks[0]


  t_axis = variance.time_axis

  qla = self.conf->get(module="stx_fsw_module_quicklook_accumulation")
  va_c = self.conf->get(module="stx_fsw_module_variance_calculation")
  va_a = (*self.ql_acc)[where((*self.ql_acc).accumulator eq "variance")]

  if self.show_plot then begin
    var_plot = stx_line_plot()
    a = var_plot._plot(stx_time_diff(variance.time_axis.time_start[0], variance.time_axis.time_start, /abs), variance.variance, names=["variance"], /add_legend, ylog=0)
    self.plots->add, var_plot
    
    if total(self.xrange) ne 0 then (*a).XRANGE = self.xrange
  endif
  
  assert_true, n_elements(t_axis.duration) ge 25, "to less time bins"

  assert_in_range, 1688UL, total(variance.variance, /pre), range=self.exepted_range, "total variance is not in range "

end


pro stx_fsw_ql_d1_low__test::test_calibration_spectrum_a_avaialable

  assert_true, self.statistics.haskey('stx_tmtc_ql_calibration_spectrum')

  assert_equals, 1, n_elements(self.statistics['stx_tmtc_ql_calibration_spectrum'])

end

pro stx_fsw_ql_d1_low__test::test_calibration_spectrum_b_settings

  self.tmtc_reader->getdata, asw_ql_calibration_spectrum=calibration_spectra, solo_packet=solo_packets
  
  sp = solo_packets["stx_tmtc_ql_calibration_spectrum",0,0]
 
  calibration_spectrum = calibration_spectra[0]
  
  tmtc_c = self.conf->get(module="stx_fsw_module_tmtc")

  assert_equals, n_elements(tmtc_c.CALIBRATION_SUBSPECTRA)/3, n_elements( calibration_spectrum.subspectra), "number of sub spectra does not match"

  for i=0, n_elements( calibration_spectrum.subspectra)-1 do begin
    assert_equals, tmtc_c.CALIBRATION_SUBSPECTRA[0,i] , calibration_spectrum.subspectra[i].LOWER_ENERGY_BOUND_CHANNEL , "LOWER_ENERGY_BOUND_CHANNEL of sub spectra "+ trim(i) +" does not match"
    assert_equals, tmtc_c.calibration_subspectra[1,i] , calibration_spectrum.subspectra[i].NUMBER_OF_SUMMED_CHANNELS , "NUMBER_OF_SUMMED_CHANNELS of sub spectra "+ trim(i) +" does not match"
    assert_equals, tmtc_c.calibration_subspectra[2,i] , calibration_spectrum.subspectra[i].NUMBER_OF_SPECTRAL_POINTS , "NUMBER_OF_SPECTRAL_POINTS of sub spectra "+ trim(i) +" does not match"
  endfor
  
  assert_equals,  stx_km_compression_params_to_schema(config=tmtc_c.QL_CALIBRATION_SPECTRUM_COMPRESSION_COUNTS) , (*sp.source_data).COMPRESSION_SCHEMA, "Compression schema for counts does not match"


end


pro stx_fsw_ql_d1_low__test::test_calibration_spectrum_c_data

  self.tmtc_reader->getdata, asw_ql_calibration_spectrum=calibration_spectra, solo_packet=solo_packets

  sp = solo_packets["stx_tmtc_ql_calibration_spectrum",0,0]

  calibration_spectrum = calibration_spectra[0]

  tmtc_c = self.conf->get(module="stx_fsw_module_tmtc")
  if self.show_plot then begin
    cs_plot = stx_energy_calibration_spectrum_plot()
    cs_plot->plot2, calibration_spectrum, /add_legend, title="Energy Calibration Spectra", out_compacted_spectra=compacted_spectra
     self.plots->add, cs_plot
  endif
  
  
  mean_range = [400,600] 
  
  
  spikes = *self.spikes
  
  matched_spikes = INTARR(N_ELEMENTS(spikes)) 

  foreach spike, spikes, spikes_idx do begin
     
    ad_idx_low = stx_sim_energy_2_pixel_ad(spike.ENERGY_SPECTRUM_PARAM1,spike.detector_override, spike.PIXEL_OVERRIDE-1)
    ad_idx_high = stx_sim_energy_2_pixel_ad(spike.ENERGY_SPECTRUM_PARAM2,spike.detector_override, spike.PIXEL_OVERRIDE-1)
    
    ad_idx_low = ishft(ad_idx_low, -2)
    ad_idx_high = ishft(ad_idx_high, -2) + 1
    
      
    spike_count = mean(compacted_spectra[spike.PIXEL_OVERRIDE-1,ad_idx_low:ad_idx_high])
    
    print, spike_count, mean(compacted_spectra[spike.PIXEL_OVERRIDE-1,mean_range[0]:mean_range[1]])
    
    t = arrow([ad_idx_low,ad_idx_low],[spike_count,spike_count + 200 ], /data)
    
    matched_spikes[spikes_idx] += (spike_count - mean(compacted_spectra[spike.PIXEL_OVERRIDE-1,mean_range[0]:mean_range[1]])) gt (spike.flux / 2)

  endforeach
  
  
   assert_true, total(matched_spikes) gt N_ELEMENTS(spikes)-3, "to many spike mismatches: "+trim(matched_spikes)
  
  
end


pro stx_fsw_ql_d1_low__test::beforeclass

  path = "D:\Temp\v20170123\AX_QL_TEST_1_low\" 
  
  restore, filename=concat_dir(path, "fsw_conf.sav"), /verb
  
  self.conf = confManager
  ;fsw-simulator: ql_tmtc.bin
  ;AX: D1-2_AX_20180323_1330.bin
  self.tmtc_reader = stx_telemetry_reader(filename = concat_dir(path, "ql_tmtc.bin"), /scan_mode, /merge_mode)
  self.tmtc_reader->getdata, statistics = statistics
  self.statistics = statistics
  ;self.xrange = [80,220]
  
  
  self.ql_acc = ptr_new(stx_fsw_ql_accumulator_table2struct(concat_dir(path, "stix_conf\qlook_accumulators.csv")))
  
  self.exepted_range = 0.30
  self.plots = list()
  self.show_plot = 1
  s = stx_sim_read_scenario(scenario_file=concat_dir(path, "D1-2_low\D1-2_low.csv"),out_bkg_str=sc)
  
  self.spikes = ptr_new(sc[where(sc.DURATION lt 1)])
  
  v = stx_offset_gain_reader("offset_gain_table.csv", directory = concat_dir(path, "stix_conf\") , /reset)
   
end


;+
; cleanup at object destroy
;-
pro stx_fsw_ql_d1_low__test::afterclass
  v = stx_offset_gain_reader(/reset)
  destroy, self.tmtc_reader
end

;+
; cleanup after each test case
;-
pro stx_fsw_ql_d1_low__test::after


end

;+
; init before each test case
;-
pro stx_fsw_ql_d1_low__test::before


end


;+
; Define instance variables.
;-
pro stx_fsw_ql_d1_low__test__define
  compile_opt idl2, hidden

  define = { stx_fsw_ql_d1_low__test, $
    ql_acc : ptr_new(), $
    conf : obj_new(), $
    tmtc_reader : obj_new(), $
    statistics : list(), $
    exepted_range: 0.0d, $
    xrange: [0d,0d], $
    plots : list(), $
    spikes : ptr_new(), $
    show_plot : 0b, $
    inherits iut_test }
end

