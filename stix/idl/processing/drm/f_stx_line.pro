;+
; :description:
;    This function returns a calibration source line spectrum including the effects of incomplete charge
;    collection due to radiation damage
;
; :categories:
;    calibration, fitting
;
; :params:
;    edge2 : in, required, type="float array"
;             Input Energy bins in keV, 2xN
;
;    param : in, required, type="float array"
;             A set of parameters describing the line and tailing
;             p[0] : Normalization
;             p[1] : line center energy in default units, normally keV
;             p[2] : gaussian line width before tailing in sigma, to convert fwhm = 2.36 * sigma
;             p[3] : mfp_divisor, default is 1. Increase mfp_divisor to increase trapping and reduce mean free path
;             p[4] : known line energy. Used to computer tailing. may be different from p[1], set to 0 to use p[1]
;             p[5] : mean free path for holes in cm, for default of  0.36 set to 0, 
;             p[6] : mean free path for electrons in cm, for default of 24 set to 0
;  :Keywords:
;     do_calc : default is 1, if set, use with drm in (O)SPEX count calculation
; :returns:
;    returns the calibration line spectrum for the input energy vector.
;
; :examples:
;     spectrum = stx_hecht_fit( findgen(100)*0.5+60., [0.36,24.,10000.])
;
; :history:
;    14-Jun-2017 - ECMD (Graz), initial release
;
;-


function f_stx_line, edge2, param, do_calc=do_calc, _extra=_extra

  checkvar, do_calc, 1


  edge_products, edge2, edges_2 = e2, mean= em, gmean = egm
  ;Evaluate on 0.1 keV bins from E0 - 15*sigma -  E0 + 5*sigma
  nbin = n_elements( em )
  sigma = param[2]
  e0    = param[1]
  mfp_divisor = param[3] > .01
  ix = value_locate( e2[0,*], e0 + [-30.*sigma, 5.0 * sigma]) > 0 < (nbin-1)
  erange = [e2[0, ix[0]], e2[1, ix[1]]]
  nsub = ( erange[1] - erange[0] ) / 0.1 + 1
  em_sub = interpol( erange, nsub)
  etest = keyword_set( param[4] )? param[4]: e0
  p = [ 0.36, 24., 10000.]
  p[0] = keyword_set( param[5] ) ? param[5] : p[0]
  p[1] = keyword_set( param[6] ) ? param[6] : p[1]
  
  if n_params( param ) ge 6 then p[1] = param[5]
  
  p[2]  = param[0]
  
  rslt_sub =stx_hecht_fit(em_sub, p, e0 = e0, sigma = sigma, mfp_divisor = mfp_divisor)
  result = interp2integ( e2, em_sub, rslt_sub, /log ) >0

  return, result
end