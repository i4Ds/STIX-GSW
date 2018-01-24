default, photoncount, 2000000L
sd = stx_ds_demo( duration=96.d0, photoncount = photoncount, time_profile_type = time_profile_type )

; create the configuration manager for the flight software simulator
fsw_config_manager = ptr_new(stx_configuration_manager(configfile='stx_flight_software_simulator_default.config'))
 
; create the history object
fsw_history = ppl_history()

module = stx_fsw_module_convert_science_data_channels()
success = module->execute(sd.filtered_eventlist, calib_events, fsw_history, fsw_config_manager)

;Get the quicklook configuration from the csv file!
;I'm sure you'll want to move this file, there are rules for interpreting this file but 
;I'll detail those later, I think you can figure it out from how it works
;Examine the structure, quicklook_config_struct
;This is the default path to the file and is not needed as an argument
;It's left here as a reference
f = concat_dir( getenv('STX_CONF'), 'qlook_accumulators.csv' )

quicklook_config_struct = stx_fsw_ql_accumulator_table2struct( f )

;Accumulate the detector pixel energy events in quicklook accumulators
for ii=0,14, 2 do help, stx_fsw_eventlist_accumulator( calib_events, _extra = quicklook_config_struct[ii] )
;Accumulate the detector trigger events in quicklook accumulators
;the trigger events are totaled for each detector they will be duplicated as there is only 1 trigger circuit for every two detectors
for ii=1,15, 2 do help, stx_fsw_eventlist_accumulator( sd.trigger_eventlist, _extra = quicklook_config_struct[ii] )
end
