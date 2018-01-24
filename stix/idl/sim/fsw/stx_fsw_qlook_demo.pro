;+
;
; :Name:
;   stx_fsw_qlook_demo
; :description:
;   Demonstration of the event accumulation module for calibrated energy eventlists or trigger eventlists
;
; :categories:
;    flight software, constructor, simulation
; :Params:
;   
;
; :keywords:
;   
;
                 
; :returns:
;    a spectrogram structure (eventually)
;
; :examples:
;    
;    IDL> stx_fsw_qlook_demo, spec
;    % STX_SIM_ENERGY_DISTRIBUTION: Energy range: [ 4.0000000, 150.00000 ]
;    IDL> help, spec
;    ** Structure <d97d2c0>, 3 tags, length=4768, data length=4768, refs=1:
;       TYPE            STRING    'ql_lightcurve'
;       TIME_AXIS       STRUCT    -> <Anonymous> Array[1]
;       ACCUMULATED_COUNTS
;                       FLOAT     Array[4, 1, 32, 8]
;
; :history:
;     
;     22-apr-2014, richard.schwartz@nasa.gov, initial working version
;
;-
pro stx_fsw_qlook_demo, out, photoncount = photoncount, duration = duration, time_profile_type = time_profile_type

default, photoncount, 2000000L
default, time_profile_type, 'uniform'
default, duration, 32.0
sd = stx_ds_demo( duration=32.d0, photoncount = photoncount, time_profile_type = time_profile_type )
; create the configuration manager for the flight software simulator
fsw_config_manager = ptr_new(stx_configuration_manager(configfile='stx_flight_software_simulator_default.config'))
 
; create the history object
fsw_history = ppl_history()

module = stx_fsw_module_convert_science_data_channels()
success = module->execute(sd.filtered_eventlist, calib_events, fsw_history, fsw_config_manager)
out = stx_fsw_eventlist_accumulator( calib_events, sum_det=0 )

end