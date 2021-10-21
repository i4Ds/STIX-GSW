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
;      IDL> d = stx_calibration_fits2_array(file=file)
;      MRDFITS: Binary table.  5 columns by  384 rows.
;      MRDFITS: Binary table.  12 columns by  1 rows.
;      IDL> help, d
;      D               FLOAT     = Array[1024, 12, 32]
;      IDL> d = stx_calibration_fits2_array(file=file, he=hdr, control=c)
;      MRDFITS: Binary table.  5 columns by  384 rows.
;      MRDFITS: Binary table.  12 columns by  1 rows.
;      IDL> help,d
;      D               FLOAT     = Array[1024, 12, 32]
;      IDL> help, hdr
;      HDR             STRING    = Array[32]
;      IDL> help, c,/st
;      ** Structure <1830b4f0>, 12 tags, length=128, data length=126, refs=1:
;      DURATION        LONG              1800
;      QUIET_TIME      INT              6
;      LIVE_TIME       LONG            902269
;      AVERAGE_TEMP    INT           3948
;      COMPRESSION_SCHEME_ACCUM_SKM
;      INT       Array[3]
;      DETECTOR_MASK   BYTE      Array[32]
;      PIXEL_MASK      BYTE      Array[12]
;      SUBSPECTRUM_MASK
;      BYTE      Array[8]
;      SUBSPEC_ID      BYTE      Array[8]
;      SUBSPEC_NUM_POINTS
;      INT       Array[8]
;      SUBSPEC_NUM_SUMMED_CHANNEL
;      INT       Array[8]
;      SUBSPEC_LOWEST_CHANNEL
;      INT       Array[8]
;      
;  calibration_spectrum = stx_calibration_fits2_array( file=file, rate_str = rate_str, control = control, header = header, $
;      start_time = start_time, end_time = end_time, pixel_mask =pixel_mask , detector_mask =detector_mask,$
;      duration = duration, live_time = live_time)
;
; :history:
;
;       03-Dec-2018 – ECMD (Graz), initial release
;       15-nov-2019 - RAS  (GSFC), simplified
;       31-jul-2020 - RAS  (GSFC) based on stx_calibration_data_array
;
;-
function stx_calibration_fits2_array, rate_str = rate_str, control = control, header = header, file=file, $
  start_time = start_time, end_time = end_time, pixel_mask =pixel_mask , detector_mask =detector_mask,$
  duration = duration, live_time = live_time

  
  if keyword_set( file ) then begin
    rate_str = mrdfits( file, 1)
    control = mrdfits( file, 2)
    header = headfits( file )
  endif
  pixel_mask = control.pixel_mask
  detector_mask = control.detector_mask
  duration = control.duration
  live_time = control.live_time / 1000. 
  qsubspec = where( control.subspectrum_mask, n_spectra)
  start_time = anytim( /mjd, fxpar(header,'date_beg'))
  end_time = anytim( /mjd, fxpar(header,'date_end'))
  
  qp = where( pixel_mask, np )
  qd = where( detector_mask, nd )
  if np eq 0 or nd eq 0 then begin
    message, /continue, 'No valid spectra because of either pixel or detector masks
    return, 0
  endif
  

  calibration_spectrum = fltarr(1024, 12, 32) ;create output array
  cstart = [0, total(/cum, control.subspec_num_points )]-1
  for iss = 0,n_spectra-1 do begin

    ; Get the current subspectrum
    adc_start = control.subspec_lowest_channel[ iss ]
    
    ngroup = control.subspec_num_summed_channel[iss]+1

    xdim = [control.subspec_num_points[iss] * ngroup, 384]
    
    adc_end = adc_start + xdim[0] -1
    expanded_subspectrum = rebin( rate_str.counts[cstart[iss]+1:cstart[iss+1]], /sample, xdim ) / (1. *  ngroup) ;divide to preserve counts
    calibration_spectrum[ adc_start: adc_end, qp, qd ]  += expanded_subspectrum[ *, qp, qd]
  endfor


  return, calibration_spectrum

end