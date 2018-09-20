;+
;  :file_comments:
;    Test routine for the FSW QL data
;
;  :categories:
;    Flight Software, QL data, testing
;
;  :examples:
;    res = iut_test_runner('stx_fsw_QL_D1__test')
;
;  :history:
;    19-jan-2018 - Nicky Hochmuth (Ateleris), initial release
;   
;-

pro stx_fsw_ql_d1__test::test_light_curves_a_avaialable

  assert_true, self.statistics.HasKey('stx_tmtc_ql_light_curves')
  
  assert_equals, 1, n_elements(self.statistics['stx_tmtc_ql_light_curves'])
  
end


pro stx_fsw_ql_d1__test::test_light_curves_b_settings

 self.tmtc_reader->getdata, asw_ql_lightcurve=ql_lightcurves,  solo_packet=solo_packets
  
 sp = solo_packets["stx_tmtc_ql_light_curves",0,0]
 
 ql_lightcurve = ql_lightcurves[0]
 
 e_axis = ql_lightcurve.energy_axis
 t_axis = ql_lightcurve.time_axis
 
 qla = self.conf->get(module="stx_fsw_module_quicklook_accumulation")
 
 lc_a = (*self.ql_acc)[where((*self.ql_acc).ACCUMULATOR eq "lightcurve")]
 
 
 det_mask = bytarr(32) & det_mask[ *lc_a.det_index_list-1 ] = 1
 pix_mask = bytarr(12) & pix_mask[ *lc_a.pixel_index_list] = 1
 
 tmtc_c = self.conf->get(module="stx_fsw_module_tmtc")
 assert_equals,  stx_km_compression_params_to_schema(config=tmtc_c.QL_LIGHT_CURVES_COMPRESSION_COUNTS) , (*sp.source_data).COMPRESSION_SCHEMA_LIGHT_CURVES, "Compression schema for counts does not match"
 assert_equals,  stx_km_compression_params_to_schema(config=tmtc_c.QL_LIGHT_CURVES_COMPRESSION_TRIGGERS) , (*sp.source_data).COMPRESSION_SCHEMA_TRIGGER, "Compression schema for trigger does not match"

 
 assert_equals, qla.reset_frequency_stx_fsw_ql_lightcurve , t_axis.duration[0], "Integration Time does not match"

 assert_equals, n_elements(*lc_a.CHANNEL_BIN)-1, n_elements(e_axis.MEAN), "number energy bands does not match"

 assert_array_equals, *lc_a.CHANNEL_BIN , [ e_axis.LOW_FSW_IDX,  e_axis.HIGH_FSW_IDX[-1]+1], "energy bands does not match"

 assert_array_equals, pix_mask,  ql_lightcurve.pixel_mask, "pixel mask does not match"
 
 assert_array_equals, det_mask,  ql_lightcurve.detector_mask, "detector mask does not match"
 

end

pro stx_fsw_ql_d1__test::test_light_curves_c_data

  self.tmtc_reader->getdata, asw_ql_lightcurve=ql_lightcurves,  solo_packet=solo_packets

  sp = solo_packets["stx_tmtc_ql_light_curves",0,0]

  ql_lightcurve = ql_lightcurves[0]

  e_axis = ql_lightcurve.energy_axis
  t_axis = ql_lightcurve.time_axis

  qla = self.conf->get(module="stx_fsw_module_quicklook_accumulation")
  
  
  lc_plot_data = stx_construct_lightcurve(from=ql_lightcurve)
  
  if self.show_plot then begin
    lc_plot = obj_new('stx_plot')
    p = lc_plot.create_stx_plot(lc_plot_data, /lightcurve, /add_legend, title="Lightcurve Plot", ylog=0)
    self.plots->add, lc_plot
    if total(self.xrange) ne 0 then (lc_plot.plot_object()).XRANGE = self.xrange
  endif
  
  
  assert_true, n_elements(t_axis.duration) ge 25, "to less time bins"
  
  counts_per_e_range = [1365120UL,      276704UL,      273824,      279648,      822656,     2783232,     6841344,    27365376]
  
  assert_in_range, 43782144UL, total(ql_lightcurve.triggers, /pre), range=self.exepted_range, "total trigger count is not in range "  

  assert_in_range, total(counts_per_e_range, /pre), total(ql_lightcurve.COUNTS, /pre), range=self.exepted_range, "total counts is not in range "
  
  for i=0, n_elements(counts_per_e_range)-1 do begin
    assert_in_range, counts_per_e_range[i], (total(ql_lightcurve.counts,2,/pre))[i], range=self.exepted_range, "total counts in energy range ["+trim(i+1)+"]  is not in range "
  endfor
  
  

  
