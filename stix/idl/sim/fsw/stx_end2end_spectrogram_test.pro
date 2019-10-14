;+
; :description:
;
;    This procedure performs end to end testing on the stx spectrogram data product starting with RHESSI flare data
;    stx_sim_rhessi_flares is used to generate a scenario file for the specified flare using the fit parameters.
;    the data simulation software (DSS) is run to generate FITS files with the eventlist of detected counts for the full flare scenario
;    This eventlist is then processed flight software simulator (FSWS).
;    A spectrogram of the count data is created from the level 1 output of the STIX interval selection algorithm
;    This spectrogram is then written into spectrum and DRM FITS files
;    OSPEX is the used to estimate the fit parameters from the STIX spectrogram data
;
;
; :categories:
;    data simulation, spectrogram
;
; :keywords:
;
;
; :examples:
;
;   stx_sim_rhessi_fit, obj, 5100551, /firstrun
;
; :history:
;
;       03-Dec-2018 – ECMD (Graz), initial release
;
;-
pro stx_end2end_spectrogram_test, obj, flareid, firstrun= firstrun

  default, firstrun , 1

  fit_results = obj -> get(/spex_summ)

  ;gerenerate a scenario file from the RHESSI fit
  stx_sim_rhessi_fit, fit_results,  rhessi_flare_id=flareid, /plot,scenario_name = scenario_name, spec = spec, all_params =all_params, $
    utvals =utvals, tntmask = tntmask, flare_start = ut_flare_start, preflare= preflare


  ; Run the simulation of the specified scenario
  dssfilename = filepath("dss.sav",root_dir=scenario_name)
  fswfilename = filepath("fsw.sav",root_dir=scenario_name)


  if firstrun then begin
    ;run the specified scenario through the data simulation and FSWS
    stx_software_framework, scenario_name = scenario_name, /run_simulation, dss = dss, fsw = fsw

    ;save the output objects to save time in future runs
    save, dss, filename = dssfilename
    save, fsw, filename = fswfilename

  endif

  ;if firstrun is not set the saved FSW object should already exist
  restore, fswfilename

  ;get the total time for the full simulation so it will all be included in the spectrogram
  fsw->getproperty, current_bin=current_bin, time_bin_width=time_bin_width, relative_time=relative_time

  ;need the spectrogram itself and the ql light curve data (for the rcr status)
  input_data =  {sd_spectrogram : 1, ql_light_curves :1 }
  flare_start = 0.
  flare_end =  relative_time+time_bin_width
  input_data = add_tag(input_data,[flare_start,flare_end], "rel_flare_time")

  tmtc_filename =  scenario_name +"_spectrogram_tmtc.bin"

  ;write the telemetry for the spectrogram to file
  ret = fsw->getdata(output_target="stx_fsw_tmtc", filename=tmtc_filename, _extra=input_data)

  ;read in the previously generated telemetry file
  telemetry_reader =  stx_telemetry_reader(filename=tmtc_filename, /scan_mode)

  telemetry_reader->getdata, fsw_spc_data_time_group=fsw_spc_data_time_group,  asw_ql_lightcurve=ql_lightcurves
  fsw_spc = (fsw_spc_data_time_group[0])->toarray()

  ;get the time intervals the spectrogram was built on and add back the real start time of the flare
  tints = stx_time_add([fsw_spc.start_time,fsw_spc[-1].end_time], seconds = ut_flare_start)

  ;insert the information from the telemetry file into the expected stx_fsw_sd_spectrogram structure
  spectrogram = { $
    type          : "stx_fsw_sd_spectrogram", $
    counts        : fsw_spc.intervals.counts, $
    trigger       : fsw_spc.trigger, $
    time_axis     : stx_construct_time_axis(tints) , $
    energy_axis   : stx_construct_energy_axis(select=where(fsw_spc[0].energy_bin_mask)), $
    pixel_mask    : fsw_spc.pixel_mask $
  }

  ;get the rcr states and the times of rcr changes from the ql_lightcurves structure
  ut_rcr= stx_time2any(ql_lightcurves[0].time_axis.time_start) + ut_flare_start

  rcr = ql_lightcurves[0].rate_control_regime

  find_changes, rcr, index, state, count=count

  ;add the rcr information to a specpar structure so it can be incuded in the spectrum FITS file
  specpar = { sp_atten_state :  {time:ut_rcr[index], state:state} }


  srmfilename = filepath("stx_spectrum_srm.fits",root_dir=scenario_name)
  specfilename = filepath("stx_spectrum.fits",root_dir=scenario_name)

  ;pass the spectrogram and all other needed information to OSPEX
  ospex_obj =   stx_fsw_sd_spectrogram2ospex(spectrogram ,specpar = specpar,  /fits, specfilename=specfilename, srmfilename=srmfilename  )

  ;fit all of the relevant time bins in the OSPEX spectrogram
  stx_fit_end2end_spectrogram,  ospex_obj, params, scenario_name= scenario_name, utvals =utvals+ ut_flare_start, tntmask = tntmask

  fit_results = ospex_obj -> get(/spex_summ)

  ;plot the fit parameters along with the initial parameters from theRHESSI flare data
  stx_plot_end2end_results, fit_results, scenario_name = scenario_name, all_params =all_params, $
    utvals =utvals, tntmask = tntmask, flare_start = ut_flare_start

end
