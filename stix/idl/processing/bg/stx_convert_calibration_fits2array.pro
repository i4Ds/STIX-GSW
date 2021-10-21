;+
; :description:
;
;  This function checks all files in the specified directory and reads the calibration fits files. The spectra are put into an array and the associated
;  metadata is stored in a structure. These variables can be optionally saved to a genx file.
;
; :categories:
;
;  calibration, FITS
;
; :params:
;
;  l1_directory                     : in, type="string"
;                                     path to directory containing the level 1 quicklook calibration spectrum fits files
;
; :keywords:
;
;
;  save                             : in, type="byte", default="1"
;                                     if set the spec_array and calibration_info variables will be saved to a genx file
;
;  calibration_info                 : out, type="stx_calibration_info structure"
;                                     structure containing the metadata from each FITS file
;
;  asw_ql_calibration_spectra       : out, type="list"
;                                     list of stx_asw_ql_calibration_spectrum structures corresponding to the read in spectra
;
;  sub_definitions                  : out, type="list"
;                                     list of subspectra_definition arrays for each file
;
;
; :returns:
;
;  spec_array                       : type="float"
;                                     array of dimension [1024 ADC channels x 12 pixels x 32 detectors x  N calibration runs]
;                                     containing the expanded calibration spectra
;
; :examples:
;
;  calibration_spectrum_array =  stx_convert_calibration_fits2array( '/data/2020/04/27/quicklook', asw_ql_calibration_spectra = asw_ql_calibration_spectra, $
;                                calibration_info =calibration_info, save = save )
;
; :history:
;    21-Jul-2020 - ECMD (Graz), initial release
;
;-
function stx_convert_calibration_fits2array, l1_directory, save = save, calibration_info= calibration_info, $
  asw_ql_calibration_spectra = asw_ql_calibration_spectra, sub_definitions  = sub_definitions

  default, save, 1

  ; find all FITS files in the Level 1 directory
  ff = file_search(l1_directory, '*.fits')

  ; filter to get the calibration spectrum files using the file names
  w = where(STRMATCH(ff, '*calibration-spectrum*') eq 1, nfiles)

  ; metadata and other information not directly contained in the spectrum is contained in a stx_calibration_info structure
  calibration_info = stx_calibration_info()

  ;as the stx_calibration_info structure contains information specific to the file
  calibration_info = replicate(calibration_info, nfiles)

  ;
  asw_ql_calibration_spectra = list()

  ;the subspectral definition arrays for each file are included separately in a list
  sub_definitions = list()

  ;loop over each file found
  for ifile = 0,  nfiles-1 do begin

    fits_path =ff[w[ifile]]
    fits_filename = file_basename(fits_path)

    ; the reading of the fits file and conversion to stx_asw_ql_calibration_spectrum structure is done here
    ; the other metadata from the file is also read here and passed out
    asw_ql_calibration_spectrum =  stx_read_calibration_fits_file( fits_path, rate_str = rate_str,rate_header = rate_header, control_str= control_str,control_header= control_header, $
      subspectra_definition = subspectra_definition, pixel_mask = pixel_mask, detector_mask = detector_mask,subspectrum_mask = subspectrum_mask, $
      subspectra_info= subspectra_info, start_time = start_time, end_time = end_time)

    ;the read information for the spectrum structure and the definition arrays are added to the corresponding lists
    sub_definitions.add, subspectra_definition
    asw_ql_calibration_spectra.add,  asw_ql_calibration_spectrum

    ;get the necessary information out of the control extension strucure
    duration = control_str.duration
    quiet_time = control_str.quiet_time
    live_time = control_str.live_time
    average_temp = control_str.average_temp

    ;the metadata corresponding to the current file is added to the calibration_info structure with some basic conversion
    ;to science value, in these cases the raw variable is also included in the structure
    calibration_info[ifile].filename = fits_filename
    calibration_info[ifile].start_time = start_time
    calibration_info[ifile].end_time = end_time
    calibration_info[ifile].duration =  duration
    calibration_info[ifile].quiet_time_raw = quiet_time
    calibration_info[ifile].live_time_raw = live_time
    calibration_info[ifile].average_temp_raw = average_temp
    calibration_info[ifile].quiet_time = quiet_time*15.2588e-6
    calibration_info[ifile].live_time = float(live_time)/1000.
    calibration_info[ifile].average_temp = stx_temp_convert(average_temp)
    calibration_info[ifile].pixel_mask = pixel_mask
    calibration_info[ifile].detector_mask = detector_mask
    calibration_info[ifile].subspectrum_mask = subspectrum_mask
    calibration_info[ifile].nbr_spec_poins = subspectra_info.nbr_spec_poins
    calibration_info[ifile].nbr_sum_channels = subspectra_info.nbr_sum_channels
    calibration_info[ifile].lowest_channel = subspectra_info.lowest_channel

  endfor

  ;each entry in the asw_ql_calibration_spectra list corresponds to a different calibration run
  nrun = asw_ql_calibration_spectra.count()

  ;make an empty array to store the expanded calibration spectra. It is of type float to avoid integer round off errors when
  ;expanding coarsely binned subspectra
  spec_array = fltarr( 1024, 12,32, nrun)

  ;the expansion of the subspectra into a single spectrum is done here
  for irun = 0,nrun-1 do spec_array[0, 0, 0, irun] = stx_calibration_data_array( asw_ql_calibration_spectra[irun])

  ;optionally safe the calibration spectrum array and the information structure to a genx file
  if keyword_set(save) then begin

    savename = 'calibration_data_' + time2fid(atime(stx_time2any(asw_ql_calibration_spectra[0].start_time)) , /full, /time) + '.genx'

    savegen, spec_array, calibration_info, file = savename
  endif

  return, spec_array
end
