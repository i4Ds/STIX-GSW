;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_pileup_corr_parameter
;
; :description:
;    This function estimates the fractional area of a single large pixel compared with the rest of the detector 
;    group. It can be used in estimatiming the probablity that two photons hit a given large pixel and a different
;    pixel in the same group resuling in anti-coincidence rejection (if different) or pileup (if the same).
;    Limitiations: This assumes uniform illumination over the detector pair 
;    This ignores the possiblity of the first hit being a small pixel 
;    
;    
; :categories:
;    livetime, spectroscopy, imaging 
;
; :returns:
;    scaler parameter to be used in livetime calulation e.g. by stx_livetime_fraction.pro
;
; :examples:
;    beta = stx_pileup_corr_parameter()
;
; :history:
;    21-Apr-2022 - ECMD (Graz), initial release
;
;-
function stx_pileup_corr_parameter

subc_str = stx_construct_subcollimator()
pixel_areas = subc_str.det.pixel.area
detector_area = (subc_str.det.area)[0]
big_pixel_fraction = pixel_areas[0]/detector_area
prob_diff_pix = (2./big_pixel_fraction - 1.)/(2./big_pixel_fraction)

return, prob_diff_pix

end