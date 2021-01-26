;+
; :description:
;  This procedure demonstrates the reading of a quicklook calibration FITS file, creating an array of the data and plotting each spectrum 
;
; :categories:
;  calibration, demo, FITS
;
;
; :keywords:
;
;  directory                                     : in, type="string"
;                                                  path to directory containing the level 1 quicklook calibration spectrum fits files
;
;  save                                          : in, type="byte", default="1"
;                                                  if set the spec_array and calibration_info variables will be saved to a genx file
;  
;  plotting                                      : in, type="byte", default="1"
;                                                  if set the a postscript file will be generated containing plots of each calibration spectrum 
;
;
;  asw_ql_calibration_spectra                    : out, type="list"
;                                                  list of stx_asw_ql_calibration_spectrum structures corresponding to the read in spectra
;
;  calibration_info                              : out, type="stx_calibration_info structure"
;                                                  list of stx_asw_ql_calibration_spectrum corresponding to the spectra
;
;  calibration_spectrum_array                    : out, type="float"
;                                                  array of dimension [1024 ADC channels x 12 pixels x 32 detectors x  N calibration runs]
;                                                  containing the expanded calibration spectra
;
;
; :examples:
;
;  stx_calibration_fits_demo, directory = '/data/2020/04/27/quicklook'
;
; :history:
;    21-jul-2020 - ECMD (Graz), initial release
;    19-Nov-2020 - ECMD (Graz), added _extra keywords for pass through of plotting commands, stx_plot_calibration_run now takes additional info 
;                               from the calibration_info structure 
;        
;
;-
pro stx_calibration_fits_demo,  directory = directory, save = save,  separate_plots= separate_plots, $
  asw_ql_calibration_spectra = asw_ql_calibration_spectra,  calibration_info = calibration_info, calibration_spectrum_array = calibration_spectrum_array, $
  plotting = plotting, _extra = _extra

  ;default when running the demo is both to save the spectra array to file and to produce postscript plots
  default, directory, '/data/2020/04/27/quicklook'
  default, save, 1
  default, plotting, 1

  ;  all quicklook calibration spectrum fits files are read from the specified directory
  calibration_spectrum_array =  stx_convert_calibration_fits2array( directory, asw_ql_calibration_spectra = asw_ql_calibration_spectra, $
    calibration_info = calibration_info, save = save )


  if plotting then begin
    
    stx_plot_calibration_run, calibration_spectrum_array, calibration_info, _extra = _extra

  endif

end

