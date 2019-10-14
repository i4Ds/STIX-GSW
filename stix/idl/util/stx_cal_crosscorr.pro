;+
; :Description:
;    This function computes the energy offset in two STIX calibration spectra
;
; :Params:
;    data - baseline calibration spectrum. Should contain well defined features for x correlation
;    ddata - calibration spectrum with potential channel shift, result computed in energy units of keV
;    ii  - lag in fractional bin steps
;    cc  - crosscorrelation coefficient (0-1) computed for each lag, output
;    imax - position of maximum of cc
;
; :Keywords:
;    magnify - magnification, spline interpolate the data and ddata to these bins for more
;     finely scaled cross-correlation, defaults to 4
;    ilim - search over this range of bin lag, positive and negative, ilim is range without magnify value
;     real range is -(magnify * ilim) -> (magnify * ilim)
;    gain - input energy gain for calibration data bins, default is 0.4 keV
;
; :Author: raschwar
;-
function stx_cal_crosscorr, data, ddata, ii,  cc, imax, magnify = mag, ilim = ilim, gain = gain

  default, mag, 4
  default, gain, 0.4
  mgain = gain / mag
  ndata = n_elements(data)
  mag = (mag > 1) < 10
  default, ilim, 10
  milim = mag * ilim * 1L
  cc = fltarr( 2 * milim + 1)

  mddata = ddata
  mdata  = data
  if mag gt 1 then begin
    mddata = interpol( ddata, mag * ndata, /spline)
    mdata = interpol( data, mag * ndata, /spline)
  endif
  for ii = -milim, milim-1 do cc[ ii + milim ] = correlate( shift( mdata, ii), mddata )
  ii = findgen( milim * 2 + 1) - milim
  mmax = max( cc, imax )
  ;set up for stix channels,
  dgain = mgain * ii
  return, dgain[imax]
end