end




pro stx_fsw_ql_d1__test::test_variance_a_avaialable

  assert_true, self.statistics.haskey('stx_tmtc_ql_variance')

  assert_equals, 1, n_elements(self.statistics['stx_tmtc_ql_variance'])

end

pro stx_fsw_ql_d1__test::test_variance_b_settings

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

pro stx_fsw_ql_d1__test::test_variance_c_data

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

  assert_in_range, 61760000UL, total(variance.variance), range=self.exepted_range, "total variance is not in range "

end


pro stx_fsw_ql_d1__test::test_background_monitor_a_avaialable

  assert_true, self.statistics.haskey('stx_tmtc_ql_background_monitor')

  assert_equals, 1, n_elements(self.statistics['stx_tmtc_ql_background_monitor'])

end

pro stx_fsw_ql_d1__test::test_background_monitor_b_settings

 self.tmtc_reader->getdata, asw_ql_background=ql_backgrounds,  solo_packet=solo_packets
  
 sp = solo_packets["stx_tmtc_ql_background_monitor",0,0]
 ql_background = ql_backgrounds[0]

  e_axis = ql_background.energy_axis
  t_axis = ql_background.time_axis

  qla = self.conf->get(module="stx_fsw_module_quicklook_accumulation")
  
  bg_a = (*self.ql_acc)[where((*self.ql_acc).ACCUMULATOR eq "bkgd_monitor")]
  
  tmtc_c = self.conf->get(module="stx_fsw_module_tmtc")
  assert_equals,  stx_km_compression_params_to_schema(config=tmtc_c.QL_BACKGROUND_COMPRESSION_COUNTS) , (*sp.source_data).COMPRESSION_SCHEMA_BACKGROUND, "Compression schema for counts does not match"
  assert_equals,  stx_km_compression_params_to_schema(config=tmtc_c.QL_BACKGROUND_COMPRESSION_TRIGGERS) , (*sp.source_data).COMPRESSION_SCHEMA_TRIGGER, "Compression schema for trigger does not match"

  
  assert_equals, qla.reset_frequency_stx_fsw_ql_bkgd_monitor, t_axis.duration[0], "Integration Time does not match"

  assert_equals, n_elements(*bg_a.CHANNEL_BIN)-1, n_elements(e_axis.mean), "number energy bands does not match"

  assert_array_equals, *bg_a.CHANNEL_BIN , [ e_axis.LOW_FSW_IDX,  e_axis.HIGH_FSW_IDX[-1]+1], "energy bands does not match"
 


end

pro stx_fsw_ql_d1__test::test_background_monitor_c_data

  self.tmtc_reader->getdata, asw_ql_background=ql_backgrounds,  solo_packet=solo_packets

  sp = solo_packets["stx_tmtc_ql_background_monitor",0,0]
  ql_background = ql_backgrounds[0]

  e_axis = ql_background.energy_axis
  t_axis = ql_background.time_axis

  qla = self.conf->get(module="stx_fsw_module_quicklook_accumulation")

  bg_a = (*self.ql_acc)[where((*self.ql_acc).accumulator eq "bkgd_monitor")]

  tmtc_c = self.conf->get(module="stx_fsw_module_tmtc")
    
  if self.show_plot then begin
    lc_plot_data = stx_construct_lightcurve(from=ql_background)
    lc_plot = obj_new('stx_plot')
    p = lc_plot.create_stx_plot(lc_plot_data, /background, /add_legend, title="background monitor plot", ylog=0)
    self.plots->add, lc_plot
    
    if total(self.xrange) ne 0 then (lc_plot.plot_object()).XRANGE = self.xrange
    
  endif
  
  assert_true, n_elements(t_axis.duration) ge 3, "to less time bins"

  counts_per_e_range = [38656UL,        8032UL,        7712,        7776,       23168,       77312,      193536,      774144]

  assert_in_range, 2670592UL, total(ql_background.triggers), range=self.exepted_range, "total trigger count is not in range "

  assert_in_range, total(counts_per_e_range, /pre), total(ql_background.BACKGROUND, /pre), range=self.exepted_range, "total counts is not in range "

  for i=0, n_elements(counts_per_e_range)-1 do begin
    assert_in_range, counts_per_e_range[i], (total(ql_background.BACKGROUND,2))[i], range=self.exepted_range, "total counts in energy range ["+trim(i+1)+"]  is not in range "
  endfor

