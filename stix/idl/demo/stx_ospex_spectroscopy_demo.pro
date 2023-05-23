;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_ospex_spectroscopy_demo
;
; :description:
;    This demonstration script shows how to convert Level 1(A) STIX science data files to an OSPEX compatible format which is then
;    loaded into an OSPEX object. Subsequently a spectrum in a single time interval how to fit
;    Three different options for fitting a STIX time interval are presented:
;    i) using spectrogram data with no externally supplied background file and selecting a pre-flare background time interval
;    ii)  using spectrogram data with an externally supplied background file
;    and iii) using a pixel data file with an externally supplied background file.
;    The resulting fit parameters for each of these methods are then compared.
;
;
; :categories:
;    demo, spectroscopy
;
; :history:
;   03-Mar-2022 - ECMD (Graz), initial release
;   16-Mar-2023 - ECMD (Graz), updated to use release version L1 files
;
;-
pro stx_ospex_spectroscopy_demo

  ;*********************************************** 1- AQUIRE DATA ******************************************************

  ;The files used for this demonstration are hosted on a STIX server and downloaded when the demo is first run
  ;16-Mar-2023 - ECMD (Graz), updated data archive URL
  site = 'http://dataarchive.stix.i4ds.net/fits/L1/2022/02/'
  
  ;The OSPEX folder in under stx_demo_data will usually start off empty on initial installation of the STIX software
  out_dir = concat_dir( getenv('STX_DEMO_DATA'),'ospex', /d)

  ;if the OSPEX demo database folder is not present then create it
  if ~file_test(out_dir, /directory) then begin
    file_mkdir, out_dir
  endif

  ;As an example a spectrogram (Level 4) file for a flare on 8th February 2022 is used
  l4_filename = 'solo_L1_stix-sci-xray-spec_20220208T212353-20220208T223255_V01_2202080003-58150.fits'

  ;Download the spectrogram fits file to the stix/dbase/demo/ospex/ directory
  sock_copy, site + '08/SCI/' + l4_filename, status = status, out_dir = out_dir

  ;An observation of a non-flaring quiet time close to the flare observation can be used as a background estimate
  bk_filename  = 'solo_L1_stix-sci-xray-cpd_20220209T002721-20220209T021401_V01_2202090020-58535.fits'
  sock_copy, site + '09/SCI/'+ bk_filename, status = status, out_dir = out_dir

  ;As well as the summed spectrogram a pixel data observation of the same event is also available
  l1_filename = 'solo_L1_stix-sci-xray-cpd_20220208T212833-20220208T222055_V01_2202080013-58504.fits'
  sock_copy, site + '08/SCI/' + l1_filename, status = status, out_dir = out_dir

  ;Now they have been dowloaded set the paths of the science data files
  fits_path_data_l4 = loc_file(l4_filename, path = out_dir )
  fits_path_bk   = loc_file(bk_filename, path = out_dir )
  fits_path_data_l1   = loc_file(l1_filename, path = out_dir)
  
  ;read the of the primary HDU of the spectrogram file to obtain the header which contains key information
  !null = mrdfits(fits_path_data_l4, 0, primary_header)

  ; the start time of the event is contained in the primary header
  ; most times contained in the file are relative to this
  header_start_time = (sxpar(primary_header, 'DATE-BEG'))
  print, 'Event start time :  ',  header_start_time
  print, " "
  ;For correct energy calibration in is necessary to determine the Energy Lookup Table (ELUT)
  ; applied in flight when the observation was taken
  elut_filename = stx_date2elut_file(header_start_time)
  print, 'The ELUT applied at this time was : ', elut_filename
  print, " "

  ;The procedure can be used to provide the ELUT given the date in any anytim compatible format
  print, stx_date2elut_file('2022-02-08')

  ;The primary header also contains values for some parameters needed for spectroscopy related to the changing spacecraft location.
  ; distance - the distance between the Sun and Solar Orbiter in AU
  ; time_shift - the difference in light travel time between the Sun centre to Earth and the Sun centre to Solar Orbiter in seconds
  ;The average light travel time and spacecraft distance are in the FITS headers of the science data files
  ;and can be read out using the routine stx_get_header_corrections.pro
  ;we keep the time and distance information as keywords as the correction applied depends somewhat on how detailed the user needs to be.
  stx_get_header_corrections, fits_path_data_l4, distance = distance, time_shift = time_shift

  print, 'The Solar Orbiter distance to the Sun was :'
  print, distance, ' AU'
  print, 'The light travel time correction was :'
  print, time_shift,' s'
  print, " "
  print, "Press SPACE to continue"
  print, " "
  pause

  ;*********************************************** 2 - DEFINE OSPEX PARAMETERS  ******************************************************

  ;For Reading the STIX specific spectrum and response matrix files
  spex_file_reader= 'stx_read_sp'

  ;The names of the OSPEX compatible spectrum and corresponding response matrix file are based on the observation start time
  spex_specfile_l4= 'stx_spectrum_2202080003.fits'
  spex_drmfile_l4= 'stx_srm_2202080003.fits'

  spex_specfile_l1= 'stx_spectrum_2202080013.fits'
  spex_drmfile_l1= 'stx_srm_2202080013.fits'


  ;At the low end we fit to the lowest science energy STIX observes of 4 keV
  ;For up to moderate events the science energy channels 28 - 32 keV and 32 - 36 keV are dominated by lines in the
  ;calibration source are 31 and 35 keV. For this events it is reasonable to fit up to 28 keV
  spex_erange= [4.0000000D, 28.000000D]

  ;The fit interval selected for this demonstration covers one minute over the first non-thermal peak
  spex_fit_time_interval = ['8-Feb-2022 21:38:59.937', '8-Feb-2022 21:40:00.437']

  ;The pre-flare background is taken as a five minute interval before the start of the flare
  ;where the count rate in all bands are steady
  spex_bk_time_interval =  ['8-Feb-2022 21:25:53.136', '8-Feb-2022 21:30:53.136']

  ;As the STIX instrument is still being fully calibrated an uniform systematic uncertainty of 5% is applied here
  spex_uncert= 0.0500000

  ;the fit is done using a standard combination of thermal (f_vth) and non-thermal power-law (f_thick2) functions
  fit_function= 'vth+thick2'

  ;The initial fit parameters are adjusted manually to get a good starting point for the fit.
  ; The parameter definitions as found in f_vth.pro and f_thick2.pro :
  ;   fit_comp_params[0] - Emission measure in units of 10^49
  ;   fit_comp_params[1] - KT, plasma temperature in keV
  ;   fit_comp_params[2] - Abundance relative to coronal for Fe, Ni, Si, and Ca. S as well at half the deviation from 1 as Fe.
  ;   fit_comp_params[3] - Total integrated electron flux, in units of 10^35 electrons sec^-1.
  ;   fit_comp_params[4] - Power-law index of the electron flux distribution function below the break energy.
  ;   fit_comp_params[4] - Break energy in the electron flux distribution function in keV
  ;   fit_comp_params[5] - Power-law index of the electron flux distribution function above the break energy.
  ;   fit_comp_params[6] - Low energy cutoff in the electron flux distribution function in keV.
  ;   fit_comp_params[7] - High energy cutoff in the electron flux distribution function in keV.
  fit_comp_params= [0.05, 1.1, 1.00000, 0.5, 6. , 15000.0,  6.00000, 15., 32000.0]

  ;As there are a limited number of science energy channels the non-thermal thick target fit is limited to a
  ;single powerlaw index.
  ;Emission Measure, Temperature, Thick target normalisation, Power-law index of the electron flux distribution function below
  ;the break energy and the low energy cutoff are free all other parameters are fixed.
  fit_comp_free_mask= [1B, 1B, 0B, 1B, 1B, 0B, 0B, 1B, 0B]

  ;For the other fitting parameters the OSPEX defaults are adequate
  fit_comp_minima= [1.00000e-20, 0.500000, 0.0100000, 1.00000e-10, 1.10000, $
    1.00000, 1.10000, 1.00000, 100.000]
  fit_comp_maxima= [1.00000e+20, 8.00000, 10.0000, 1.00000e+10, 20.0000, 100000., $
    20.0000, 1000.00, 1.00000e+07]
  fit_comp_spectrum = ['full', '']
  fit_comp_model = ['chianti', '']

  ;Set the relevant plotting options
  spex_autoplot_units= 'Flux'
  spex_autoplot_enable = 1
  spex_fitcomp_plot_err = 1

  ;*********************************************** 3 -First fit - Spectrogram with pre-flare background selected  ******************************************************

  ;The main routine to convert the spectrogram (L4) data to an OSPEX compatible format is stx_convert_spectrogram
  ;Several necessary corrections are also applied to the data here
  ;After this is called the spectrum and srm FITS files will be generated.
  ;The routine will load these files into an OSPEX object which is it will also pass out so that further parameters
  ;can be applied and the fitting performed.
  stx_convert_spectrogram, $
    fits_path_data = fits_path_data_l4, $
    distance = distance, $
    time_shift = time_shift, $
    ospex_obj = ospex_obj_l4

  ;set the values as defined in section 2 above for this object
  ospex_obj_l4-> set, spex_file_reader = spex_file_reader
  ospex_obj_l4-> set, spex_specfile = spex_specfile_l4
  ospex_obj_l4-> set, spex_drmfile = spex_drmfile_l4
  ospex_obj_l4-> set, spex_erange = spex_erange
  ospex_obj_l4-> set, spex_fit_time_interval = spex_fit_time_interval
  ospex_obj_l4-> set, spex_bk_time_interval = spex_bk_time_interval
  ospex_obj_l4-> set, spex_uncert = spex_uncert
  ospex_obj_l4-> set, fit_function = fit_function
  ospex_obj_l4-> set, fit_comp_params = fit_comp_params
  ospex_obj_l4-> set, fit_comp_minima = fit_comp_minima
  ospex_obj_l4-> set, fit_comp_maxima= fit_comp_maxima
  ospex_obj_l4-> set, fit_comp_free_mask = fit_comp_free_mask
  ospex_obj_l4-> set, fit_comp_spectrum = fit_comp_spectrum
  ospex_obj_l4-> set, fit_comp_model = fit_comp_model
  ospex_obj_l4-> set, spex_autoplot_enable=spex_autoplot_enable
  ospex_obj_l4-> set, spex_autoplot_units = spex_autoplot_units
  ospex_obj_l4-> set, spex_autoplot_show_err = spex_fitcomp_plot_err
  ospex_obj_l4-> set, spex_fitcomp_plot_err = spex_fitcomp_plot_err

  print, " "
  print, 'Please fit the spectrum - When you are satisfied select "Accept -> and continue looping" '
  print, " "

  ospex_obj_l4-> dofit

  ;Print the information about the spectrum file
  fits_info, spex_specfile_l4

  ;The data extensions and their headers can be read in individually using standard FITS reading methods
  !null = mrdfits(spex_specfile_l4, 0, primary_header_spec)
  rate = mrdfits(spex_specfile_l4, 1, rate_header, /unsigned)
  energy = mrdfits(spex_specfile_l4, 2, energy_header, /unsigned)

  ;the information about the response matrix file can similarly be displayed
  fits_info, spex_drmfile_l4

  print, " "
  print, "Press SPACE to continue"
  print, " "
  pause


  ;*********************************************** 4 - Second fit - Spectrogram with externally supplied background observation  ******************************************************

  ;For the second method the routine stx_convert_spectrogram.pro is again called with the filename, distance and time_shift keywords
  ;Additionally the file name of a L1 pixel data background observation is supplied. In this case the background is subtracted from the flare
  ;data before the spectrum file is generated.
  ;Note that currently the type of background accepted is currently limited to compaction Level 1 (Compressed Pixel Data)
  stx_convert_spectrogram, $
    fits_path_data = fits_path_data_l4, $
    fits_path_bk = fits_path_bk, $
    distance = distance, $
    time_shift = time_shift, $
    ospex_obj = ospex_obj_l4b

  ;set the values as defined in section 2 above for this object - these are identical to those set for the pervious fit
  ospex_obj_l4b-> set, spex_file_reader = spex_file_reader
  ospex_obj_l4b-> set, spex_specfile = spex_specfile_l4
  ospex_obj_l4b-> set, spex_drmfile = spex_drmfile_l4
  ospex_obj_l4b-> set, spex_erange = spex_erange
  ospex_obj_l4b-> set, spex_fit_time_interval = spex_fit_time_interval
  ospex_obj_l4b-> set, spex_uncert = spex_uncert
  ospex_obj_l4b-> set, fit_function = fit_function
  ospex_obj_l4b-> set, fit_comp_params = fit_comp_params
  ospex_obj_l4b-> set, fit_comp_minima = fit_comp_minima
  ospex_obj_l4b-> set, fit_comp_maxima = fit_comp_maxima
  ospex_obj_l4b-> set, fit_comp_free_mask = fit_comp_free_mask
  ospex_obj_l4b-> set, fit_comp_spectrum = fit_comp_spectrum
  ospex_obj_l4b-> set, fit_comp_model = fit_comp_model
  ospex_obj_l4b-> set, spex_autoplot_enable=spex_autoplot_enable
  ospex_obj_l4b-> set, spex_autoplot_units = spex_autoplot_units
  ospex_obj_l4b-> set, spex_autoplot_show_err = spex_fitcomp_plot_err
  ospex_obj_l4b-> set, spex_fitcomp_plot_err = spex_fitcomp_plot_err

  print, " "
  print, 'Please fit the spectrum - When you are satisfied select "Accept -> and continue looping" '
  print, " "
  ospex_obj_l4b-> dofit

  ;*********************************************** 5 - Third fit - Pixel data with externally supplied background observation  ******************************************************
  ;For the third method a different routine is called stx_convert_pixel_data.pro this converts a L1 pixel data background observation to an OSPEX compatible spectrum file in
  ;a very similar manner to stx_convert_spectrogram.pro it takes many of the same keywords. Again the filename, distance and time_shift keywords should be supplied
  ;L1 data is usually downloaded for every individual pixel meaning that more accurate calibration can be applied
  ;The effect of onboard data compression is also reduced. However as this format requires a much higher volume of telemetry often the temporal resolution will
  ;be reduced.
  stx_convert_pixel_data, $
    fits_path_data = fits_path_data_l1,$
    fits_path_bk = fits_path_bk, $
    distance = distance, $
    time_shift = time_shift, $
    ospex_obj = ospex_obj_l1

  ;set the values as defined in section 2 above for this object - only the file names of the spectrum and response matrix file are changed with
  ;respect to the previous two fits
  ospex_obj_l1-> set, spex_file_reader = spex_file_reader
  ospex_obj_l1-> set, spex_specfile = spex_specfile_l1
  ospex_obj_l1-> set, spex_drmfile = spex_drmfile_l1
  ospex_obj_l1-> set, spex_erange = spex_erange
  ospex_obj_l1-> set, spex_fit_time_interval = spex_fit_time_interval
  ospex_obj_l1-> set, spex_uncert = spex_uncert
  ospex_obj_l1-> set, fit_function = fit_function
  ospex_obj_l1-> set, fit_comp_params = fit_comp_params
  ospex_obj_l1-> set, fit_comp_minima = fit_comp_minima
  ospex_obj_l1-> set, fit_comp_maxima= fit_comp_maxima
  ospex_obj_l1-> set, fit_comp_free_mask = fit_comp_free_mask
  ospex_obj_l1-> set, fit_comp_spectrum = fit_comp_spectrum
  ospex_obj_l1-> set, fit_comp_model = fit_comp_model
  ospex_obj_l1-> set, spex_autoplot_enable=spex_autoplot_enable
  ospex_obj_l1-> set, spex_autoplot_units = spex_autoplot_units
  ospex_obj_l1-> set, spex_autoplot_show_err = spex_fitcomp_plot_err
  ospex_obj_l1-> set, spex_fitcomp_plot_err = spex_fitcomp_plot_err

  print, " "
  print, 'Please fit the spectrum - When you are satisfied select "Accept -> and continue looping" '
  print, " "

  ospex_obj_l1-> dofit

  ;*********************************************** 6 - COMPARISON ******************************************************
  ;Compare the results of the three different approaches to fitting a given interval

  ;As not all function parameters are used in these fits select only the ones
  fit_free_l4 = ospex_obj_l4 -> get(/fit_comp_free)
  idx_free =  where(fit_free_l4 eq 1, nfree)

  ;retrieve the fit parameters and their errors from the previously returned OSPEX objects
  fit_params_l4 = ospex_obj_l4 -> get(/fit_comp_params)
  fit_sigmas_l4 = ospex_obj_l4 -> get(/fit_comp_sigmas)

  fit_params_l4b = ospex_obj_l4b -> get(/fit_comp_params)
  fit_sigmas_l4b = ospex_obj_l4b -> get(/fit_comp_sigmas)

  fit_params_l1 = ospex_obj_l1 -> get(/fit_comp_params)
  fit_sigmas_l1 = ospex_obj_l1 -> get(/fit_comp_sigmas)

  ;The expected values were estimated by performing manual fits to the same intervals using the GSW as of 09-Mar-2022
  fit_params_expected_l4= [0.04827, 1.116, 1.000, 0.5163, 6.053, 1.500e+05, 9.000, 14.66, 3.200e+04]
  fit_sigmas_expected_l4= [0.01236, 0.04528, 0.000, 0.2079, 0.2249, 0.000, 0.000, 1.293, 0.000]

  fit_params_expected_l4b = [0.04580, 1.125, 1.000, 0.5269, 5.845, 1.500e+04, 9.000, 14.29, 3.200e+04]
  fit_sigmas_expected_l4b = [0.01205, 0.04785, 0.000, 0.2519, 0.1552, 0.000, 0.000, 1.447, 0.000]

  fit_params_expected_l1 = [0.04626, 1.130, 1.000, 0.5819, 5.788, 1.500e+04, 9.000, 14.11, 3.200e+04]
  fit_sigmas_expected_l1 = [0.009982, 0.05223, 0.000, 0.2090, 0.08839, 0.000, 0.000, 1.577, 0.000]

  linecolors
  ;plot a comparison and the expected and newly fit values for the spectrogram with pre-flare background case
  window, 0
  ploterr, findgen(nfree), fit_params_l4[idx_free]/fit_params_expected_l4[idx_free], fit_params_l4[idx_free]*0., fit_sigmas_l4[idx_free]/fit_params_expected_l4[idx_free], $
    ytitle ='Parameters Normalised to expected value',xtitle = 'Parameter name',yrange  = [0, 2], xtickname = [ 'EM','kT', 'NT Flux','Delta','Ebrk','E0' ], $
    xst = 2, title = 'Spectrogram'
  oploterr, findgen(nfree), fit_params_expected_l4[idx_free]/fit_params_expected_l4[idx_free], fit_params_l4[idx_free]*0., fit_sigmas_expected_l4[idx_free]/fit_params_expected_l4[idx_free], color = 9, line = 2, errcolor = 9
  al_legend,['Expected','Fitted'],colors=[255,9],linest=[0,2],textcolors=[255,9],charsize=1.3

  ;plot a comparison and the expected and newly fit values for the spectrogram with background observation subtracted case
  window, 1
  ploterr, findgen(nfree), fit_params_l4b[idx_free]/fit_params_expected_l4b[idx_free], fit_params_l4b[idx_free]*0., fit_sigmas_l4b[idx_free]/fit_params_expected_l4b[idx_free], $
    ytitle ='Parameters Normalised to expected value',xtitle = 'Parameter name',yrange  = [0, 2], xtickname = [ 'EM','kT', 'NT Flux','Delta','Ebrk','E0' ],$
    xst = 2, title = 'Spectrogram presubtracted'
  oploterr, findgen(nfree), fit_params_expected_l4b[idx_free]/fit_params_expected_l4b[idx_free], fit_params_l4b[idx_free]*0., fit_sigmas_expected_l4b[idx_free]/fit_params_expected_l4b[idx_free], color = 9, line = 2, errcolor = 9
  al_legend,['Expected','Fitted'],colors=[255,9],linest=[0,2],textcolors=[255,9],charsize=1.3

  ;plot a comparison and the expected and newly fit values for the pixel data with background observation subtracted case
  window, 2
  ploterr, findgen(nfree), fit_params_l1[idx_free]/fit_params_expected_l1[idx_free], fit_params_l1[idx_free]*0., fit_sigmas_l1[idx_free]/fit_params_expected_l1[idx_free], $
    ytitle ='Parameters Normalised to expected value',xtitle = 'Parameter name',yrange  = [0, 2], xtickname = [ 'EM','kT', 'NT Flux','Delta','Ebrk','E0' ], $
    xst = 2, title = 'Pixel Data'
  oploterr, findgen(nfree), fit_params_expected_l1[idx_free]/fit_params_expected_l1[idx_free], fit_params_l1[idx_free]*0., fit_sigmas_expected_l1[idx_free]/fit_params_expected_l1[idx_free], color = 9, line = 2, errcolor = 9
  al_legend,['Expected','Fitted'],colors=[255,9],linest=[0,2],textcolors=[255,9],charsize=1.3

  ;plot a comparison of the newly fit values for all three cases
  window, 3
  ploterr, findgen(nfree), fit_params_l4b[idx_free]/fit_params_l4b[idx_free], fit_params_l4[idx_free]*0., fit_sigmas_l4[idx_free]/fit_params_l4b[idx_free], $
    ytitle ='Prarmeter Normalised to Spectrogram estimate',xtitle = 'Parameter name',yrange  = [0, 2], xtickname = [ 'EM','kT', 'NT Flux','Delta','Ebrk','E0' ], xst = 2, HATLENGTH = 15
  oploterr, findgen(nfree), fit_params_l1[idx_free]/fit_params_l4b[idx_free], fit_params_l4[idx_free]*0., fit_sigmas_l1[idx_free]/fit_params_l4b[idx_free], color = 4, line = 2, errcolor = 4
  oploterr, findgen(nfree), fit_params_l4[idx_free]/fit_params_l4b[idx_free], fit_params_l4[idx_free]*0., fit_sigmas_l4[idx_free]/fit_params_l4b[idx_free], color = 2, line = 2, errcolor = 2
  al_legend,['Spectrogram presubtracted','Spectrogram','Pixel Data'],colors=[255,2,4],linest=[0,2,2],textcolors=[255,2,4],charsize=1.3


  stop
end