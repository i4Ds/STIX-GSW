;+
; :description:
;  This function reads a quicklook calibration fits file into a stx_asw_ql_calibration_spectrum structure along with associated data from the file
;
; :categories:
;  calibration, fits
;
; :params:
;
;  fits_path                  : in, required, type="string"
;                               path to the calibration fits file to be read in
;
; :keywords:
;
;  primary_header             : out, type="strarr"
;                               primary header data from the calibration FITS file
;
;  rate_str                   : out, type="structure"
;                               data from rate extension of the calibration FITS file
;
;
;  rate_header                : out, type="strarr"
;                               header data from the rate extension of the calibration FITS file
;
;  control_str                : out, type="structure"
;                               data from the control extension of the calibration FITS file
;
;  control_header             : out, type="strarr"
;                               header data from the rate extension of the calibration FITS file
;
;
; subspectra_definition       : out, type="int arr"
;                               3 x number of calibartion subspectra in the file.
;                               Each subspectrum is defined by three parameters: lowest ADC channel, number of summed channels, and number spectral points
;
; pixel_mask                  : out, type="byte arr"
;                               12 element mask of which pixels are inclued
;
;
; detector_mask               : out, type="byte arr"
;                               32 element mask of which detectors are inclued
;
;
; subspectrum_mask            : out, type="byte arr"
;                               8 element mask of which subspectra are inclued
;
;
; start_time                  : out, type="stx_time structure"
;                               start time of calibration spectrum accumulation
;
;
; end_time                    : out, type="stx_time structure"
;                               end time of calibration spectrum accumulation
;
;
; subspectra_info             : out, type="structure"
;                               structure containing the subspectrum definition information as separate arrays for each parameter
;
; :returns:
;
;  asw_ql_calibration_spectrum : stx_asw_ql_calibration_spectrum structure containing the spectra read in from the file
;
; :examples:
;
; asw_ql_calibration_spectrum =  stx_read_calibration_fits_file( '/data/2020/04/27/quicklook', rate_str = rate_str,rate_header = rate_header, control_str= control_str,control_header= control_header, $
;      subspectra_definition = subspectra_definition, pixel_mask= pixel_mask, detector_mask = detector_mask,subspectrum_mask = subspectrum_mask, $
;      subspectra_info = subspectra_info, start_time = start_time, end_time = end_time)
;
;
; :history:
;    21-Jul-2020 - ECMD (Graz), initial release
;
;-
function stx_read_calibration_fits_file, fits_path, primary_header = primary_header, rate_str = rate,rate_header = rate_header, control_str = control,control_header= control_header, $
  subspectra_definition = subspectra_definition, pixel_mask= pixel_mask, detector_mask = detector_mask, subspectrum_mask = subspectrum_mask,  $
  start_time = start_time, end_time = end_time, subspectra_info = subspectra_info

  ; read the data from the fits file.
  !null = mrdfits(fits_path, 0, primary_header)
  rate = mrdfits(fits_path, 1, rate_header)
  control = mrdfits(fits_path, 2, control_header)

  ; The FITS format for Ground Unit data was originally different
  dum =  where(tag_names(control) eq 'SUBSPEC1_NUM_POINTS',oldformat)

  ;convert the header to a structure to more easily parse the time information
  primary_header_str = fitshead2struct( primary_header )

  indices_used_subspectra = where(control.subspectrum_mask eq 1, nmbr_subspectra)
  ; Store the subspectra
  ; First create a calibration spectrum object
  pixel_mask= control.pixel_mask
  detector_mask=control.detector_mask
  subspectrum_mask=control.subspectrum_mask


  loop_P = fix(total(pixel_mask))
  loop_D = fix(total(detector_mask))
  loop_S = fix(total(subspectrum_mask))

  ; the older format packages the subspectra definition in a more similar manner to
  ; the telemetry packets so this must be formatted as arrays here
  if oldformat then begin

    ; dynamic size is depending on subspectra definition
    nbr_spec_poins = intarr(8)
    nbr_spec_poins[0]= control.subspec1_num_points +1
    nbr_spec_poins[1]= control.subspec2_num_points +1
    nbr_spec_poins[2]= control.subspec3_num_points +1
    nbr_spec_poins[3]= control.subspec4_num_points +1
    nbr_spec_poins[4]= control.subspec5_num_points +1
    nbr_spec_poins[5]= control.subspec6_num_points +1
    nbr_spec_poins[6]= control.subspec7_num_points +1
    nbr_spec_poins[7]= control.subspec8_num_points +1
    nbr_sum_channels = intarr(8)
    nbr_sum_channels[0]= control.subspec1_num_summed +1
    nbr_sum_channels[1]= control.subspec2_num_summed +1
    nbr_sum_channels[2]= control.subspec3_num_summed +1
    nbr_sum_channels[3]= control.subspec4_num_summed +1
    nbr_sum_channels[4]= control.subspec5_num_summed +1
    nbr_sum_channels[5]= control.subspec6_num_summed +1
    nbr_sum_channels[6]= control.subspec7_num_summed +1
    nbr_sum_channels[7]= control.subspec8_num_summed +1
    lowest_channel = intarr(8)
    lowest_channel[0]= control.subspec1_low_chan
    lowest_channel[1]= control.subspec2_low_chan
    lowest_channel[2]= control.subspec3_low_chan
    lowest_channel[3]= control.subspec4_low_chan
    lowest_channel[4]= control.subspec5_low_chan
    lowest_channel[5]= control.subspec6_low_chan
    lowest_channel[6]= control.subspec7_low_chan
    lowest_channel[7]= control.subspec8_low_chan

  endif else begin
    ;in the new format the subspectra definition can be read more directly from the file
    nbr_spec_poins =  control.subspec_num_points + 1 ; the telemetry format specifies subspec_num_points - 1
    nbr_sum_channels = control.subspec_num_summed_channel + 1; the tememetry format specifies subspec_num_summed_channel - 1
    lowest_channel= control.subspec_lowest_channel

  endelse

  subspectra_info = {nbr_spec_poins:nbr_spec_poins,nbr_sum_channels:nbr_sum_channels,lowest_channel:lowest_channel }

  ; create subspectra_definition
  subspectra_definition=intarr(3,loop_S)

  ; create a list of subspectra arrays
  ; we have to use a pointer array as editing the prepared arrays in a list does not work
  subspectra = ptrarr(loop_S)
  for i=0, loop_S-1 do begin
    subspectra_definition[*,i] = [lowest_channel[i], nbr_sum_channels[i], nbr_spec_poins[i]]
    subspectra[i] = ptr_new(lonarr(nbr_spec_poins[i] ,loop_P,loop_D),/no_copy)
  endfor

  ; init counter for number of structures
  total_number_of_structures=0
  det_id = 0
  pix_id = 0
  spc_id = 0

  ; get other static information out of header
  duration = control.duration
  quiet_time = control.quiet_time
  live_time = control.live_time
  average_temp = control.average_temp

  for idx = 0L, (size(rate, /DIM))[0]-1 do begin

    det_id = rate[idx].DETECTOR_ID
    pix_id = rate[idx].PIXEL_ID
    first_point =0

    for spc_id = 0, loop_S-1 do begin
      ; the calibration spectra in the telemetry files are in the format of a structure with n_detectors*n_pixel elements
      ; each with a counts array of [subspec1_num_summed + subspec2_num_summed + ... + subspec8_num_summed] elements.
      ; Here this array is transformed into separate sub spectra so it can go a stx_asw_ql_calibration_subspectrum structure
      (*subspectra[spc_id])[*,pix_id,det_id] =  rate[idx].counts[first_point:first_point+nbr_spec_poins[spc_id]-1]
      first_point +=nbr_spec_poins[spc_id]

    endfor
  endfor

  ; create time object
  stx_time_obj = stx_time()
  stx_time_obj.value =  anytim(primary_header_str.date_obs , /mjd)
  start_time = stx_time_add(stx_time_obj, seconds = 0)
  end_time = stx_time_add(start_time, seconds = duration)


  calsubspec = list()
  for i=0, loop_S-1 do begin
    ;add stx_asw_ql_calibration_subspectrum structures for each of the subspectra to a single list
    calsubspec.add, stx_asw_ql_calibration_subspectrum(spectral_points = (*subspectra[i]), $
      subspectra_definition = subspectra_definition[*,i], pixel_mask = pixel_mask, detector_mask = detector_mask)
  endfor

  ;create stx_asw_ql_calibration_spectrum object with spectra from file
  asw_ql_calibration_spectrum = stx_asw_ql_calibration_spectrum(calsubspec = calsubspec, $
    start_time = start_time, end_time = end_time)

  return, asw_ql_calibration_spectrum
end

