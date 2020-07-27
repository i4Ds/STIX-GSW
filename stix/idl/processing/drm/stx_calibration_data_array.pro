;+
; :description:
;    This function converts calibration data structures in telemetry subspectrum format 
;    to an array of [1024, 12, 32 ] ([adc1024_channels, pixels, detectors]) suitable for the
;    extraction of parameters via OSPEX
;
; :categories:
;    gsw, ql, calibration
;
; :params:
;    input
;
; :Keywords:
;    list_index - use this index if there is more than one cal spectrum entry
;    start_time - return the start_time, stix format, for the data set
;    end_time   - return the end_time, stix format, for the data set
;    pixel_mask - return the pixel_mask used or input one to use for the data set
;    detector_mask - return the detector_mask used or input one to use for the data set
;

; :returns:
;   returns the calibration spectra for all pixels and detectors expanded to
;
;
; :examples:
;
;  calibration_spectrum = stx_calibration_data_array(tmtc_calibration_spectra, pixel_mask = pixel_mask , detector_mask = detector_mask )
;    IDL> help, asw
;    ASW             LIST  <ID=273856  NELEMENTS=21>
;    IDL> help, asw[0]
;    ** Structure <17bc8cb0>, 4 tags, length=40, data length=36, refs=3:
;    TYPE            STRING    'stx_asw_ql_calibration_spectrum'
;    START_TIME      STRUCT    -> STX_TIME Array[1]
;    END_TIME        STRUCT    -> STX_TIME Array[1]
;    SUBSPECTRA      OBJREF    <ObjHeapVar273857(LIST)>
;    IDL> help, total(stx_calibration_data_array( asw, list_index=0,start=start, end_time=end_time)) &help, anytim(start.value,/vms)
;    <Expression>    FLOAT     =  2.25109e+006
;    <Expression>    STRING    = '30-Sep-1998 14:16:28.000'
;    IDL> help, stx_calibration_data_array( asw[0],start=start, end_time=end_time) &help, anytim(start.value,/vms)
;    <Expression>    FLOAT     = Array[1024, 12, 32]
;    <Expression>    STRING    = '30-Sep-1998 14:16:28.000'
;    IDL> help, stx_calibration_data_array( asw[10],start=start, end_time=end_time) &help, anytim(start.value,/vms)
;    <Expression>    FLOAT     = Array[1024, 12, 32]
;    <Expression>    STRING    = '30-Sep-1998 14:16:28.000'
;    IDL> help, total(stx_calibration_data_array( asw[0],start=start, end_time=end_time)) &help, anytim(start.value,/vms)
;    <Expression>    FLOAT     =  2.25109e+006
;    <Expression>    STRING    = '30-Sep-1998 14:16:28.000'
;    IDL> help, total(stx_calibration_data_array( asw[10],start=start, end_time=end_time)) &help, anytim(start.value,/vms)
;    <Expression>    FLOAT     =       26504.0
;    <Expression>    STRING    = '30-Sep-1998 14:16:28.000'
;
; :history:
;
;       03-Dec-2018 – ECMD (Graz), initial release
;       15-nov-2019 - RAS  (GSFC), simplified
;
;-
function stx_calibration_data_array, input, list_index = list_index, $
  start_time = start_time, end_time = end_time, pixel_mask =pixel_mask , detector_mask =detector_mask

  default, list_index, 0 ;input may be a list, which one?
  calibration_data = (is_list( input ) ? input[ list_index ] : input).subspectra
  default, pixel_mask, calibration_data[0].pixel_mask
  default, detector_mask, calibration_data[0].detector_mask
  default, start_time, input[list_index].start_time
  default, end_time, input[list_index].end_time
  
  qp = where( pixel_mask, np )
  qd = where( detector_mask, nd )
  if np eq 0 or nd eq 0 then begin
    message, /continue, 'No valid spectra because of either pixel or detector masks
    return, 0
  endif
  n_spectra = calibration_data.count()

  calibration_spectrum = fltarr(1024, 12, 32) ;create output array
  for i = 0,n_spectra-1 do begin

    ; Get the current subspectrum
    current_subspectrum = calibration_data[i].spectrum
    ngroup = calibration_data[i].number_of_summed_channels

    e_start = calibration_data[i].lower_energy_bound_channel ge 0 ?  calibration_data[i].lower_energy_bound_channel : calibration_data[i].lower_energy_bound_channel+1024

    xdim = current_subspectrum.dim
    xdim[0] = xdim[0] * ngroup ;expand the number of channels

    e_end = e_start + xdim[0] -1
    expanded_subspectrum = rebin( current_subspectrum, /sample, xdim ) / (1. *  ngroup) ;divide to preserve counts
    calibration_spectrum[ e_start: e_end, qp, qd ]  += expanded_subspectrum[ *, qp, qd]
  endfor


  return, calibration_spectrum

end