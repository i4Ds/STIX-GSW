;+
;
; NAME:
;   stx_uv_points
;
; PURPOSE:
;   Compute the coordinates of the (u,v) points sampled by specific STIX sub-collimators. For more information, we refer to:
;   
;   - Giordano et al., "The Process of Data Formation for the Spectrometer/Telescope for Imaging X-rays 
;     (STIX) in Solar Orbiter", SIAM Journal on Imaging Sciences, 2015
;     
;   - Massa et al., "STIX imaging I - Concept", arxiv, 2023
;
; CALLING SEQUENCE:
;   uv_points = stx_uv_points(subc_index)
;
; INPUTS:
;   subc_index: array containing the indices of the subcollimators to be considered for computing the (u,v) points
;
; KEYWORDS:
;   d_sep: distance between the front and the rear grid [in mm]. Default, 545.30
;   
;   d_det: distance between the rear grid and the detector [in mm]. Default, 47.78
;
; HISTORY: July 2023, Massa P. (WKU), based on 'stx_uv_points_giordano'
;
; CONTACT:
;   paolo.massa@wku.edu
;-

function stx_uv_points, subc_index, d_sep=d_sep, d_det=d_det

default, d_sep, 545.30
default, d_det, 47.78

subc_str = stx_construct_subcollimator()
subc_str = subc_str(subc_index)

factor_f = (d_sep + d_det) / subc_str.front.pitch / 3600.0d / !RADEG ;; in arcsec^-1
factor_r = d_det / subc_str.rear.pitch / 3600.0d / !RADEG            ;; in arcsec^-1

u = -subc_str.PHASE * (cos(subc_str.front.angle * !dtor) * factor_f - cos(subc_str.rear.angle * !dtor) * factor_r)
v = -subc_str.PHASE * (sin(subc_str.front.angle * !dtor) * factor_f - sin(subc_str.rear.angle * !dtor) * factor_r)

return, {u:u, v:v}

end