;+
; :Description:
;    STX_Background_Model takes a background spectrogram, att state 0 by rule, observed with a slow cadence, 
;    are grouped and extrapolated to flare time intervals.  The data is from the background detector pixels that are not exposed
;    to solar flux. The data are fit, for each energy channel, to a polynomial model where time is free parameter. Then the model is applied 
;    to the flare time bins. The data product will also include the total pixel area which will depend on telecommand. The input is based
;    on the current expectation of the background data product which is undefined at this time, 21-apr-2015.
;
; :Params:
;    bspectrogram -input background data structure
;      IDL> help, bspectrogram
;      ** Structure <c176250>, 7 tags, length=13664, data length=13654, refs=1:
;         TYPE            STRING    'stx_spectrogram'
;         DATA            ULONG64   Array[32, 30]     ;count data
;         T_AXIS          STRUCT    -> <Anonymous> Array[1]
;         E_AXIS          STRUCT    -> <Anonymous> Array[1] ;energy axis in energy/science channels, keV
;         LTIME           FLOAT     Array[32, 30] ;livetime fraction
;         ATTENUATOR_STATE                         ;unused
;                         BYTE      Array[30]
;         AREA_MM2        FLOAT          0.220000  ;pixel area in mm2
;
; :Keywords:
;    flare_time - flare time intervals as stx time axis format
;    ndegree    - degree of polynomial for temporal fit
; :Returns: This function returns the spectrogram as a variant of the stx_spectrogram structure, the stx_bkg_spectrogram structure
;    IDL> help, fbspectrogram
;    ** Structure <c176f40>, 7 tags, length=327552, data length=327544, refs=1:
;       TYPE            STRING    'stx_bkg_spectrogram'
;       DATA            ULONG64   Array[32, 600]
;       T_AXIS          STRUCT    -> <Anonymous> Array[1]
;       E_AXIS          STRUCT    -> <Anonymous> Array[1]
;       LTIME           FLOAT     Array[32, 600]
;       SIGMA           FLOAT     Array[32, 600]  ;standard deviation as a fraction of the data value
;       AREA_MM2        FLOAT           22.0000 
; :Author: richard.schwartz@nasa.gov
; :History: 21-apr-2015
;-
function stx_background_model, bspectrogram, flare_time = fstx_time, ndegree = ndegree
;fit each bspectrogram energy channel to a polynomial in time and apply to the new time bins of fstx time
default, area_mm2, 22. ; pixel area in mm2
nchan = n_elements( bspectrogram.e_axis.width )
nbin = n_elements( fstx_time.duration )
fdata = fltarr( nchan, nbin )
sdata = fdata ;include an estimate of the standard deviation.  Should be considered an estimate only
xlims = transpose( anytim( [[fstx_time.TIME_START.value], [fstx_time.TIME_END.value] ]) )
xdata = anytim( bspectrogram.t_axis.mean.value )
default, ndegree, 2
for ichan = 0L, nchan -1 do begin
  ydata = f_div( bspectrogram.data[ ichan, * ], bspectrogram.t_axis.duration * bspectrogram.ltime[ ichan, *] )
  fdata[ ichan, * ] = poly( avg( xlims, 0),  poly_fit( xdata, ydata, ndegree, yerr=yerr, yband = yband ) ) * fstx_time.duration
  ;fdata[ ichan, * ] = interp2integ( xlims, xdata, ydata ) * fstx_time.duration
  sdata[ ichan, * ] = yerr / avg( fdata[ ichan, * ] )
  endfor
fbspectrogram = stx_spectrogram( fdata, fstx_time, bspectrogram.e_axis, fdata * 0.0 + 1.0, attenuator_state = intarr(nbin)  )
fbspectrogram = add_tag( fbspectrogram, sdata, 'sigma' )
fbspectrogram = rep_tag_value( fbspectrogram, 'stx_bkg_spectrogram','type' )
fbspectrogram = rem_tag( fbspectrogram, 'attenuator_state' )
area_mm2 = have_tag( bspectrogram, 'area_mm2' ) ? get_tag_value( bspectrogram, /area_mm2 ) : area_mm2
fbspectrogram = add_tag( fbspectrogram, area_mm2, 'area_mm2' )
return, fbspectrogram
end