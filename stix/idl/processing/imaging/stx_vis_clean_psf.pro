;+
;
; NAME:
;
;   stx_vis_clean_psf
;
; PURPOSE:
;
;   Create the STIX Point Spread Function (PSF) to be used inside the CLEAN algorithm
;
; CALLING SEQUENCE:
;
;   psf = stx_vis_clean_psf(vis, xypsf)
;
; INPUTS:
; 
;   vis: STIX visibility structure. The u and v coordinates of the frequency sampled by the considered sub-collimators are used
;        to compute the PSF
;
;   xypsf: index of the pixel in which the PSF is centered
;   
; KEYWORDS:
; 
;   imsize: two-element array containing the number of pixels of the PSF. Default, [129,129]
;   
;   pixel_size: two-element array containing the pixel size of the PSF in arcsec. Default, [1.,1.]
;
;   spatial_frequency_weight: array containing the weights associated to each (u,v) point. 
;                             By default each weight is equal to 1 (natural weighting) 
;
; OUTPUTS:
;   2D matrix containing the STIX PSF
;   
;
; HISTORY: January 2023, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-
function stx_vis_clean_psf, vis, xypsf, imsize=imsize, pixel_size=pixel_size, $
                                        spatial_frequency_weight=spatial_frequency_weight

default, imsize,129
default, pixel_size,1.
nvis = n_elements(vis)
default, spatial_frequency_weight, fltarr(nvis)+1.

npx   = 2*long(imsize[0])
npx   = npx / 2 * 2 + 1 ; Force the number of pixels to be odd
pixel = pixel_size[0]

imdim = long(imsize[0])
imdim = imdim / 2 * 2 + 1 ; Force the number of pixels to be odd

image_dim = lonarr(2) + imdim

psf_core = (npx-imdim)/2 + [ 0, imdim-1 ]
cpsf   = image_dim/2

;; Compute -2 pi x and -2 pi y
xypi = vis_bpmap_get_xypi( npx, pixel ) 
ic   = complex(0.0, 1.0) ; imaginary 1

;; Initialize PSF
psf00 = fltarr(npx, npx)
for nv = 0, nvis-1 do begin
  uv = reform( /over, vis[nv].u * xypi[0,*,*] + vis[nv].v * xypi[1,*,*] )
  psf00 += spatial_frequency_weight[nv] * float( complex( cos( uv ), sin(uv) ) )
endfor

;; Make the maximum value of the PSF equal to 1
psf00 = psf00/max(psf00)

;; Center the PSF in the pixel of index xypsf
xyshift =  ( n_elements( xypsf ) eq 1 ? get_ij( xypsf, imdim )  : xypsf )  - cpsf 
psf = (shift( psf00, xyshift))[ psf_core[0]:psf_core[1], psf_core[0]:psf_core[1] ]

return,psf

end