end


pro stx_fsw_ql_d1__test::test_spectra_a_avaialable

  assert_true, self.statistics.haskey('stx_tmtc_ql_spectra')

  assert_equals, 1, n_elements(self.statistics['stx_tmtc_ql_spectra'])

end

pro stx_fsw_ql_d1__test::test_spectra_b_settings

  self.tmtc_reader->getdata, stx_asw_ql_spectra = ql_spectras_asw, solo_packets=solo_packets

  sp = solo_packets["stx_tmtc_ql_spectra",0,0]
  
  ql_spectra_asw = ql_spectras_asw[0]
  

  e_axis = ql_spectra_asw.energy_axis
  t_axis = ql_spectra_asw.time_axis

  qla = self.conf->get(module="stx_fsw_module_quicklook_accumulation")

  sp_a = (*self.ql_acc)[where((*self.ql_acc).accumulator eq "spectra")]
  
  pix_mask = bytarr(12) & pix_mask[ *sp_a.pixel_index_list] = 1
  
  tmtc_c = self.conf->get(module="stx_fsw_module_tmtc")
  assert_equals,  stx_km_compression_params_to_schema(config=tmtc_c.QL_SPECTRA_COMPRESSION_COUNTS) , (*sp.source_data).COMPRESSION_SCHEMA_SPECTRUM, "Compression schema for counts does not match"
  assert_equals,  stx_km_compression_params_to_schema(config=tmtc_c.QL_SPECTRA_COMPRESSION_TRIGGERS) , (*sp.source_data).COMPRESSION_SCHEMA_TRIGGER, "Compression schema for trigger does not match"

  assert_equals, qla.RESET_FREQUENCY_STX_FSW_QL_SPECTRA, t_axis.duration[0], "Integration Time does not match"

  assert_equals, n_elements(*sp_a.channel_bin)-1, n_elements(e_axis.mean), "number energy bands does not match"

  assert_array_equals, *sp_a.channel_bin , [ e_axis.low_fsw_idx,  e_axis.high_fsw_idx[-1]+1], "energy bands does not match"
  
  assert_array_equals, pix_mask, ql_spectra_asw.pixel_mask, "pixel mask does not match"

end

