;+
; :file_comments:
;    This is the main program for the stix software framework. It can be used
;    to start the GUI as well as get access to the command line interface
;
; :categories:
;    software
;
; :examples:
;    stx_software_framework                           ->    Starts the GUI
;    stx_software_framework, dss=data_simulation       ->    Returns a data simulation object
;                                                           in the variable data_simulation
;
; :history:
;    13-Nov-2014 - Roman Boutellier (FHNW), Initial release
;-

;+
; :description:
;    Starting the GUI of the stix software framework or getting access to the command
;    line interface (i.e. creating an according object).
;
; :keywords:
;    dss: out, optional, type='stx_data_simulation'
;      a stx_data_simulation object which can be used on the command line but also in the GUI (tbd)
;    fsw: out, optional, type='stx_flight_software_simulator'
;      a stx_flight_software_simulator_clocked object which can be used on the command line or the GUI (tbd)
;    run_simulation : in, optional, type='boolean'
;      if set to 1, it will run the simulation for the given scenario
;
; :history:
;    13-Nov-2014 - Roman Boutellier (FHNW), Initial release
;    08-Dec-2014 - Laszlo I. Etesi (FHNW), - renamed ds keyword to dss
;                                          - renamed simulate to ulation
;    23-Jan-2015 - Roman Boutellier (FHNW), Changed data simulation object to stx_data_simulation (from stx_data_simulation2)
;    03-Dec-2018 - ECMD (Graz), rcr state is passed from previous time bins 
;    08-Nov-2019 - ECMD (Graz), using calculated number of time bins from DSS rathen than fixed value of 1000 

;-
pro stx_software_framework, dss=dss, fsw=fsw, run_simulation=run_simulation, scenario_name=scenario_name, scenario_file=scenario_file, _extra=extra
  ; In case the parameter dss is set, create a new data simulation object
  fsw = obj_new('stx_flight_software_simulator', start_time=stx_construct_time())

  dss = obj_new('stx_data_simulation')

  if (keyword_set(run_simulation)) then begin
    if(~ppl_typeof(scenario_file, compareto='string') && ~ppl_typeof(scenario_name, compareto='string')) then message, 'You must specify one of the two: scenario_name, scenario_file'
    res = dss->getdata(scenario_name=scenario_name, scenario_file=scenario_file, _extra=extra)
    no_time_bins = long(dss->getdata(scenario_name=scenario_name, output_target='scenario_length', _extra=extra) / 4d)

    
    ; Load the flight software simulator
    fsw = obj_new('stx_flight_software_simulator', start_time=stx_construct_time())
    fsw->set, stop_on_error=1
    ; Now iteratively (4s intervals) run the on-board software
    for time_bin = 0L, no_time_bins-1 do begin
      ; Iteratively request data. This is where the Rate Control Regime is set
      fsw->getproperty, current_rcr = rate_control_str
      rcr = rate_control_str.rcr
      ds_result_data = dss->getdata(output_target='stx_ds_result_data', time_bin=time_bin, scenario_name=scenario_name, rate_control_regime=rcr, _extra=extra)

      ; The Data Simulation returns '!NULL' when there is no data for a given interval
      if(ds_result_data eq !NULL) then break

      ; Quickfixes (to be removed later)
      ds_result_data.filtered_eventlist.time_axis = stx_construct_time_axis([0d, 4d])
      ds_result_data.triggers.time_axis = stx_construct_time_axis([0d, 4d])

      ; Process the interval and plot
      fsw->process, ds_result_data.filtered_eventlist, ds_result_data.triggers, plotting=0
    endfor
  endif else begin
    a = obj_new('stx_software_framework')
  endelse

end
