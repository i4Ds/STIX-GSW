;+
; NAME:
;   vis_fwdfit
;
; PURPOSE:
;   forward fit imaging algorithm based on visibilities
;
; CALLING SEQUENCE:
;   vis_fwdfit, visin0 [, NOPHASE=nophase]     [, CIRCLE=circle]    [, MAXITER = maxiter] [, ABSOLUTE=absolute]   $
;                      [, NOERR=noerr]         [, SRCIN = srcstrin] [, SRCOUT=srcstrout]  [, MULTI=multi]         $
;                      [, FITSTDDEV=fitstddev] [, LOOP=loop]        [, SHOWMAP=showmap]   [, NOPLOTFIT=noplotfit] $
;                      [, QFLAG=qflag]         [, ALBEDO=albedo]    [, SYSERR=syserr]     [, NOEDIT=noedit] $
;                      [, _EXTRA=extra]
;
; CALLS:
;   vis_fwdfit_fixedconfig          [to optimize parameters for a given source configuration]
;   vis_fwdfit_func                 [to calculate model visibilities for a given set of source parameters]
;   vis_fwdfit_plotfit              [to generate plotted display of fit]
;   vis_fwdfit_print                [Generates printed display of source structure]
;   vis_structure2array             [Converts source structure to an array for amoeba_c]
;   vis_src_structure__define       [Defines source structure format]
;
; INPUTS:
;   visin0 = an array of visibiltiy structures, each of which is a single visibility measurement.
;               visin0 is not modified by hsi_vis_fwdfit
;
; OPTIONAL INPUTS:
;	See keywords.
;
; OUTPUTS:
;   Prints fit parameters in log window.
;
; OPTIONAL OUTPUTS:
;   See keywords.
;
; KEYWORDS:
;   /CIRCLE = fits visibilities to a single, circular gaussian.  (Default is an circular gaussian)
;   /LOOP   = Fits visibilities to a single curved elliptical gaussian.
;   /MULTI  = fits visibilities to a pair of circular gaussians.
;   /ALBEDO = adds a combined albedo source to the other fitted components. (Not yet fully reliable.)
;   SRCIN   = specifies an array of source structures, (one for each source component) to use as a starting point.
;
;   /NOERR forces fit to ignore input statistical errors. (Default is to use statistical errors.)
;   SYSERR is an estimate of the systematic errors, expressed as a fraction of the amplitude. Default = 0.05
;
;   /NOFIT just creates the uvdat COMMON block but suppresses all other outputs.  No fitting is done.
;   /NOEDIT suppresses the default editing and coonjugate combining of the input visibilities.
;   /NOPHASE forces all input phases to zero.
;   /ABSOLUTE generates fit by minimizing the sum of ABS(input visibility - model visibility). Default = 0
;   MAXITER sets maximum number of iterations per stage (default = 2000)
;
;   SRCOUT names a source structure array to receive the fitted source parameters.
;   FITSTDDEV returns sigma in fitted quantities in SRCOUT.
;   QFLAG returns a quality flag whose bits indicate the type of problem found.  qflag=0 ==> fit appears ok.
;   REDCHISQ names a variable to receive the reduced chi^2 of fit.
;   NITER returns number of iterations done in fit.
;   /NOPLOTFIT suppresses plotfit display.    Default is to generate this display.
;   /SHOWMAP generates a PLOTMAN display of final map
;   /PLOTMAN uses the PLOT_MAP routine instead of plotman to display the final map if /SHOWMAP is set.
;   ID = a character string used to label plots.  (Start time is always shown.)
;   FIT_MASK = 10 element array.  0/1 means fix or fit corresponding element in src structure.
;
; _EXTRA keyword causes inheritance of additional keywords
;
; COMMON BLOCKS:
;	uvdata
;
; SIDE EFFECTS:
;	none
;
; RESTRICTIONS:
;   NB. This program is a wrapper around vis_fwdfit.
;   vis_fwdfit is still under development - should be used with caution and results reviewed critically.
;   Chi^2 output values are indeterminate if either /ABSOLUTE or /NOERR is set.
;   Bad fits are usually flagged with a warning message.
;
; MODIFICATION HISTORY:
; 21-nov-13, RAS    This is a wrapper around vis_fwdfit.
; stx_vis_fwdfit works in the default configuration but it needs /circle if point source is used. 
; Point source visibilities are unrealistic and should never be used.  
; So I have changed the default to /circle because of the faulty simulation default. 
; This needs to be reviewed.
;-
;
    
function stx_vis_fwdfit, visin0, $
;SRCIN = srcstrin, MULTI=multi, CIRCLE=circle, LOOP=loop, ALBEDO=albedo, FIT_MASK=fit_mask, $
;    NOPHASE=nophase, MAXITER = maxiter, ABSOLUTE=absolute, SYSERR=syserr, $
;    NOEDIT=noedit, NOERR=noerr, NOFIT=nofit, $    
;    SHOWMAP=showmap, NOPLOTFIT=noplotfit, $
    SRCOUT=srcstrout, FITSTDDEV=fitstddev, QFLAG=qflag, REDCHISQ=redchisq, NITER=niter, NFREE=nfree, $
    vf_vis_window=vf_vis_window, $
  pixel_size = pixel_size, image_dim = image_dim, xyoffset=xyoffset, $
  image_out = image_out, $
   _REF_EXTRA=extra

;Look for stix visibility structure and extract the vis bag if necessary in hsi-like format    
vis_input =  stx2hsi_vis( visin0 )
default, circle, 1

vis_fwdfit, vis_input, $

    SRCOUT=srcstrout, FITSTDDEV=fitstddev, QFLAG=qflag, REDCHISQ=redchisq, NITER=niter, NFREE=nfree, $
    circle = circle, $
    vf_vis_window=vf_vis_window, $
    _EXTRA = extra


param_out = { srcout: srcstrout, sigma: fitstddev, niter: niter, $
  redchi2: redchisq, nfree: nfree, qflag: qflag, vf_vis_window: fcheck( vf_vis_window, -1) }

default, xyoffset, [0.0, 0.0]
default, pixel_size, 1.0
default, image_dim, [65., 65.]

vis_source2map, srcstrout, xyoffset, image_out, $
    pixel = pixel_size, $
    mapsize = image_dim[0]

map_out = make_map( image_out, dx=pixel_size, dy= pixel_size, xc = xyoffset[0], yc= xyoffset[0] )

this_time_range=stx_time2any(vis[0].time_range,/vms)

;; Mapcenter corrected for Frederic's mean shift values
map_out.xc = vis[0].xyoffset[0] + 26.1
map_out.yc = vis[0].xyoffset[1] + 58.2

;; Roll angle correction
roll_angle = stx_get_roll_angle_temp(this_time_range[0])
map_out.roll_angle = roll_angle

return, map_out
end
 