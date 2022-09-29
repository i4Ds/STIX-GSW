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
;    fits_path : in, required, type="string"
;                The path to the STIX science data FITS file.
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
;
;-
function stx_science_data_lightcurve, fits_path, energy_ranges = edges_in,  time_min = time_min,  $
  fits_path_bk =  fits_path_bk, plot_obj = plot_obj, time_shift = time_shift, rate = rate, shift_duration = shift_duration, $
  det_ind = det_ind, pix_ind = pix_ind, sys_uncert = sys_uncert


  default, time_min, 20
  default, edges_in, [[4.,10.],[10,15],[15,25]]
  default, spex_units, 'flux'

  ; If /rate is set, return the rate units
  if keyword_set(rate) then spex_units = 'rate'

  ;for the light curve the standard default corrections are applied
  ; If the user manually defines time_shift, then use that
  stx_get_header_corrections, fits_path, distance = distance, time_shift = tmp_shift
  default, time_shift, tmp_shift

  edge_products, edges_in, edges_2 = energy_ranges

  ; Get the original filename
  !null = mrdfits(fits_path, 0, primary_header)
  orig_filename = sxpar(primary_header, 'FILENAME')

  if strpos(orig_filename, 'cpd') gt -1 or strpos(orig_filename, 'xray-l1') gt -1 then begin
    stx_convert_pixel_data, fits_path_data = fits_path, fits_path_bk =  fits_path_bk, distance = distance, time_shift = time_shift, ospex_obj = ospex_obj, $
      det_ind = det_ind, pix_ind = pix_ind, sys_uncert = sys_uncert, plot = 0, _extra= _extra
  endif else if strpos(orig_filename, 'spec') gt -1 or strpos(orig_filename, 'spectrogram') gt -1 then begin
    stx_convert_spectrogram, fits_path_data = fits_path, fits_path_bk =  fits_path_bk, distance = distance, time_shift = time_shift, ospex_obj = ospex_obj, $
      sys_uncert = sys_uncert, plot = 0, _extra= _extra
    if keyword_set(det_ind) or keyword_set(pix_ind) then  message, 'ERROR: Detector and pixel selection not possible with spectrogram files.'
  endif else begin
    message, 'ERROR: the FILENAME field in the primary header should contain either cpd, xray-l1 or spec'
  endelse

  data_obj = ospex_obj->get(/obj,class='spex_data')
  counts_str = ospex_obj->getdata(spex_units='counts')

  ut_time = ospex_obj->getaxis(/ut, /edges_1)
  ut2_time = ospex_obj->getaxis(/ut, /edges_2)
  ut2_time_all = ut2_time
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
  endif

  ;retrieve the data from the OSPEX object for the output structure
  flux_str = ospex_obj->getdata(spex_units=spex_units)
  units = data_obj->getunits()
  ut2_time = ospex_obj->getaxis(/ut, /edges_2)
  duration = ospex_obj->getaxis(/ut, /width)


  light_curve_str = {$
    data:flux_str.data, $
    data_type:units.data_type, $
    data_units:units.data, $
    error:flux_str.edata, $
    livetime : flux_str.ltime, $
    ut:ut2_time, $
    duration:duration, $
    time_shift:time_shift, $
    rcr:rcr, $
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
;    1) L4 spectrogram without background subtraction
;    1) L4 spectrogram with background subtraction
;    1) L1 pixel data without background subtraction
;    1) L4 pixel data with background subtraction
;
;
; :categories:
; demonstration, lightcurve
;
; :history:
;    02-Jul-2022 - ECMD (Graz), initial release
;
;-
pro stx_demo_lightcurve

  ;The files used for this demonstration are hosted on a STIX server and downloaded when the demo is first run
  site = 'http://dataarchive.stix.i4ds.net/data/demo/ospex/'

  ;The OSPEX folder in under stx_demo_data will usually start off empty on initial installation of the STIX software
  out_dir = concat_dir( getenv('STX_DEMO_DATA'),'ospex', /d)

  ;if the ospex demo database folder is not present then create it
  if ~file_test(out_dir, /directory) then begin
    file_mkdir, out_dir
  endif


  ;As an example a spectrogram (Level 4) file for a flare on 8th February 2022 is used
  l4_filename = 'solo_L1A_stix-sci-spectrogram-2202080003_20220208T212353-20220208T223255_035908_V01.fits'
  sock_copy, site + l4_filename, status = status, out_dir = out_dir

  ;An observation of a non-flaring quiet time close to the flare observation can be used as a background estimate
  bk_filename  = 'solo_L1A_stix-sci-xray-l1-2202090020_20220209T002720-20220209T021400_036307_V01.fits'
  sock_copy, site + bk_filename, status = status, out_dir = out_dir

  ;As well as the summed spectrogram a pixel data observation of the same event is also available
  l1_filename = 'solo_L1A_stix-sci-xray-l1-2202080013_20220208T212833-20220208T222055_036275_V01.fits'
  sock_copy, site + l1_filename, status = status, out_dir = out_dir

  ;Now they have been dowloaded set the paths of the science data files
  fits_path_data_l4 = loc_file(l4_filename, path = out_dir )
  fits_path_bk   = loc_file(bk_filename, path = out_dir )
  fits_path_data_l1   = loc_file(l1_filename, path = out_dir)

  ; set the example time and energy binning
  time_min = 4
  energy_ranges = [4,6,10,28]

  light_curve_str = stx_science_data_lightcurve(fits_path_data_l4, energy_ranges = energy_ranges, time_min = time_min,  plot_obj = plot_obj )

  help, light_curve_str

  print, "Press SPACE to continue"
  print, " "
  pause

  light_curve_str = stx_science_data_lightcurve(fits_path_data_l4, energy_ranges = energy_ranges, time_min = time_min, fits_path_bk =fits_path_bk,  plot_obj = plot_obj  )

  print, "Press SPACE to continue"
  print, " "
  pause

  light_curve_str = stx_science_data_lightcurve(fits_path_data_l1, /is_pixel_data, energy_ranges = energy_ranges, time_min = time_min,  plot_obj = plot_obj)

  print, "Press SPACE to continue"
  print, " "
  pause

  light_curve_str = stx_science_data_lightcurve(fits_path_data_l1, /is_pixel_data, energy_ranges = energy_ranges, time_min = time_min ,  fits_path_bk = fits_path_bk,  plot_obj = plot_obj )

  print, "Press SPACE to end demo"
  print, " "
  pause
end