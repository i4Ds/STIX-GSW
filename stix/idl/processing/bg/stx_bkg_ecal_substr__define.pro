;+
; :Description:
;    stx_bkg_ecal_substr__define
;    calibration subspectrum definition
;
;
;
;
;
; :Author: raschwar
;-
pro stx_bkg_ecal_substr__define
  d = {stx_bkg_ecal_substr, $ ;calibration subspectrum definition
    sid: 0, $ subspectrum id
    did: 0, $ detector id 1-32
    pid: 0, $ pixel id
    cmp_k: 0, $ Compression schema Calib accum.: K-parameter
    cmp_m: 0, $ Compression schema Calib accum.: M-parameter
    cmp_s: 0, $ Compression Schema Calib accum.: S-parameter

    npoints: 0, $ number of spectral points
    ngroup: 0, $  number of summed channel in spectral point
    ichan_lo: 0,$
    subspec_orig: ptr_new(), $
    subspec_grouped: ptr_new(), $
    subspec_c: ptr_new(), $ ;lowest channel in subspectrum
    subspec_rcvr: ptr_new()} ;rebuilt (recovered and decompressed) subspectrum

end