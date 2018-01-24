;+
; :description:
;     this function converts the DSS native detector number to subcollimator ID and vice versa
;
; :params:
;     number               : in, required, type = "integer"
;                            number of detector in given system
;                            
; :keywords:
;     dss                  : converts from subcollimator ID to DSS native detector number
;     subcollimator        : converts from DSS native detector number to subcollimator ID (default) 
;                            
; :returns:
;   number of the detector in given standard
;
; :example:
;   subcollimator_ID = stx_sim_dss_detector_numbering(DSS_native_number)
;   DSS_native_number = stx_sim_dss_detector_numbering(subcollimator_ID,/dss)
;
; :history:
;     19-Jun-2015 - Marek Steslicki (Wro), initial release
;
;-
function  stx_sim_dss_detector_numbering, number, dss=dss, subcollimator=subcollimator

subcollimator_ID=[ 5, $
                  11, $
                   1, $
                   2, $
                   6, $
                   7, $
                  12, $
                  13, $
                  10, $
                  16, $
                  14, $
                  15, $
                   8, $
                   9, $
                   3, $
                   4, $
                  22, $
                  28, $
                  31, $
                  32, $
                  26, $
                  27, $
                  20, $
                  21, $
                  17, $
                  23, $
                  18, $
                  19, $
                  24, $
                  25, $
                  29, $
                  30 ]

; NEW
subcollimator_ID=[1,2,6,7,5,11,12,13,14,15,10,16,8,9,3,4,31,32,26,27,22,28,20,21,18,19,17,23,24,25,29,30]
                  
DSS_native=[  2, $
              3, $
             14, $
             15, $
              0, $
              4, $
              5, $
             12, $
             13, $
              8, $
              1, $
              6, $
              7, $
             10, $
             11, $
              9, $
             24, $
             26, $
             27, $
             22, $
             23, $
             16, $
             25, $
             28, $
             29, $
             20, $
             21, $
             17, $
             30, $
             31, $
             18, $
             19  ]
 
; NEW            
;DSS_native = [1,2,15,16,5,3,4,13,14,11,6,7,8,9,10,12,27,25,26,23,24,21,28,29,30,19,20,22,31,32,17,18]
 
if keyword_set(dss) then return,DSS_native[number-1]

return, subcollimator_ID[number]

end                  