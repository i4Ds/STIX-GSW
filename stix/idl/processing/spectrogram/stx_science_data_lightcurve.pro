;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_science_data_lightcurve
;
; :description:
;    This takes a science data file and produces a lightcurve structure binned to the given energy and time bins
;    A plotman window showing the lightcurve can also be generated.
;
; :categories:
;     lightcurve
;
; :params:
;    fits_path : in, required, type="string" or "str array"
;                The path to the STIX science data FITS file. An array of paths can also be given: In such a case, the code
;                will iterate on all FITS files concatenating the time profiles.
;
; :keywords:
;    energy_ranges : in, type="float array", default="[[4.,10.],[10,15],[15,25]]"
;                    2N or N+1 contiguous energy edges in keV required for lightcurve
;
;    time_min : in, type="float", default="20."
;               Minimum time size in seconds
;
;    time_shift : in, type="float", default: taken from the FITS header
;                 Light travel time correction to apply to the time profiles. By default, it takes the
;                 value from the FITS header, i.e., Sun centre location of the flare is assumed.
;
;    fits_path_bk : in, type="string"
;                   The path to the pixel data file containing the background observation.
;
;    rate : in, optional keyword, default="flux"
;               If set, the output units are cnts/s. By default, it is in Flux units [cnts/s/keV/cm^2]
;
;    det_ind : in, type="int array", default="all detectors  present in observation"
;              indices of detectors to sum when making spectrogram - N.B. only applicable when input file is pixel data
;
;    pix_ind : in, type="int array", default="all pixels present in observation"
;               indices of pixels to sum when making spectrogram - N.B. only applicable when input file is pixel data
;
;    time_range : in, type="dbl array" or "str array", default="all times present in observation"
;               It allows to extract a sub-interval from the FITS file. Particularly useful if one wants to extract only
;               a sub-interval around a flare from a long spectrogram file. 
;               Since by default time_shift is taken from the FITS header, this time_range has to be specified in Earth UT.
;               
;    sys_uncert : in, optional keyword, default="0.05"
;               The level of systematic uncertainty to be added to the data
;
;    plot_obj : out, type="Object"
;               Plotman Object containing the binned lightcurve. Supplying this keyword will open a plotman widget showing
;               the lightcurve plot.
;
;
; :returns:
;
;    light_curve_str : out, type="structure"
;                      basic structure containing the lightcurve data plus the corresponding energy and time ranges
;
; :examples:
;  light_curve_str = stx_science_data_lightcurve(fits_path_spectrogram, energy_ranges = [4,6,10,28], time_min = 60, plot_obj = plot_obj )
;
; :history:
;    30-Jun-2022 - ECMD (Graz), initial release
;    15-Jul-2022 - Andrea Francesco Battaglia (FHNW)
;                  Added a few functionalities:
;                       -> automatic recognition of SPEC and CPD files: /is_pixel_data is no longer needed
;                       -> option to manually define time_shift. Default: assume solar centre
;                       -> rate keyword added
;    08-Aug-2022 - ECMD (Graz), added pixel and detector index selection for pixel data
;                               added keyword to allow the user to specify the systematic uncertainty
;    05-Sep-2022 - ECMD (Graz), added rcr info to output structure
;                               suppress plotting when ospex object is created  
;    15-Dec-2023 - AFB (FHNW), keyword time_range added, to extract only a sub-interval
;    31-Jan-2023 - AFB (FHNW), it is now possible to pass multiple FITS files in fits_path and the output
;                              structure will be the concatenation of all the input files
;    19-Jun-2023 - ECMD (Graz), added _extra keyword for pass through to stx_convert_... routines as suggested by ianan
;
;-
function stx_science_data_lightcurve, fits_path, energy_ranges = edges_in,  time_min = time_min,  $
  fits_path_bk =  fits_path_bk, plot_obj = plot_obj, time_shift = time_shift, rate = rate, shift_duration = shift_duration, $
  det_ind = det_ind, pix_ind = pix_ind, sys_uncert = sys_uncert, time_range = time_range, _extra= _extra


  default, time_min, 20
  default, edges_in, [[4.,10.],[10,15],[15,25]]
  default, spex_units, 'flux'

  ; If /rate is set, return the rate units
  if keyword_set(rate) then spex_units = 'rate'

  ;for the light curve the standard default corrections are applied
  ; If the user manually defines time_shift, then use that
  stx_get_header_corrections, fits_path[0], distance = distance, time_shift = tmp_shift
  default, time_shift, tmp_shift

  edge_products, edges_in, edges_2 = energy_ranges

  ; Get the original filename
  !null = mrdfits(fits_path[0], 0, primary_header)
  orig_filename = sxpar(primary_header, 'FILENAME')

  ; Multiple FITS files can be provided and the output will be the concatenation of all files
  nfiles = n_elements(fits_path)
  data_all = []
  error_all = []
  ltime_all = []
  ut2_time_all = []
  duration_all = []
  rcr_all = []
  for this_file = 0, nfiles-1 do begin

    if strpos(orig_filename, 'cpd') gt -1 or strpos(orig_filename, 'xray-l1') gt -1 then begin
      stx_convert_pixel_data, fits_path_data = fits_path[this_file], fits_path_bk =  fits_path_bk, distance = distance, time_shift = time_shift, ospex_obj = ospex_obj, $
        det_ind = det_ind, pix_ind = pix_ind, sys_uncert = sys_uncert, plot = 0, _extra= _extra
    endif else if strpos(orig_filename, 'spec') gt -1 or strpos(orig_filename, 'spectrogram') gt -1 then begin
      stx_convert_spectrogram, fits_path_data = fits_path[this_file], fits_path_bk =  fits_path_bk, distance = distance, time_shift = time_shift, ospex_obj = ospex_obj, $
        sys_uncert = sys_uncert, plot = 0, _extra= _extra
      if keyword_set(det_ind) or keyword_set(pix_ind) then  message, 'ERROR: Detector and pixel selection not possible with spectrogram files.'
    endif else begin
      message, 'ERROR: the FILENAME field in the primary header should contain either cpd, xray-l1 or spec'
    endelse
  
    data_obj = ospex_obj->get(/obj,class='spex_data')
    counts_str = ospex_obj->getdata(spex_units='counts')
  
    ut_time = ospex_obj->getaxis(/ut, /edges_1)
    ut2_time = ospex_obj->getaxis(/ut, /edges_2)
    ;ut2_time_all = ut2_time
    duration = ospex_obj->getaxis(/ut, /width)
    filters_all = ospex_obj->get(/spex_interval_filter) 
    
    ;use OSPEX bin_data method to bin counts in given energy bands
    energy_summed_counts = data_obj->bin_data(data = counts_str, intervals = energy_ranges, $
      eresult = energy_summed_error, ltime = energy_summed_ltime)
  
    energy_summed_str = {data:energy_summed_counts, edata:energy_summed_error, ltime:energy_summed_ltime}
  
    ; determine time bins with minimum duration - keep adding consecutive bins until the minimum
    ; value is at least reached
    i=0
    j=0
    total=0
    iall=[]
  
    while (i lt n_elements(duration)-1) do begin
      while (total lt time_min)  and (i+j le n_elements(duration)-1) do begin
        total = total(duration[i:i+j])
        j++
      endwhile
      iall = [iall,i]
      i = i+j
      j = 0
      total = 0
    endwhile
  
    intervals = [ut2_time[0,iall[0:-2]],ut2_time[1,iall[1:-1]-1]]
    intervals = [[intervals],[ ut2_time[0,iall[-1]], ut2_time[1,-1]]]
  
    ;use OSPEX bin_data method to bin counts in given time bands
    time_summed_counts = data_obj->bin_data(data = energy_summed_str, intervals = intervals, /do_time, $
      eresult = time_summed_error, ltime = time_summed_livetime)
  
    ; insert the data summed in time and energy back into the OSPEX object
    ospex_obj->set, spex_data_source = 'spex_user_data'
    ospex_obj->set, spectrum = time_summed_counts,  $
      spex_ct_edges = energy_ranges, $
      errors = time_summed_error, $
      spex_ut_edges = intervals, $
      livetime = time_summed_livetime, $
      spex_detectors = 'STIX'
    origunits = ospex_obj->get(/spex_data_origunits)
    origunits.data_name = 'STIX'
    ospex_obj->set, spex_data_origunits = origunits
    ospex_obj->set, spex_uncert = 0.05
    ospex_obj ->set, spex_eband = energy_ranges
    ospex_obj ->set, spex_tband = intervals
    ospex_obj->set, spex_fit_time_interval = intervals
    
    idx = transpose([[iall],[shift(iall,-1)-1]])
    rcr  = spex_get_filter(filters_all,idx)
    
    ; if the plot_obj keyword is present create a plotman window and plot the lightcurve
    if arg_present(plot_obj) then begin
      ospex_obj->plot_time,  spex_units=spex_units, /show_err, /show_filter
      pobj = ospex_obj->get_plotman_obj()
      ut_plot = pobj->get(/data)
      plot_obj = plotman(desc='STIX Lightcurve', input = ut_plot, /ylog, xst = 1)
      print,''
      print,'=====>  Press SPACEBAR to continue  <====='
      print,''
      pause
    endif
  
    ;retrieve the data from the OSPEX object for the output structure
    flux_str = ospex_obj->getdata(spex_units=spex_units)
    units = data_obj->getunits()
    ut2_time = ospex_obj->getaxis(/ut, /edges_2)
    duration = ospex_obj->getaxis(/ut, /width)
  
    ; Concatenate the data
    data_all = [[data_all], [flux_str.data]]
    error_all = [[error_all], [flux_str.edata]]
    ltime_all = [[ltime_all], [flux_str.ltime]]
    ut2_time_all = [ut2_time_all, transpose(ut2_time[0,*])]
    duration_all = [duration_all, duration]
    rcr_all = [rcr_all, rcr]
  
  endfor ; End of the loop for all files
  
  
  ; Check for duplicates and delete them
  sorted_list = sort(anytim(ut2_time_all))
  this_diff = anytim(ut2_time_all) * 0.
  this_diff[1:*] = anytim(ut2_time_all[sorted_list[1:*]])-anytim(ut2_time_all[sorted_list[0:-2]])
  keeplist = where(abs(this_diff) ge 0.45)
  ut2_time_all = ut2_time_all[sorted_list[keeplist]]
  data_all = data_all[*,sorted_list[keeplist]]
  error_all = error_all[*,sorted_list[keeplist]]
  ltime_all = ltime_all[*,sorted_list[keeplist]]
  duration_all = duration_all[sorted_list[keeplist]]
  
  ; Extract a sub-interval, if requested
  if keyword_set(time_range) then begin

    time_range = anytim(time_range)
    this_ut = anytim(ut2_time_all)

    start_ind = where(abs(this_ut-time_range[0]) eq min(abs(this_ut-time_range[0])))
    end_ind = where(abs(this_ut-time_range[1]) eq min(abs(this_ut-time_range[1])))

    ut2_time_all = ut2_time_all[start_ind:end_ind]
    data_all = data_all[*,start_ind:end_ind]
    error_all = error_all[*,start_ind:end_ind]
    ltime_all = ltime_all[*,start_ind:end_ind]
    duration_all = duration_all[start_ind:end_ind]
    rcr_all = rcr_all[start_ind:end_ind]

  endif
  
  light_curve_str = {$
    data:data_all, $
    data_type:units.data_type, $
    data_units:units.data, $
    error:error_all, $
    livetime : ltime_all, $
    ut:ut2_time_all, $
    duration:duration_all, $
    time_shift:time_shift, $
    rcr:rcr_all, $
    energy_bands:energy_ranges}

  obj_destroy, ospex_obj
  return, light_curve_str
