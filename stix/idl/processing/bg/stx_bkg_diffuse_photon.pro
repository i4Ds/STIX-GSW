;+
; :description:
; 
;   Estimate of diffuse x-ray background photon spectrum  
;   based on description and formulae in STIX-TN-0027-ETH_Background_Rates
;     
; :categories:
; 
;    background
;
; :params:
;
;    e : in, required, type="float array"
;             Input Energy bins in keV
;
; :keywords:
;
;    costheta   : in, type = "float", default = 1.0 (zero degrees from normal)
;                 cosine of angle of incidence
;                 
; :returns:
; 
;    fltarr, the background spectrum for the input energy vector.
;
; :examples:
; 
;    spec = stx_bkg_diffuse_photon(findgen(146)+4.)
;
; :history:
; 
;    28-Nov-2017 - ECMD (Graz), initial release
;
;-
function stx_bkg_diffuse_photon, e, costheta=costheta

  default, e, findgen(1500)*0.1 + 4.
  default, costheta , 1.

  s1  = 7.877 * (e)^(-.29) * exp(-e/41.13)

  s2  = 0.0259 * (e/60.)^(-5.5) + 0.504*(e/60)^(-1.58) + 0.0288*(e/60)^(-1.05)

  i1 = where(e lt 60.)
  i2 = where(e ge 60.)

  s = [s1[i1],s2[i2]]

  phot = s/e

  sa = [2*!pi, 0.012,3.2]
  sa = [sa, 4*!pi - total(sa)]
  sa /=  4*!pi

  pmma={compnd,n:intarr(10),z:fltarr(10),a:fltarr(10),gcm3:fltarr(10)}
  pmma.z(0:2) = [6,1,8]
  pmma.a(0:2) = [12.01,1.0,16.]
  pmma.n(0:2) = [5,8,2]
  for i=0,2 do pmma.gcm3(i) = pmma.a(i)*pmma.n(i)/total(pmma.a*pmma.n) * 1.19
  data_pmma = filter_cmpnd( e>1.01, pmma.z([0,1,2]), 1.d0*pmma.gcm3([0,1,2])*.2,/cm)


  z_be = 4
  z_w  = 74
  z_al = 13

  z = [z_be, z_w, z_al]

  gm_be = 1.848 ;g/cm3
  gm_w  = 19.25 ;g/cm3
  gm_al = 2.7 ;g/cm3

  gmcm = [gm_be*.4, gm_w*.04, gm_al*.7]


  atten_be = sa[1] / (exp(  (xsec(e,z[0],'AB',/cm2perg, error=error) * $
    gmcm[0]/costheta) < 40. ))

  atten_w = sa[2] / (exp(  (xsec(e,z[1],'AB',/cm2perg, error=error) * $
    gmcm[1]/costheta) < 40. ) * exp(  (xsec(e,z[2],'AB',/cm2perg, error=error) * gmcm[2]/costheta) < 40. ))

  atten_pmma = (sa[0]*data_pmma)/ exp(  (xsec(e,z[2],'AB',/cm2perg, error=error) * gmcm[2]/costheta) < 40. )

  atten_al = sa[3] / (exp(  (xsec(e,z[2],'AB',/cm2perg, error=error) * $
    gmcm[2]/costheta) < 40. ))

  atten = atten_be + atten_w + atten_al + atten_pmma

  b1 = atten*phot

  return, b1
end