;+
; :description:
;   Demo routine to make an image cube starting from a scenario using the DSS, FSW and ASW
;   based on run_ds_fswsim_demo
;
; :history:
;    2-Oct-2016 - ECMD (Graz), initial release
;
;-

pro stx_cube_demo

  scenario =  'stx_scenario_2'
  asw = obj_new('stx_analysis_software')
  ois = obj_new( 'stx_img_spectra' )
  
  run_ds_fswsim_demo, dss=dss, fsw=fsw, scenario=scenario
  ;restore, 'stixidldemosavstx_scenario_2_dss.sav'
  ;restore, 'stixidldemosavstx_scenario_2_fsw.sav'
  
  ; as scenario 2 does not trigger the flare flag a flare time has to be set artificially
  flare_time = {$
    type            : "stx_fsw_flare_selection_result", $
    IS_VALID        : 1b, $
    FLARE_TIMES     : reform([stx_construct_time(time=104.0),stx_construct_time(time=240.0)],1,2), $
    CONTINUE_TIME   : stx_time() $
    }
    
  help, flare_time
  
  ;to ensure the time boundaries remain aligned the trimming is set to 0
  fsw->set, module="stx_fsw_module_intervalselection_img", trimming_max_loss = 0.0d
  
  
  ;run the interval selection for the given flare time
  ivs_result = fsw->getdata(output_target="stx_fsw_ivs_result", input_data=flare_time)
  
  energy_axis =  stx_construct_energy_axis()
  
  ;the start and end times of each group are combined to make a
  times_all = []
  foreach group, ivs_result.l1_img_combined_archive_buffer_grouped do times_all = [times_all, group.start_time, group.end_time]
  times_all = stx_time2any(times_all)
  time_axis = times_all[uniq( times_all, sort(times_all))]
  
  ;empty arrays for the ivs intervals and the raw pixel data
  ivs_all = []
  raw_pixel_data_all = []
  
  ;run through every interval in every group, each one should correspond to one enrty in the each of the
  ;ivs intervals and raw pixel data arrays
  foreach group, ivs_result.l1_img_combined_archive_buffer_grouped do foreach interval, group.intervals do begin
  
    ivs = stx_ivs_interval()
    
    ivs.start_time       =  group.start_time
    ivs.end_time         =  group.end_time
    ivs.start_time_idx   =  where(time_axis eq stx_time2any(group.start_time ) )
    ivs.end_time_idx     =  where(time_axis eq stx_time2any(group.end_time ) )
    ivs.start_energy     =  (energy_axis.edges_1)[interval.energy_science_channel_range[0]]
    ivs.end_energy       =  (energy_axis.edges_1)[interval.energy_science_channel_range[1]]
    ivs.start_energy_idx =  interval.energy_science_channel_range[0]
    ivs.end_energy_idx   =  interval.energy_science_channel_range[1]
    ivs.counts           =  total(interval.counts)
    ivs.spectroscopy     =  0
    
    ivs_all =[ivs_all , ivs]
    
    
    raw_pixel_data = stx_pixel_data()
    
    raw_pixel_data.type             =  "stx_raw_pixel_data"
    raw_pixel_data.time_range       =  [group.start_time, group.end_time]
    raw_pixel_data.energy_range     =  energy_axis.edges_1[interval.energy_science_channel_range]
    raw_pixel_data.counts           =  interval.counts
    raw_pixel_data.live_time        =  group.trigger
    raw_pixel_data.attenuator_state =  group.rcr
    
    raw_pixel_data_all = [raw_pixel_data_all,raw_pixel_data]
  endforeach
  
  ;pass the inverval selection structure to the imaging spectroscopy object
  pimg = ptr_new(ivs_all)
  ois -> set, img = pimg, erange=[4,140]
  ;determine the regular boundaries for imaging spectroscopy
  spect_struct = ois->sum_time_groups( /mk_struct )
  ois->plot
  
  ;generate an IVS interval structure from the img spectra spectrogram structure
  img_spec_ints = stx_img_spec_spectrogram2intervals(spect_struct)
  
  ;stx_pixel_data_intervals for input into stx_sum_over_time_energy
  pixel_data_intervals = { $
    type : 'stx_pixel_data_intervals', $
    intervals : img_spec_ints, $
    raw_pixel_data : raw_pixel_data_all $
    }
    
  ;sum the raw pixel data over the img spectra intervals
  pixel_data = stx_sum_over_time_energy(pixel_data_intervals)
  
  ;pass the pixel data as the input for the analysis software object
  asw->setdata, pixel_data
  
  ; generate the images for all boundaries
  image_str = asw->getdata(out_type='stx_image')
  
  ;write all the data to fits
  filename = 'cube_demo.fits'
  stx_map2fits_cube, image_str, filename, maps
  
  ;make an ospex object and read in the fits file
  sp_obj = ospex(spex_specfile=filename)

end