pro stx_fsw_ql_d1__test::test_spectra_c_data

  self.tmtc_reader->getdata, stx_asw_ql_spectra = ql_spectras_asw, solo_packets=solo_packets

  sp = solo_packets["stx_tmtc_ql_spectra",0,0]

  ql_spectra_asw = ql_spectras_asw[0]
  
  
  ;align times if needed
  ;a time bin is 4 seconds but the first time in the next TM packed does not necessarily start 4seconds later but 4seconds + some computational time offset 
  ; so that offset could sum up to flip into a full 4 second shift
  
  
  detMask = total(ql_spectra_asw.detector_mask,1, /pre)
  
  SPECTRUM = list()
  TRIGGERS = list()
  DETECTOR_MASK = list()
  
  n_merges = 0
  for bi=0, n_elements(detMask)-1 do begin
    
    SPECTRUM->add, ql_spectra_asw.SPECTRUM[*,*,bi]
    TRIGGERS->add, ql_spectra_asw.TRIGGERS[*,bi]
    DETECTOR_MASK->add, ql_spectra_asw.DETECTOR_MASK[*,bi]
    
    if bi lt n_elements(detMask)-1 then begin
      if detMask[bi] + detMask[bi+1] eq 32 then begin
        n_merges++;
        
        SPECTRUM[-1]+=ql_spectra_asw.spectrum[*,*,bi+1]
        TRIGGERS[-1]+=ql_spectra_asw.triggers[*,bi+1]
        DETECTOR_MASK[-1]+=ql_spectra_asw.detector_mask[*,bi+1]
        
        bi++
      endif
    endif
  endfor
      
     
   if n_merges gt 0 then begin
    t_axis = stx_construct_time_axis(time_axis = ql_spectra_asw.time_axis, idx=indgen(n_elements(detMask)-n_merges))
    
    ql_spectra_asw = stx_construct_asw_ql_spectra($
        time_axis = t_axis, $
        pixel_mask = ql_spectra_asw.pixel_mask, $
        energy_axis = ql_spectra_asw.energy_axis, $
        detector_mask = DETECTOR_MASK->toarray(/transpose) ,$
        spectrum= SPECTRUM->toarray(/transpose) ,$
        triggers= TRIGGERS->toarray(/transpose) $                        
     )
    
    
    
   endif
    

  e_axis = ql_spectra_asw.energy_axis
  t_axis = ql_spectra_asw.time_axis
  
 

  qla = self.conf->get(module="stx_fsw_module_quicklook_accumulation")

  sp_a = (*self.ql_acc)[where((*self.ql_acc).accumulator eq "spectra")]

  pix_mask = bytarr(12) & pix_mask[ *sp_a.pixel_index_list] = 1

  tmtc_c = self.conf->get(module="stx_fsw_module_tmtc")
  
  
  assert_true, n_elements(t_axis.duration) ge 25, "to less time bins"
  
  assert_in_range, 40293637UL, total(ql_spectra_asw.spectrum, /pre), range=self.exepted_range, "total counts is not in range "

  assert_in_range, 87758336UL, total(ql_spectra_asw.triggers), range=self.exepted_range,  "total trigger count is not in range "

  
  ;find the first spike in time 
  
  spike_factor = 0.75
   
  spike_time_offset = -1 
  
  ;spectrum[energy,detetctor,time]
  
  spikes = *self.spikes
  
  
  
  for t_idx=0,  n_elements(t_axis.duration)-1 do begin
    e_idx = value_locate(e_axis.edges_1,spikes[0].ENERGY_SPECTRUM_PARAM1)
    d_idx = spikes[0].DETECTOR_OVERRIDE - 1
    
    if (long64(ql_spectra_asw.spectrum[e_idx,d_idx,t_idx]) - long64(ql_spectra_asw.spectrum[e_idx,d_idx-1,t_idx])) gt spikes[0].flux   then begin
      spike_time_offset = t_idx
      break;
    endif
  endfor
  
  ;test if all spikes match with at relative time
  
  assert_true, spike_time_offset ge 0, "no spike found for detector 2"
  
  
  spectra_plot = obj_new('stx_spectra_plot')
  
  foreach spike, spikes, spikes_idx do begin
    e_idx = value_locate(e_axis.edges_1,spike.energy_spectrum_param1)
    d_idx = spike.detector_override - 1
    t_idx = fix(spike.START_TIME) / qla.reset_frequency_stx_fsw_ql_spectra + spike_time_offset
     
    
    if self.show_plot then begin
      
      spectra_plot.plot, ql_spectra_asw.spectrum[*,*,t_idx], where(ql_spectra_asw.DETECTOR_MASK[*,t_idx] ge 1), current_time=t_axis.time_start[t_idx], duration=qla.reset_frequency_stx_fsw_ql_spectra, /add_legend
      t = text(e_idx,spike.flux, ['expected spike at ', 'd: '+trim(d_idx+1),"e: "+trim(e_idx)] , /data)
      
    endif
       
    assert_true, (long64(ql_spectra_asw.spectrum[e_idx,d_idx,t_idx]) - long64(ql_spectra_asw.spectrum[e_idx,d_idx-1,t_idx])) gt spike.flux / 1.5 $
       OR        (long64(ql_spectra_asw.spectrum[e_idx,d_idx,t_idx-1]) - long64(ql_spectra_asw.spectrum[e_idx,d_idx-1,t_idx-1])) gt spike.flux / 1.5, "spike mismatch for spike_id: "+trim(spike.SOURCE_SUB_ID)
      
  endforeach
  
  self.plots->add, spectra_plot
  
  
  
