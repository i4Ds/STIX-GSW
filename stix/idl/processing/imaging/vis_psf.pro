
;+
; Project:
;   Gen/Image
; Name:
;   VIS_PSF
; Purpose:
;   This procedure makes and optionally displays a backprojection map from a visibility bag for
;   a unit delta function input, i.e. this is the point spread function backprojection map
; Calling Sequence:
;  vis_psf, vis, xypsf,  pixel=pixel, psf00=psf00, image_dim=image_dim, init=init, $
;    UNIFORM_WEIGHTING=uniform_weighting, spatial_freqency_weight =spatial_frequency_weight, $
;    _extra=_extra

; Inputs:
; Vis - visibility bag.  See {hsi_vis} for a compliant structure, must have
;   fields,  u, v, and obsvis
; xypsf - 1d index of location of psf in FOV or a 2d index such that the lower left hand corner has
;   a 1d index of 0 and 2d of [0,0] while the center of a 65x65 fov the center is at 32*65+32 or [32,32]
;
; Outputs:
; Returns a flat array back projection map for input
;   Overall normalization is arbitrary.
; Keywords
; image_dim - 1 or 2d vector with image dimensions, only first element is used for square fov
;   image_dim is forced to be an odd number
; INIT - If set, forces the recalculation of PSF00, the base point spread function to be reused by shifting
; PSF00 - Base point spread function computed at the center of the FOV using the input weighting parameters
;   and meant to be reused by shifting. It is not automatically recomputed if the FOV or weighting params
;   are changed but this must be done by setting INIT. PSF00 is meant to be reused within a CLEAN loop and
;   so the visibilities, weighting, fov, pixel size and all other parameters than could affect the PSF
;   will remain unchanged.
; ALT_SHAPE_PSF - non-delta function (finite width) axially symmetric shape to use as psf basis.
;   Can be used with pixon-like (parabolic) and gaussian profiles
; QUIET - (Through vis_bpmap) 1 or 0 If set suppresses  output to the screen, default is set
; NOPLOT - (Through vis_bpmap) 1 or 0 If set suppresses plot output, default is set

;
; LABEL - (Through vis_bpmap) plot title (Default is current time.), string
; UNIFORM_WEIGHTING, (Through vis_bpmap) 1 or 0, if set, changes subcollimator weighting from default (NATURAL) to UNIFORM
;   setting to 0 uses NATURAL weighting, either sets SPATIAL_FREQUENCY_WEIGHT, default is 0, NATURAL
;   which gives equal weight to each subcollimator
;
; SPATIAL_FREQUENCY_WEIGHT - (Through vis_bpmap) weighting for each collimator, set by UNIFORM_WEIGHTING if used
; The number of weights should either equal the number of unique sub-collimators or the number of visibilities
;   Also, the default RHESSI case is supported, passing 9 weights and the ones for each sc are selected from those
; LOOPSTYLE- for debugging, if set supports original style of bp computation in hsi_vis_bpmap, default is 0
; History
; 11-jun-2013, richard.schwartz@nasa.gov, developed to support vis_clean
; 18-jul-2013, richard.schwartz@nasa.gov, fixed bug from xyshift within init block
;     identified by Florian Mayer
; 22-oct-2013, richard.schwartz@nasa.gov, added alt_shape_psf to facilitate processing pixon(parabolic)
;   or Gaussians of finite width as the basis function instead of using a delta function
; 24-oct-2013, richard.schwartz@nasa.gov, increase fov to twice the normal fov to remove edge effects
;-


function vis_psf, vis, xypsf,  pixel=pixel, psf00=psf00, image_dim=image_dim, init=init, $
  UNIFORM_WEIGHTING=uniform_weighting, spatial_freqency_weight =spatial_frequency_weight, $
  alt_shape_psf = alt_shape_psf, $
  _extra=_extra
  ;
  default, init, 0
  default, pixel, 1.0
  default, image_dim, [65,65]
  imdim = image_dim[0] / 2 * 2 + 1 ;odd number of pixels
  image_dim = lonarr(2) + imdim
  npx = long( imdim * 2)
  npx = npx / 2 * 2 + 1 ;odd number of pixels

  ;Use these limits to extract the psf on the image pixels
  psf_core = (npx-imdim)/2 + [ 0, imdim-1 ]
  cpsf   = image_dim/2
  if (size(/dim, psf00))[0] ne npx then init = 1

  if init then begin
    pmap = fltarr(npx, npx)
    altmap = 0
    if keyword_set( alt_shape_psf ) then begin
      ;Check alt_shape_psf that it is no larger than npx x npx
      alt_psf_dim = size(/dimension, alt_shape_psf)
      if max( alt_psf_dim ) le npx then begin
        half = ( npx - alt_psf_dim[0] ) / 2
        pmap[ 0 + half : npx -1 - half, 0 + half : npx -1 - half ] = alt_shape_psf
        altmap =1
      endif
    endif
    if ~altmap then begin
      pmap[ npx/2, npx/2 ] = 1.0

      i0 = npx/2 -1 ;just need to sample around the center, really only the center pixel
      vxypsf = vis_map2vis( pmap[ i0:i0+2, i0:i0+2 ], xy, vis )
    endif else vxypsf = vis_map2vis( pmap[  0 + half : npx -1 - half, 0 + half : npx -1 - half ], $
      xy, vis )
    vis_bpmap, vxypsf, map = psf00, pixel = pixel, /data_only, bp_fov = npx * pixel, $
      spatial_freqency_weight = spatial_frequency_weight, _extra = _extra
  endif
  default, xypsf, cpsf

  xyshift =  ( n_elements( xypsf ) eq 1 ? get_ij( xypsf, imdim )  : xypsf )  - cpsf
  psf = (shift( psf00, xyshift))[ psf_core[0]:psf_core[1], psf_core[0]:psf_core[1] ]

  return,psf
end


