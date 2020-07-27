;+
; :description:
;    This procedure runs the stx_flare_detection_rhessi_test for flares with a range of different
;    fluxes, spectra and background estimates using the RHESSI lightcurve from several days as
;    the basis for the estimates of flaring activity in the thermal and non-thermal energy bands
;
; :categories:
;    testing, flare detection
;
; :examples:
;   stx_flare_detection_rhessi_test_demo
;
; :history:
;    20-Jul-2018 - ECMD (Graz), initial release
;
;-
pro stx_flare_detection_rhessi_test_demo

  ;a range of peak fluxes in the thermal band are selected
  flux = [2e6,2e5,2e4,2e3]*.3

  ; the total thermal fluxes are very roughly equivalent to the X1, M1, C1 and B1 GOES classes
  names = ['_x_','_m_' ,'_c_','_b_']


  nthrrat = [0.3,0.03,0.003]


  bgfact =[1,2,4,8,16]

  basename = ['simple_flare', 'intense_day', 'quiet_day','6jul3_fd', '8jul3_fd','6apr5_fd','12oct5_fd','12mar5_fd']

  ; one time range of 2 hours which shows a fairly standard looking flare profile plus 7 full days
  ; with varying activity are selected for this demo
  timerange = [ ['30-Nov-2005 05:00:02.000', '30-Nov-2005 07:00:14.000'],$
    ['23-Oct-2003 00:04:02.000', '23-Oct-2003 23:59:14.000'],$
    ['30-Nov-2005 00:00:02.000', '30-Nov-2005 23:59:14.000'],$
    ['06-Jul-2003 00:00:02.000', '06-Jul-2003 23:59:14.000'],$
    ['08-Jul-2003 00:00:02.000', '08-Jul-2003 23:59:14.000'],$
    ['06-Apr-2005 00:00:02.000', '06-Apr-2005 23:59:14.000'],$
    ['12-Oct-2005 00:04:02.000', '12-Oct-2005 23:59:14.000'],$
    ['12-Mar-2005 00:04:02.000', '12-Mar-2005 23:59:14.000']]

  ; the background estimates are made by looking at the RHESSI quicklook lightcurves
  ; and selecting a constnat value which would remove all non-flare counts
  bg = [[30,8 ],$
    [3,12],$
    [2 ,10],$
    [8,15],$
    [.2,13],$
    [12,26],$
    [15,10],$
    [17,15]]



  for l = 0, 7 do begin

    ;extract the corrected RHESSI quicklook lightcurve for the specified time range
    fc = hsi_extrct_flx(reform(timerange[*, l]), /corrected, /name)
    d5 = fc.d5

    for i = 0, 3 do begin
      for j = 0,2 do begin
        for k = 0,4 do begin

          stx_flare_detection_rhessi_test, fc, $
            savename = basename[l] + names[i]+'nt'+strtrim(j,2)+'_bg_'+strtrim(k,2)+'.png',rhessi_bg = reform(bg[*,l]), $
            thermal_scaling = flux[i], ntscaling = nthrrat[j], bgfactor =bgfact[k], /close

        endfor
      endfor
    endfor
  endfor


end