end


pro stx_fsw_ql_d1__test::test_calibration_spectrum_a_avaialable

  assert_true, self.statistics.haskey('stx_tmtc_ql_calibration_spectrum')

  assert_equals, 1, n_elements(self.statistics['stx_tmtc_ql_calibration_spectrum'])

end

pro stx_fsw_ql_d1__test::test_calibration_spectrum_b_settings

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


pro stx_fsw_ql_d1__test::test_calibration_spectrum_c_data

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

  foreach spike, spikes, spikes_idx do begin
     
    ad_idx_low = stx_sim_energy_2_pixel_ad(spike.ENERGY_SPECTRUM_PARAM1,spike.detector_override, spike.PIXEL_OVERRIDE-1)
    ad_idx_high = stx_sim_energy_2_pixel_ad(spike.ENERGY_SPECTRUM_PARAM2,spike.detector_override, spike.PIXEL_OVERRIDE-1)
    
    ad_idx_low = ishft(ad_idx_low, -2)
    ad_idx_high = ishft(ad_idx_high, -2)
    
    ;print, (mean(compacted_spectra[spike.PIXEL_OVERRIDE-1,ad_idx_low:ad_idx_high]) - mean(compacted_spectra[spike.PIXEL_OVERRIDE-1,mean_range[0]:mean_range[1]])), (spike.flux / 1.5)
    
    spike_count = mean(compacted_spectra[spike.PIXEL_OVERRIDE-1,ad_idx_low:ad_idx_high])
    
    t = arrow([ad_idx_low,ad_idx_low],[spike_count,spike_count + 200 ], /data)
    
    assert_true, (spike_count - mean(compacted_spectra[spike.PIXEL_OVERRIDE-1,mean_range[0]:mean_range[1]])) gt (spike.flux / 2) , "spike mismatch for spike_id: "+trim(spike.source_sub_id)

  endforeach
  
  
  
end


pro stx_fsw_QL_D1__test::beforeclass

  path = "D:\Temp\v20170123\AX_QL_TEST_1\" 
  
  restore, filename=concat_dir(path, "fsw_conf.sav"), /verb
  
  self.conf = confManager
  ;fsw-simulator: ql_tmtc.bin
  ;AX: D1-2_AX_20180321_1400.bin
  self.tmtc_reader = stx_telemetry_reader(filename = concat_dir(path, "D1-2_AX_20180321_1400.bin"), /scan_mode, /merge_mode)
  self.tmtc_reader->getdata, statistics = statistics
  self.statistics = statistics
  self.xrange = [220,400]
  
  
  self.ql_acc = ptr_new(stx_fsw_ql_accumulator_table2struct(concat_dir(path, "stix_conf\qlook_accumulators.csv")))
  
  self.exepted_range = 0.05
  self.plots = list()
  self.show_plot = 0
  s = stx_sim_read_scenario(scenario_file=concat_dir(path, "D1-2\D1-2.csv"),out_bkg_str=sc)
  
  self.spikes = ptr_new(sc[where(sc.DURATION lt 1)])
  
  v = stx_offset_gain_reader("offset_gain_table.csv", directory = concat_dir(path, "stix_conf\") , /reset)
   
end


;+
; cleanup at object destroy
;-
pro stx_fsw_QL_D1__test::afterclass
  v = stx_offset_gain_reader(/reset)
  destroy, self.tmtc_reader
end

;+
; cleanup after each test case
;-
pro stx_fsw_QL_D1__test::after


end

;+
; init before each test case
;-
pro stx_fsw_QL_D1__test::before


end


;+
; Define instance variables.
;-
pro stx_fsw_QL_D1__test__define
  compile_opt idl2, hidden

  define = { stx_fsw_QL_D1__test, $
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

