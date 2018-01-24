;+
; :Description:
;    stx_ecal_substr__define
;    calibration subspectrum definition
;
;
;
;
;
; :Author: raschwar
;-
function stx_bkg_ecal_substr
;  d = {stx_bkg_ecal_substr, $ ;calibration subspectrum definition
;    sid: 0, $ subspectrum id
;    did: 0, $ detector id 1-32
;    pid: 0, $ pixel id
;    cmp_k: 0, $ Compression schema Calib accum.: K-parameter
;    cmp_m: 0, $ Compression schema Calib accum.: M-parameter
;    cmp_s: 0, $ Compression Schema Calib accum.: S-parameter
;    npoints: 0, $ number of spectral points
;    ngroup: 0, $  number of summed channel in spectral point
;    ichan_lo: 0} ;lowest channel in subspectrum
d = {stx_bkg_ecal_substr}
d.cmp_k = 4
d.cmp_m = 8 - d.cmp_k
d.cmp_s = 0
d.ngroup = 1
d.npoints = 50
d.ichan_lo = 50
return, d
end