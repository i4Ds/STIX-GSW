;+
; Name: stx_vis_clean
;
; Purpose: This function returns the clean map including residuals using visibilities
;
; Inputs:
;   - vis - visibility bag
;
; Keyword inputs:
;   - niter        max iterations  (default 100)
;   - image_dim    number of pixels in x and y, 1 or 2 element long vector or scalar
;       images are square so the second number isn't used
;   - pixel        pixel size in asec (pixels are square)
;   - gain         clean loop gain factor (default 0.05)
;   - clean_box    clean only these pixels (1D index) in the fov
;   - negative_max if set stop when the absolute maximum is a negative value (default 1)
;   - beam_width   psf beam width (fwhm) in asec
;   - spatial_frequency_weight
;
; Keyword outputs:
;   - iter
;   - dirty_map    two maps in an [image_dim, 2] array (3 dim), original dirty map first, last unscaled dirty map second
;   - clean_beam   the idealized Gaussian PSF
;   - clean_map    the clean components convolved with normalized clean_beam
;   - clean_components structure containing the fluxes of the identified clean components
;         ** Structure <1ee894d8>, 3 tags, length=8, data length=8, refs=1:
;             IXCTR           INT              0
;             IYCTR           INT              0
;             FLUX            FLOAT            0.00000
; - clean_sources_map the clean components realized as point sources on an fov map (lik)
; History:
; 12-feb-2013, Anna Massone and Richard Schwartz, based on hsi_map_clean
; 11-jun-2013, Richard Schwartz, identified error in subtracting gain modified psf from
;  dirty map. Before only psf had been subtracted!!!
; 17-jul-2013, Richard Schwartz, converted beam_width to pixel units for st_dev on call to
;  psf_gaussian for self-consistency
; 23-jul-2013, wraps vis_clean(), this version created as a pre-cursor to vis_clean object 
;   and stx_vis_clean object, info_struct added in vis_clean for output consolidation
; 
;-


function stx_vis_clean_old, vis, niter = niter, image_dim = image_dim_in, pixel = pixel, $
  _extra = _extra,  $
  spatial_frequency_weight = spatial_frequency_weight, $
  gain = gain, clean_box = clean_box, negative_max = negative_max, $
  beam_width = beam_width, $
  clean_beam = clean_beam, $
  ;Outputs
  iter = iter, dirty_map = dirty_map,$
  clean_map = clean_map, clean_components = clean_components, $
  clean_sources_map = clean_sources_map, $
  resid_map = resid_map
  
  clean_image =vis_clean( vis, niter = niter, image_dim = image_dim_in, pixel = pixel, $
  _extra = _extra,  $
  spatial_frequency_weight = spatial_frequency_weight, $
  gain = gain, clean_box = clean_box, negative_max = negative_max, $
  beam_width = beam_width, $
  clean_beam = clean_beam, $
  ;Outputs
  iter = iter, dirty_map = dirty_map,$
  clean_map = clean_map, clean_components = clean_components, $
  clean_sources_map = clean_sources_map, $
  resid_map = resid_map, $
  info_struct = info_struct )
  
  
  return, clean_image
  end
