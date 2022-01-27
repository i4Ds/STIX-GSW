;+
; Project:
; stx/idl/gen/imaging
; Name:
; STX_VIS_BPMAP
; Purpose:
; This procedure makes and optionally displays a backprojection map from a visibility bag
; Calling Sequence:
; stx_vis_bpmap, visin,time=time,_EXTRA=extra,BP_FOV=bp_fov, PIXEL=pixel, MAP=map, $
;     QUIET=quiet, PEAKXY=peakxy, NOPLOT=noplot, EDGEFLAG=edgeflag,  $
;     label=label, UNIFORM_WEIGHTING=uniform_weighting, spatial_freqency_weight =spatial_frequency_weight, $
;     data_only = data_only, $
;     LOOPSTYLE = loopstyle, $
;     _EXTRA=_extra
; Inputs:
; Visin - visibility bag.  See {hsi_vis} or stx_visibility() for a compliant structure, must have
;   fields,  u, v, and obsvis
;   IDL> help, {hsi_vis},/st
;   ** Structure HSI_VIS, 15 tags, length=104, data length=94:
;   ISC             INT              0
;   HARM            INT              0
;   ERANGE          FLOAT     Array[2]
;   TRANGE          DOUBLE    Array[2]
;   U               FLOAT          0.000000
;   V               FLOAT          0.000000
;   OBSVIS          COMPLEX   (     0.000000,     0.000000)
;   TOTFLUX         FLOAT          0.000000
;   SIGAMP          FLOAT          0.000000
;   CHI2            FLOAT          0.000000
;   XYOFFSET        FLOAT     Array[2]
;   TYPE            STRING    ''
;   UNITS           STRING    ''
;   ATTEN_STATE     INT              0
;   COUNT           FLOAT          0.000000
; Outputs:
; Map - flat array back projection map or map structure if DATA_ONLY is set to 0
;   Overall normalization is arbitrary.
; Keywords
;
; /QUIET suppresses  output to the screen, default is 1
; /NOPLOT suppresses plot output, default is 1
; DATA_ONLY - default is 1, if set, return a flat array, otherwise a map structure
; PEAKXY = 2-element vector to receive location of |map| maximum
; EDGEFLAG is set to -1 if peak map pixel is at one edge of the map.  In that case, peakxy is not interpolated
; LABEL = plot title (Default is current time.)
; UNIFORM_WEIGHTING - 0/1 default is 0,
;   changes subcollimator weighting from default (NATURAL) to UNIFORM
;   setting to 0 uses NATURAL weighting, either sets SPATIAL_FREQUENCY_WEIGHT
; BP_FOV = field of view (arcsec) Default = 80. arcsec
; SPATIAL_FREQUENCY_WEIGHT - weighting for each collimator, set by UNIFORM_WEIGHTING if used
; The number of weights should either equal the number of unique sub-collimators or the number of visibilities
;   Also, the default RHESSI case is supported, passing 9 weights and the ones for each sc are selected from those
; LOOPSTYLE- for debugging, if set supports original style of bp computation in hsi_vis_bpmap
; History
; 14-feb-13 ras Originally developed for RHESSI, as hsi_vis_bpmap, but this adaptation is generic for any visibility bag
;   with u, v, and obsvis
;   Vectorized computation of the xy pixel values and scaled them by -2 * !pi
;               Also fixed centering of xy pixels for odd npx
; 18-jul-2013, ras, cleaned up documentation, use vis_spatial_frequency() function in vis_bpmap_get_spatial_weights()
; 22-jul-2013, ras, migrated to stx_vis_bpmap, this is a wrapper on $SSW/gen/idl/image/vis_bpmap
;-
pro stx_vis_bpmap_old, visin, time=time, BP_FOV=bp_fov, PIXEL=pixel, MAP=map, $
    QUIET=quiet, PEAKXY=peakxy, NOPLOT=noplot, EDGEFLAG=edgeflag,  $
    label=label, UNIFORM_WEIGHTING=uniform_weighting, spatial_freqency_weight =spatial_frequency_weight, $
    data_only = data_only, $
    LOOPSTYLE = loopstyle, $
    _EXTRA=_extra

default, bp_fov,   80
default, pixel,    bp_fov/200.
default, quiet,  1
default, noplot, 1
default, data_only, 1
default, loopstyle, 0
default, uniform_weighting, 0

    
vis_bpmap, visin,time=time, BP_FOV=bp_fov, PIXEL=pixel, MAP=map, $
    QUIET=quiet, PEAKXY=peakxy, NOPLOT=noplot, EDGEFLAG=edgeflag,  $
    label=label, UNIFORM_WEIGHTING=uniform_weighting, spatial_freqency_weight =spatial_frequency_weight, $
    data_only = data_only, $
    LOOPSTYLE = loopstyle, $
    _EXTRA=_extra


end    
