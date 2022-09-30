;+
;
; NAME:
;   stx_estimate_location
;
; PURPOSE:
;   Automatic estimate of the flare location (Helioprojective coordinates) from a full-disk Back Projection map 
;
; CALLING SEQUENCE:
;   stx_estimate_location, path_sci_file, max_bp_coord=max_bp_coord
;
; INPUTS:
;   path_sci_file: path of the science L1 fits file of the event (string)
;   
;   time_range: string array containing the start and the end time
;   
;   aux_data: auxiliary data structure corresponding to the selected time range 
;   
;   
;
; KEYWORDS:
;   flare_loc: output, estimate of the flare location (arcsec, Helioprojective cartesian)
;                 
;   path_bkg_file: path of the background L1 fits file used for background subtraction
;   
;   energy_range: energy range to consider for computing the Back Projection map (default, 6-10 keV)
;   
;   imsize: number of pixels of the Back Projection map (default, [512,512])
;   
;   mapcenter: center of the Back Projection map (default, [0.,0.])
;   
;   subc_index: array containing the indices of the subcollimators used for computing the Back Projection map 
;               (default, detectors from 7 to 10)
;               
;   silent: set to 1 for avoiding the plot of the full-disk the Back Projection map (default, 0)
;   
; HISTORY: March 2022, Massa P. created
;
; CONTACT:
;   massa.p [at] dima.unige.it
;-

pro stx_estimate_flare_location, path_sci_file, time_range, aux_data, flare_loc=flare_loc, path_bkg_file=path_bkg_file, $
                                 energy_range=energy_range, imsize=imsize, mapcenter=mapcenter, $
                                 subc_index=subc_index, silent=silent, _extra=extra

default, energy_range, [6.,10.]
default, imsize, [512,512]
default, mapcenter, [0., 0.]
default, subc_index, stix_label2ind(['10a','10b','10c','9a','9b','9c','8a','8b','8c','7a','7b','7c'])
default, silent, 0

;;******* Determine the pixel size from the apparent radius of the Sun for computing a full-disk Back Projection map
rsun = aux_data.RSUN
pixel = rsun * 2.6 / imsize

;;******* Compute the visibility values

mapcenter_stix = stx_hpc2stx_coord(mapcenter, aux_data)

vis = stx_construct_calibrated_visibility(path_sci_file, time_range, energy_range, mapcenter_stix, $
                                          path_bkg_file=path_bkg_file,subc_index=subc_index, _extra=extra)


;;******* Use Giordano's (u,v) points: no need to perform projection correction (see Giordano et al., 2015)
subc_str = stx_construct_subcollimator()
uv = stx_uv_points_giordano()
u = -uv.u * subc_str.phase
v = -uv.v * subc_str.phase
vis.u = u[subc_index]
vis.v = v[subc_index]

;;******* Compute the Back Projection map
bp_nat_map = stx_bproj(vis,imsize,pixel,aux_data)

;;******* Compute the coordinates of the maximum value of the Back Projection map, i.e. of the location of the flare
max_bp       = max(bp_nat_map.data, ind_max)
ind_max      = array_indices(bp_nat_map.data, ind_max)
max_bp_coord = [(ind_max[0]-imsize[0]/2)*pixel[0]+mapcenter[0], (ind_max[1]-imsize[1]/2)*pixel[1]+mapcenter[1]]

;;;;******* VIS_FWDFIT reconstruction around the maximum to improve the accuracy of the location
;vis = stx_construct_calibrated_visibility(path_sci_file, time_range, energy_range, max_bp_coord, $
;                                          path_bkg_file=path_bkg_file, xy_flare=max_bp_coord)
;
;type='circle'
;vis_fwdfit_pso_map = stx_vis_fwdfit_pso(type,vis,aux_data,imsize=imsize_ql,pixel=pixel_ql,srcstr=srcstr,/silent)
;
;stx_pointing = aux_data.STX_POINTING
;roll_angle   = aux_data.ROLL_ANGLE
;
;stx_pointing_rot = stx_pointing
;stx_pointing = [srcstr.SRCX, srcstr.SRCY];stx_pointing
;stx_pointing_rot[0] = cos(roll_angle)  * stx_pointing[0] - sin(roll_angle) * stx_pointing[1]
;stx_pointing_rot[1] = sin(roll_angle) * stx_pointing[0] + cos(roll_angle) * stx_pointing[1]
;
;flare_loc = stx_pointing_rot ;+ stx_pointing_rot
flare_loc  = max_bp_coord + aux_data.STX_POINTING
;;;******* 


if ~silent then begin

;;******* Plot the full-disk Back Projection map and overlay the location of the flare (green cross)
window,4,xsize=1200,ysize=600

!p.multi = [0,2,1]

plot_map, bp_nat_map, /cbar, /limb, grid_spacing=10, /no_data,charsize=2, title = 'Estimate flare location'
linecolors, /quiet
oplot, [flare_loc[0]], [flare_loc[1]], psym=1, color=2, symsize=3, thick=3
ssw_legend, ['X=' + num2str(fix(flare_loc[0])) + ' arcsec', 'Y=' + num2str(fix(flare_loc[1])) + ' arcsec'], $
            TEXTCOLORS=[2], /right, charsize=1.5, BOX=0, CHARTHICK=1.5

loadct,3, /silent            
                       
plot_map, bp_nat_map, /limb, grid_spacing=10, charsize=2, title = 'Full-disk Back-projection'
linecolors, /quiet
tvcircle, rsun/3, flare_loc[0], flare_loc[1], color=7, thick=2
oplot, [flare_loc[0]], [flare_loc[1]], psym=1, color=7, symsize=3, thick=2

endif


end

