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

  path = "D:\Temp\v20170123\AX_SD_TEST_AB\" 
  
  restore, filename=concat_dir(path, "fsw_conf.sav"), /verb
  
  self.conf = confManager
  ;fsw-simulator: ql_tmtc.bin
  ;AX: D1-2_AX_20180323_1330.bin
  self.tmtc_reader = stx_telemetry_reader(filename = concat_dir(path, "ql_tmtc.bin"), /scan_mode, /merge_mode)
  self.tmtc_reader->getdata, statistics = statistics
  self.statistics = statistics
  self.exepted_range = 0.30
  self.plots = list()
  self.show_plot = 1
  v = stx_offset_gain_reader("offset_gain_table.csv", directory = concat_dir(path, "stix_conf\") , /reset)
   
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
    conf : obj_new(), $
    tmtc_reader : obj_new(), $
    spec : ptr_new(), $
    trig : ptr_new(), $
    statistics : list(), $
    exepted_range: 0.0d, $
    plots : list(), $
    show_plot : 0b, $
    inherits iut_test }
end

