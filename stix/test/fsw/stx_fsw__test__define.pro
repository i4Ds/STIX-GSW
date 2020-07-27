;+
; :file_comments:
;   This is a test class for scenario-based testing on AX
;
; :categories:
;   data simulation, flight software simulator, software, testing
;
; :examples:
;  iut_test_runner('stx_fsw__test')
;
; :history:

;   08-jun-2018 - Nicky Hochmuth (FHNW) initial release
;-




function stx_fsw__test::init, plot=plot, _extra=extra
  default, plot, 0
  self.version = 'v20170123' ;time2file(trim(ut_time(/to_local)), /seconds)
  self.seed = 1337
  self.test_root = 'D:\Temp'
  self.t_l = 1.35d-6
  self.t_r = 9.91d-6
  self.t_ig = 0.35d-6
  self.offset_gain_table = ""
  self.show_plot = plot
  return, 1
end



pro stx_fsw__test::beforeclass
  
 
  stx_sim_fsw_prep, self.test_name, self.sequence_name, configuration_file=self.configuration_file, seed=self.seed, test_root=self.test_root,$
    version=self.version, original_dir=self.original_dir, original_conf=self.original_conf, dss=dss, fsw=fsw, OFFSET_GAIN_TABLE=self.offset_gain_table 
    
  
  dssevs_file = self.test_name + '.dssevs';
  
  if ~file_exist(dssevs_file) then begin
    ;generate the DSS events for hardware testing
    tb = dss->getdata(output_target='scenario_length', scenario=self.sequence_name) / 4L  + 1
    eventlist = dss->getdata(output_target='stx_sim_detector_eventlist', time_bins=[0L,long(tb)], scenario=self.sequence_name, rate_control_regime=0, t_l=self.t_l, t_r=self.t_r, t_ig=self.t_ig)
    stx_sim_dss_events_writer, dssevs_file , eventlist.detector_events, constant=1850
  end 
  
  if ~file_exist("fsw.sav") then begin
    stx_sim_fsw_run, dss, fsw, self.test_name, self.sequence_name, t_l=self.t_l, t_r=self.t_r, t_ig=self.t_ig
    save, dss, fsw, filename=self.test_name + '_dss-fsw.sav'
    save, fsw, filename="fsw.sav"
    
    confManager = fsw->getconfigmanager()
    save, confManager, filename="fsw_conf.sav"

  endif else begin
    restore, filename="fsw_conf.sav", /verb
    restore, filename="fsw.sav", /verb
  endelse
  
  self.conf = confManager
  self.fsw    = fsw
 
  file_copy, concat_dir(getenv('SSW_STIX'), 'idl/sim/fsw_testing/configureAX.tcl'), '.', /overwrite 
  
  self.plots = list()

  
end


;+
; cleanup at object destroy
;-
pro stx_fsw__test::afterclass
  v = stx_offset_gain_reader(/reset)

  ; restore original setting
  setenv, 'STX_CONF=' + self.original_conf
  cd, self.original_dir
  
  destroy, self.tmtc_reader
end


pro stx_fsw__test__define
  compile_opt idl2, hidden

  void = { $
    stx_fsw__test, $
    fsw    : obj_new(), $
    conf : obj_new(), $
    original_dir : "", $
    original_conf : "", $
    tmtc_reader : obj_new(), $
    statistics : list(), $
    exepted_range: 0.0d, $
    plots : list(), $
    t_shift : 0L, $
    t_shift_sim : 0L, $
    show_plot : 0b, $
    version : '', $
    seed : 0L, $
    test_root : '', $
    t_l : 0d, $
    t_r : 0d, $
    t_ig : 0d, $
    sequence_name : "", $
    test_name : "", $
    configuration_file : "", $
    offset_gain_table : "", $
    inherits iut_test }
end
