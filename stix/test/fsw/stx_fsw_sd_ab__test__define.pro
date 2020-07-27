;+
;  :file_comments:
;    Test routine for the FSW QL data
;
;  :categories:
;    Flight Software, QL data, testing
;
;  :examples:
;    res = iut_test_runner('stx_fsw_sd_ab__test')
;
;  :history:
;    19-jan-2018 - Nicky Hochmuth (Ateleris), initial release
;   
;-

function stx_fsw_sd_ab__test::init, _extra=extra
  
  res = self->stx_fsw__test::init(_extra=extra)
  
  self.sequence_name = 'AB'
  self.test_name = 'AX_SD_TEST_AB'
  self.configuration_file = 'stx_flight_software_simulator_d1_2.xml'
  self.offset_gain_table = "offset_gain_table.csv"
  setenv, 'WRITE_CALIBRATION_SPECTRUM=false'

  return, res
end

pro stx_fsw_sd_ab__test::test_ab_a_avaialable

  assert_true, self.statistics.haskey('stx_tmtc_sd_xray_0')

  assert_equals, 1, n_elements(self.statistics['stx_tmtc_sd_xray_0'])

end

pro stx_fsw_sd_ab__test::test_ab_b_settings

  self.tmtc_reader->getdata, fsw_archive_buffer_time_group = ab_blocks, solo_packet=solo_packets

  sp = solo_packets["stx_tmtc_sd_xray_0",0,0]
  
  ab = ab_blocks[0]
  
  energy_axis = stx_construct_energy_axis()
  
  asw_data = stx_convert_fsw_archive_buffer_time_group_to_asw(ab, energy_axis=energy_axis, datasource="TMTC")

  tot_over_time = total(total(total(asw_data.SPEC,1, /pre),1, /pre),1, /pre)
  
  trim = where(tot_over_time eq 0, c_trim)
  
  spec = asw_data.SPEC
  trig = asw_data.TRIGGERS
  
  if c_trim gt 0 then begin
    spec=spex[*,*,*,trim]
    trig = trig[trim,*]
  endif
  
  tot_over_time = total(total(total(spec,1, /pre),1, /pre),1, /pre)
  
  n_times = n_elements(tot_over_time)
  
  self.trig = ptr_new(trig)
  self.spec = ptr_new(spec)
  
  assert_true, n_times eq 1536 OR n_times eq 1537, "not correct number of time bins"
  
  assert_in_range, 61048UL, total(tot_over_time, /pre), range=self.exepted_range, "total counts are not in range "
  
  assert_in_range, 196949UL, total(trig, /pre), range=self.exepted_range, "total triggers are not in range "


end

pro stx_fsw_sd_ab__test::test_ab_c_adressing

  trig = *self.trig
  spec = *self.spec
  
  
  ;spec : [energy,pixel,detector,time]
  
  n_t = (size(trig, /dim))[0]
  
  skip = 2
  
  for t=0, n_t-1 do begin
    t_coll = spec[*,*,*,t]
         
    d_tc = total(total(t_coll,1,/pre), 1,/pre)
    v = max(d_tc,d)
    
    p_tc = total(total(t_coll,1,/pre), 2,/pre)
    v = max(p_tc,p)
    
    e_tc = total(total(t_coll,2,/pre), 2,/pre)
    v = max(e_tc,e)
    
    
    p_ex = (t mod (12/skip)) * skip
    d_ex = ((t/(12/skip/skip) mod 32) / skip)*skip
    e_ex = ((t / (12*32/skip/skip)) * skip) mod 32
    
    
    ;IF NOT ARRAY_EQUAL([d_ex,p_ex,e_ex], [d,p,e]) THEN begin
    ;  print, d, d_ex, p, p_ex, e, e_ex
    ;ENDIF
    
    assert_array_equals, [d_ex,p_ex,e_ex], [d,p,e], "not expected adressing found at t: "+trim(t)
    
  endfor
  
  
end





pro stx_fsw_sd_ab__test::beforeclass
  
  self->stx_fsw__test::beforeclass
  
  self.exepted_range = 0.05
  self.plots = list()
  self.show_plot = 1
 
    
  self.fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  
  ;lc =  total(lightcurve.accumulated_counts,1)
  ;start = min(where(lc gt 100))
  ;peak = max(lc[start:start+3], peak_idx)
  ;self.t_shift_sim = start+peak_idx
  
  self.t_shift_sim = 0
  
  stx_plot, lightcurve, plot=plot
  self.plots->add, plot
  
  if ~file_exist('ax_tmtc.bin') then begin
    tmtc_data = {$
      QL_LIGHT_CURVES : 1,$
      sd_xray_0: 1 ,$
      rel_flare_time : [0d,total(lightcurve.TIME_AXIS.duration)]$
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
  
  stx_sim_create_fpp_tc, self.conf
  
  get_lun,lun
  openw, lun, "test_custom.tcl"
  printf, lun, 'syslog "running custom script for SD-AB test"'
  printf, lun, 'source [file join [file dirname [info script]] "TC_237_13_FPP.tcl"]'
  free_lun, lun
  
  
  get_lun,lun
  openw, lun, "reqeust_data_l0.tcl"
  printf, lun, 'source D:\\Tools\\scripts\\procedures.tcl'
  printf, lun, '# PIX00072 is the start time '
  
  printf, lun, 'execTC "ZIX38001 {PIX00076 123} {PIX00070 0} {PIX00072 SET_TIME_HERE} {PIX00073 0} {PIX00248 4294967295} {PIX00071 2} {PIX00077 0} {PIX00078 200} {PIX00079 1} {PIX00200 0} {PIX00201 31} {PIX00202 1} {PIX00077 200} {PIX00078 400} {PIX00079 10} {PIX00200 0} {PIX00201 16} {PIX00202 2}"'
  free_lun, lun
  
  get_lun,lun
  openw, lun, "reqeust_data_l1.tcl"
  printf, lun, 'source D:\\Tools\\scripts\\procedures.tcl'
  printf, lun, '# PIX00072 is the start time '
  printf, lun, 'execTC "ZIX38001 {PIX00076 123} {PIX00070 1} {PIX00072 SET_TIME_HERE} {PIX00073 0} {PIX00248 4294967295} {PIX00071 2} {PIX00077 0} {PIX00078 200} {PIX00079 1} {PIX00200 0} {PIX00201 31} {PIX00202 1} {PIX00077 200} {PIX00078 400} {PIX00079 10} {PIX00200 0} {PIX00201 16} {PIX00202 2}"'
  free_lun, lun
   
  ;lc =  total(ql_lightcurve.counts,1)
  ;start = min(where(lc gt 100))
  ;peak = max(lc[start:start+3], peak_idx)
  ;self.t_shift = start+peak_idx
  self.t_shift = min(where(total(ql_lightcurve.counts,1) ge 0))

end


;+
; cleanup at object destroy
;-
pro stx_fsw_sd_ab__test::afterclass
  v = stx_offset_gain_reader(/reset)
  destroy, self.tmtc_reader
end

;+
; cleanup after each test case
;-
pro stx_fsw_sd_ab__test::after


end

;+
; init before each test case
;-
pro stx_fsw_sd_ab__test::before


end


;+
; Define instance variables.
;-
pro stx_fsw_sd_ab__test__define
  compile_opt idl2, hidden

  define = { stx_fsw_sd_ab__test, $
      trig : ptr_new(), $
      spec : ptr_new(), $
      inherits stx_fsw__test }
end

