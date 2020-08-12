;+
; :Description:
;    Extract the variation of the Caliste offset vs temperature by fitting
;    the variation in the position of the 30.85 keV line against the housekeeping temperature
; :Examples:
;    meta = mrdfits('calibration_meta.fits',1)
;    q = where(meta.bl_holder and abs(meta.duration-900) lt 5)
;    mq = meta[q]
;      IDL> help, mq,/st
;      ** Structure <18aff730>, 15 tags, length=3160, data length=3160, refs=2:
;      FILENAME        STRING    'stx_cal\solo_L1_stix-calibration-spectrum_20200507T150641__complete_02342.fits'
;      DURATION        LONG               900 
;      LIVE_TIME       LONG            421248
;      QUIET_TIME      INT              6
;      BL_HOLDER       INT              1
;      AVERAGE_TEMP    FLOAT          -37.2148
;      DET_MASK        LONG64      -9223372032559808513
;      PIX_MASK        LONG64      -9223372036854771713
;      FITS_FILE_ID    LONG64                      2342
;      CALIBRATION_RUN_ID
;      LONG64                       540
;      MEAS_START_UTC  STRING    '2020-05-07T15:06:41.503'
;      GAIN            FLOAT     Array[12, 32]
;      OFFSET          FLOAT     Array[12, 32]
;      AVG31           FLOAT           293.772
;      SIG31           FLOAT           3.37876
;    
; :Params:
;    meta_str - selected calibration meta structures (calibration_meta.fits)
;    optimally chosen for durations short with respect to temperature variations
;    
; :Keywords:
;    det_mask - bytarr(32), set element for detector
;    pix_mask - bytarr(12), set element for pixel
;
; :Author: rschwartz70@gmail.com, 5-aug-2020
;-

function stx_calibration_tlut_derivative, meta_str, det_mask = det_mask, pix_mask = pix_mask, $
  adc4096scale = adc4096scale, acoef = acoef, again = again 

  default, adc4096scale, 1
  mq  = meta_str
  p31 = mq.offset + 30.85 * mq.gain ;position of 30.85 keV line for all
  temp = mq.average_temp
  ntemp = n_elements( temp )
  default, det_mask, bytarr(32)+1b
  default, pix_mask, bytarr(8)+1b

  ;avg p31 to the number of temperature samples
  ;use resistant_mean,

  wpix = where(pix_mask, npx)
  wdet = where(det_mask, ndt)
  gain = (mq.gain)[wpix,wdet,*]
  gainscale = gain * 4.0 ;
  resistant_mean, gainscale, 3, again
  acoef = fltarr( 2, npx, ndt )
  for j = 0, ndt-1 do for i = 0, npx-1 do begin
    acoef[0, i,j] = robust_poly_fit( temp, p31[i,j,*], 1 )
  endfor
  dedtk = avg( acoef[1,*,*]) ; delta offset (keV) per delta degree Kelvin

  return, adc4096scale ? dedtk * again : dedtk ;adc chan per Kelvin or keV per Kelvin
end






