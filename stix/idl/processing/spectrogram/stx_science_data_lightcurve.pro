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
;    fits_path_bk : in, type="string"
;                   The path to the pixel data file containing the background observation.
;
;    is_pixel_data : in, type="Boolean"
;                    Set if STIX science data FITS file is L1 pixel data rather than L4 spectrogram
;
;    plot_obj : out, type="Object"
;               Plotman Object containing the binned lightcurve. Supplying this keyword will open a plotman widget showing
;               the lightcurve plot.
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
;
;-
function stx_science_data_lightcurve, fits_path, energy_ranges = edges_in,  time_min = time_min,  $
  fits_path_bk =  fits_path_bk, is_pixel_data = is_pixel_data, plot_obj = plot_obj

  default, time_min, 20
  default, edges_in, [[4.,10.],[10,15],[15,25]]

  ;for the light curve the standard default corrections are applied
  stx_get_header_corrections, fits_path, distance = distance, time_shift = time_shift

  edge_products, edges_in, edges_2 = energy_ranges


  if keyword_set(is_pixel_data) then begin
    stx_convert_pixel_data, fits_path_data = fits_path, fits_path_bk =  fits_path_bk, distance = distance, time_shift = time_shift, ospex_obj = ospex_obj, _extra= _extra
  endif else begin
    stx_convert_spectrogram, fits_path_data = fits_path, fits_path_bk =  fits_path_bk, distance = distance, time_shift = time_shift, ospex_obj = ospex_obj, _extra= _extra
  endelse

  data_obj = ospex_obj->get(/obj,class='spex_data')
  counts_str = ospex_obj->getdata(spex_units='counts')

  ut_time = ospex_obj->getaxis(/ut, /edges_1)
  ut2_time = ospex_obj->getaxis(/ut, /edges_2)
  duration = ospex_obj->getaxis(/ut, /width)

  ;use OPSEX bin_data method to bin counts in given energy bands
  energy_summed_counts = data_obj->bin_data(data = counts_str, intervals = energy_ranges, $
    eresult = energy_summed_error, ltime = energy_summed_error)

  energy_summed_str = {data:energy_summed_counts, edata:energy_summed_error, ltime:energy_summed_error}

  ; determine time bins with minimum duration - keep adding consecutive bins until the minimum
  ; value is at least reached
  i=0
  j=0
  total=duration[0]
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

  ;use OPSEX bin_data method to bin counts in given time bands
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
  ospex_obj -> set, spex_eband = energy_ranges
  ospex_obj -> set, spex_tband = intervals

  ; if the plot_obj keyword is present create a plotman window and plot the lightcurve
  if arg_present(plot_obj) then begin
    ospex_obj->plot_time,  spex_units='flux', /show_err, /show_filter
    pobj = ospex_obj->get_plotman_obj()
    ut_plot = pobj->get(/data)
    plot_obj = plotman(desc='STIX Lightcurve', input = ut_plot, /ylog, xst = 1)
  endif

  ;retrieve the data from the OSPEX object for the output structure
  flux_str = ospex_obj->getdata(spex_units='flux')
  ut2_time = ospex_obj->getaxis(/ut, /edges_2)
  duration = ospex_obj->getaxis(/ut, /width)

  light_curve_str = {$
    data:flux_str.data, $
    error:flux_str.edata, $
    livetime : flux_str.ltime, $
    ut:ut2_time, duration:duration, $
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
  out_dir = concat_dir( getenv('stx_demo_data'),'ospex', /d)

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