;+
; :Description:
;    STX_DETECTOR_DEVIATION_STATUS takes an array of count spectra and compares them
;    and reports whether the count values are within the nominal range, moderately out of nominal range (yellow)
;    or deviating from nominal into the red range.
;
; :Returns:
;   Returns an array with the same shape as the input count_spectra with values -1, 0, 1, or 2
;   -1 - below min_count (see keywords)
;   0  - counts in nominal range (see below for explanation)
;   1  - counts in yellow range   (see below for explanation)
;   2  - counts in red range      (see below for explanation)
;
; :Params:
;    count_spectra, nominally 32 x 30, channels & Fourier detectors, counts in each channel for each detector
;
; :Input Keywords:
;    yellow - deviation range, default 0.10 of average. Values between yellow and red value, stat significant
;     are given yellow status
;    red - deviation range, default 0.20 of average. Values greater (stat significant) than the red limit are given red status
;     are given yellow status
;    sigma_limit - default is 10, values must exceed average + yellow * average + sigmal_limit * sqrt( avg) to be declared
;     yellow, and similarly for red
;    rescale - normalization for every channel and detector to bring it into the average range based on previous
;     measurements, intially 1 for every channel and detector
;
;    min_count - default 100, channels with fewer than min_count are not evaluated for having nominal, yellow, or red status
; :Output Keywords:;
;    det_max = det_max ;- maximum value for each detector, -1 below min_count, 0 nominal, 1 yellow, 2 red
;    all_max = all_max ;- maximum value for all detectors, -1 below min_count, 0 nominal, 1 yellow, 2 red
;    x_count = x_count ;- expected counts for each detector computed from the average and rescale
;    diff_count = diff_count ;- absolute difference in counts between input and x_count
;
; :Author: rschwartz70@gmail.com
;-
function stx_detector_deviation_status, count_spectra, yellow = yellow, red = red, $
  sigma_limit = sigma_limit, rescale = rescale, min_count = min_count, $
  ;Output keywords
  det_max = det_max, $ ;maximum value for each detector, -1 below min_count, 0 nominal, 1 yellow, 2 red
  all_max = all_max, $ ;maximum value for all detectors, -1 below min_count, 0 nominal, 1 yellow, 2 red
  x_count = x_count, $ ;expected counts for each detector computed from the average and rescale
  diff_count = diff_count ;absolute difference in counts between input and x_count

  default, sigma_limit, 10 ;gaussian deviation above yellow or red line limits
  default, yellow, 0.1 ;indicates suspicious deviation
  default, red, 0.2 ;indicates serious change
  default, min_count, 100 ;minimum count required to declare yellow or red excursions
  dim_cs = size( /dimension, count_spectra )
  nchan = dim_cs[0]
  ndet  = dim_cs[1]
  default, rescale, count_spectra * 0.0 + 1. ;detectors all the same is the default
  ;Compute average counts in each channel
  av_count = avg( count_spectra, 1 )
  ;apply rescale correction factor to get expected (x) counts
  x_count = reproduce( av_count, ndet) * rescale
  ;get the absolute differences and find status for each
  ;status - -1, below limit; 0, nominal above min_count, lt yellow, 1, exceeds yellow by sigma_limitp, 2, exceeds red by sigma_limit

  status = intarr( dim_cs )
  diff_count = abs( count_spectra - x_count )
  ;counts below min_count are -1
  z = where( count_spectra le min_count, nz, comp=q, ncomp = nq  )

  zy = where( diff_count ge (yellow*av_count + sigma_limit*sqrt( av_count )), ny)
  ;Check to see if any are redline
  zr = where( diff_count ge (red*av_count + sigma_limit*sqrt( av_count )), nr)
  status[zy] = 1
  ;could be red, if so, set to 2
  status[zr] = 2
  ;maybe too few counts so set to -1
  status[z] = -1
  det_max = max( status, dim=1 )
  all_max = max( status ) ; look for any detector's channel in the Red or Yellow
  return, status
end


  edg=stx_science_energy_channels()

  ph_edg=findgen(250)+3
  drm0 =stx_build_drm( edg.edges_2, atten=0, ph_ene=ph_edg)

  drm1 =stx_build_drm( edg.edges_2, atten=1, ph_ene=ph_edg)
  ;Change the gain on one detector to see if we can detect the deviation!
  edg1=edg.edges_2*1.03
  drm01 =stx_build_drm( edg1, atten=0, ph_ene=ph_edg)
  drm11 =stx_build_drm( edg1, atten=1, ph_ene=ph_edg)
  ;simulate a typical spectrum
  apar_vth= [0.1, 1.5]
  apar_fpow = [1e-5, 4]
  ph_th = f_vth( ph_edg, apar_vth)
  ph_pw = f_pow( ph_edg, apar_fpow)
  ephm=get_edges( ph_edg, /gm)
  ;plot, /xlo, /ylog, ph_th+ph_pw
  ;pmm, ephm
  ;plot, /xlo, /ylog, ephm, ph_th+ph_pw
  ph_mdl = ph_th+ ph_pw
  ewidth = drm0.ewidth ; count channel width in keV
  ;Build 30 independent count spectra with Poisson stats
  cnt0 = ewidth * ( drm0.smatrix # (ph_mdl * get_edges(ph_edg,/wid)))
  cnt1 = ewidth * ( drm1.smatrix # (ph_mdl * get_edges(ph_edg,/wid)))
  ;deviant count spectrum
  dcnt0 = ewidth * ( drm01.smatrix # (ph_mdl * get_edges(ph_edg,/wid)))
  dcnt1 = ewidth * ( drm11.smatrix # (ph_mdl * get_edges(ph_edg,/wid)))
  ;Nominal count correction factors, 32 channels x 30 detectors
  ;Nominal values are 1, actual values to be determined in space with initial measurement
  cfac = fltarr( 32, 30 )+ 1.0
  default, yellow, 0.1 ;10% deviation
  default, red, 0.2 ;20% deviation
  ;use cnt1 and dcnt1 as the test cases
  ;for 30 spectra compare each channel to the average
  all30 = fltarr( 32, 30)
  for i = 0,29 do all30[0,i]= poidev( cnt1*5000, seed=seed)
  ;ccompute the abnormal simulated spectrum and put it into the 0th detector row
  all30[0, 0] = poidev( dcnt1*5000, seed = seed )

  status = stx_detector_deviation_status( all30, yellow = yellow, red = red, $
    sigma_limit = sigma_limit, rescale = cfac, min_count = min_count, $
    ;Output keywords
    det_max  -_max, $ ;maximum value for each detector, -1 below min_count, 0 nominal, 1 yellow, 2 red
    all_max = all_max, $ ;maximum value for all detectors, -1 below min_count, 0 nominal, 1 yellow, 2 red
    x_count = x_count, $ ;expected counts for each detector computed from the average and rescale
    diff_count = diff_count );absolute difference in counts between input and x_count

  ;Print the status readout for the deviant detector. Can be found using where()!!!
  print, 'Show the status value for each channel in the detector that was deliberately changed for effect, detector 0'
  print, status[*,0]
  ;IDL> .go
  ;% Compiled module: STX_DETECTOR_DEVIATION_STATUS.
  ;% Compiled module: $MAIN$.
  ;  -1      -1       2       2       2       1       0       0       0       0       0       0       0       0       0      -1      -1      -1      -1      -1
  ;-1      -1      -1      -1      -1      -1      -1      -1      -1      -1      -1      -1

end
