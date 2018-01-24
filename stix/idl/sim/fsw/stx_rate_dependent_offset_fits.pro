;+
; :description:
;   Given a scenario this procedure will read in the simulated eventlist and write out a new eventlist with
;   the ad channel of each event shifted by a rate dependent value
;
;
; :keywords:
;
;   scenario_name  : in, type='float', default=''stx_scenario_rate_dept_' + scenario_flux + '_rate''
;                     the name of the scenario file to be processed
;
;   scenario_flux  : in, type='string', default='high'
;                    a short (e.g. 1 word) description of the scenario used for naming plots and telemetry files
;
;    maxrate       : in, optional, type = "float", default = '3000.'
;                    The count rate at which the energy shift is at the maximum value of 1 keV
;                    above this it plateaus at the constant value of 1 keV
;
;    max_events    : in, optional, type = "long", default = '10L^6'
;                    The maximum number of events to hold in the array of processed eventlists before writing all
;                    currently processed events to file
;
;    time_res      : in, optional, type = "float", default = '4'
;                    the size of the time bin, in seconds, used to determine the rate in each pixel
;
;
; :examples:
;     stx_rate_dependent_offset_fits, scenario_name = 'stx_scenario_rate_dept'
;
; :history:
;     10-Oct-2017 - ECMD (Graz), initial release
;
;-
pro   stx_rate_dependent_offset_fits, scenario_name = scenario_name, scenario_flux = scenario_flux, max_events= max_events, time_res=time_res, maxrate = maxrate

  default, scenario_flux, 'high'
  default, scenario_name, 'stx_scenario_rate_dept_' + scenario_flux + '_rate'
  default, max_events, 10L^6
  default, time_res, 4.
  default, maxrate, 3000.
  
  dss = obj_new('stx_data_simulation')
  
  no_time_bins = long(dss->getdata(scenario_name=scenario_name, output_target='scenario_length') / 4d)
  scenario_output_path = dss->getdata(output_target='scenario_output_path', scenario_name=scenario_name, out_skip_sim = 1)
  
  ;get the names of all the data fits files and any IDL sav files e.g. fsw run by the GUI
  ;as these will be moved to a separate folder "originals" at the end leaving only the shifted data
  ;in the current scenario folder
  old_files = find_files('*_*.fits', scenario_output_path)
  old_sav = find_files('*.sav', scenario_output_path)
  if old_sav ne '' then old_files = [old_files, old_sav]
  old_files_path = concat_dir(scenario_output_path, 'originals')
  file_mkdir, old_files_path
  
  events_out = []
  
  ;loop through all 4s time bins as is done when processing the fsw
  for time_bin = 0L, no_time_bins do begin
  
    ;read in the detector simulation data without any further processing such as time filtering
    ds_result_data = dss->getdata(output_target='stx_sim_detector_eventlist', time_bin=time_bin, scenario=scenario_name)
    
    if ds_result_data eq !NULL then continue
    
    ;create a histogram of which time bins at the specified resolution the detector events fall into
    ; by default 4 seconds is used so there will only be a single bin but finer resolutions may be used in the future
    full_histogram  = histogram(ds_result_data.detector_events.relative_time, binsize = time_res, reverse_indices = rri )
    nsubs = n_elements(full_histogram)
    
    ;loop through each time bin
    for sub_bin = 0, nsubs-1 do begin
    
      zzi = reverseindices( rri, sub_bin )
      if ( full_histogram[sub_bin] ne 0 ) then begin
      
        ;get all the events which correspond to the current time bin
        current_eventlist = (ds_result_data.detector_events)[zzi]
        
        ;make a histogram of which detector events occur in each pixel and detector
        current_histogram  = histogram((current_eventlist.detector_index-1) + 32*current_eventlist.pixel_index, min = 0, max = 32.*12.-1, reverse_indices = ri )
        totshift = fltarr(384)
        
        ;loop over each of the individual 12 x 32 pixels
        for i = 0,383 do begin
          idx_dp = reverseindices( ri, i )
          if ( current_histogram[i] ne 0 ) then begin
            ;get the energy shift in terms of ad channel based on the rate in each pixel
            eshift = stx_rate_shift(current_histogram[i]/time_res, maxrate = maxrate, /ad)
            ;apply the energy shift to all the events in the events list
            current_eventlist[idx_dp].energy_ad_channel += eshift
          endif
        endfor
        
      endif
      
      ;add the processed event list to the array
      events_out = [events_out, current_eventlist]
      
    endfor
    
    ;if there are sufficient events in the total list write the energy shifted data to file
    if n_elements(events_out) gt max_events then begin
    
      file_prefix = 'Energy_shifted_events_' + trim(string(events_out[0].relative_time,format="(d32)")) + '_'
      
      ;use the standard stix detector eventlist writer to write the energy shifted eventlist to  a fits file
      ; all other parameters for the eventlist should be identical to what was read in
      stx_sim_detector_events_fits_writer, events_out , file_prefix, base_dir = scenario_output_path, warn_not_empty=0
      
      ;reset the array of processed events
      events_out = []
    endif
    
  endfor
  
  ;flush any events not previously written to file
  if n_elements(events_out) gt 0 then begin
    file_prefix = 'Energy_shifted_events_' + trim(string(events_out[0].relative_time,format="(d32)")) + '_'
    
    stx_sim_detector_events_fits_writer, events_out , file_prefix, base_dir=scenario_output_path, warn_not_empty=0
  endif
  
  ;move all of the previous unshifted data to the "originals" file
  file_move, old_files, old_files_path
  
end