end
;---------------------------------------------------------------------------
;+
;
; :name:
;       stx_science_data_lightcurve
;
; :description:
;    This takes the demonstration science data files and plots a lightcurve binned to the given energy and time bins.
;    Four cases are shown:
;    1) spectrogram without background subtraction
;    1) spectrogram with background subtraction
;    1) pixel data without background subtraction
;    1) pixel data with background subtraction
;
;
; :categories:
; demonstration, lightcurve
;
; :history:
;    02-Jul-2022 - ECMD (Graz), initial release
;    23-Oct-2023 - ECMD (Graz), updated demo to L1 files 
;
;-
pro stx_demo_lightcurve

  ;The files used for this demonstration are hosted on a STIX server and downloaded when the demo is first run
  site = 'http://dataarchive.stix.i4ds.net/fits/L1/2022/02/' 

  ;The OSPEX folder in under stx_demo_data will usually start off empty on initial installation of the STIX software
  out_dir = concat_dir( getenv('STX_DEMO_DATA'),'ospex', /d)

  ;if the ospex demo database folder is not present then create it
  if ~file_test(out_dir, /directory) then begin
    file_mkdir, out_dir
  endif


  ;As an example a spectrogram (Level 4) file for a flare on 8th February 2022 is used
  spec_filename = 'solo_L1_stix-sci-xray-spec_20220208T212353-20220208T223255_V01_2202080003-58150.fits'

  ;Download the spectrogram fits file to the stix/dbase/demo/ospex/ directory
  sock_copy, site + '08/SCI/' + spec_filename, status = status, out_dir = out_dir

  ;An observation of a non-flaring quiet time close to the flare observation can be used as a background estimate
  bk_filename  = 'solo_L1_stix-sci-xray-cpd_20220209T002721-20220209T021401_V01_2202090020-58535.fits'
  sock_copy, site + '09/SCI/'+ bk_filename, status = status, out_dir = out_dir

  ;As well as the summed spectrogram a pixel data observation of the same event is also available
  cpd_filename = 'solo_L1_stix-sci-xray-cpd_20220208T212833-20220208T222055_V01_2202080013-58504.fits'
  sock_copy, site + '08/SCI/' + cpd_filename, status = status, out_dir = out_dir


  ;Now they have been dowloaded set the paths of the science data files
  fits_path_data_spec = loc_file(spec_filename, path = out_dir )
  fits_path_bk   = loc_file(bk_filename, path = out_dir )
  fits_path_data_cpd   = loc_file(cpd_filename, path = out_dir)

  ; set the example time and energy binning
  time_min = 4
  energy_ranges = [4,6,10,28]

  ; for the demo we won't generate FITS files 
  generate_fits = 0
  
  light_curve_str = stx_science_data_lightcurve(fits_path_data_spec, energy_ranges = energy_ranges, time_min = time_min, generate_fits=generate_fits,  plot_obj = plot_obj )

  help, light_curve_str

  print, "Press SPACE to continue"
  print, " "
  pause

  light_curve_str = stx_science_data_lightcurve(fits_path_data_spec, energy_ranges = energy_ranges, time_min = time_min, fits_path_bk =fits_path_bk, generate_fits=generate_fits, plot_obj = plot_obj  )

  print, "Press SPACE to continue"
  print, " "
  pause

  light_curve_str = stx_science_data_lightcurve(fits_path_data_cpd, energy_ranges = energy_ranges, time_min = time_min, generate_fits=generate_fits, plot_obj = plot_obj)

  print, "Press SPACE to continue"
  print, " "
  pause

  light_curve_str = stx_science_data_lightcurve(fits_path_data_cpd, energy_ranges = energy_ranges, time_min = time_min,  fits_path_bk = fits_path_bk,  generate_fits=generate_fits, plot_obj = plot_obj )

  print, "Press SPACE to end demo"
  print, " "
  pause
end
