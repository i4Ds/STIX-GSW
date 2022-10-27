;+
;
; NAME:
;   stx_estimate_flare_location
;
; PURPOSE:
;   Automatic estimate of the flare location (arcsec, Helioprojective Cartesian coordinates, Solar Orbiter vantange point) 
;
; CALLING SEQUENCE:
;   stx_estimate_flare_location, path_sci_file, time_range, aux_data, flare_loc=flare_loc
;
; INPUTS:
;   path_sci_file: string containing the path of the science L1 fits file of the event
;   
;   time_range: string array containing the selected start and the end time 
;   
;   aux_data: auxiliary data structure corresponding to the selected time range 
;   
;   
;
; KEYWORDS:
;   flare_loc: output, estimate of the flare location (arcsec, Helioprojective Cartesian coordinates, 
;                      Solar Orbiter vantange point)
;                 
;   path_bkg_file: path of the background L1 fits file used for background subtraction
;   
;   energy_range: energy range to be considered for performing the full-disk Back Projection and the forward fitting method 
;                 (default, 6-10 keV)
;   
;   imsize: number of pixels of the full-disk Back Projection map (default, [512,512])
;   
;   mapcenter: center of the Back Projection map (default, [0.,0.])
;   
;   subc_index: array containing the indices of the subcollimators used for computing the Back Projection map 
;               (default, detectors from 7 to 10)
;               
;   silent: set to 1 for avoiding the plot of the full-disk the Back Projection map and of the estimated flare location 
;           (default, 0)
;   
; HISTORY: October 2022, Massa P. (WKU), initial release
;
; CONTACT:
;   paolo.massa@wku.edu
;-

pro stx_estimate_flare_location, path_sci_file, time_range, aux_data, flare_loc=flare_loc, path_bkg_file=path_bkg_file, $
                                 energy_range=energy_range, imsize=imsize, mapcenter=mapcenter, $
                                 subc_index=subc_index, silent=silent, this_win=this_win, _extra=extra

default, energy_range, [6.,10.]
default, imsize, [512,512]
default, mapcenter, [0., 0.]
default, subc_index, stx_label2ind(['10a','10b','10c','9a','9b','9c','8a','8b','8c','7a','7b','7c'])
default, silent, 0
default, this_win, 4

;;******* Determine the pixel size from the apparent radius of the Sun for computing a full-disk Back Projection map
rsun = aux_data.RSUN
pixel = rsun * 2.6 / imsize ; 2.6 is chosen arbitrarily so that field of view Back Projection map used 
                            ; for determining the flare location contains the entire solar disk 

;;******* Construct the visibility structure
mapcenter_stix = stx_hpc2stx_coord(mapcenter, aux_data)

vis = stx_construct_visibility(path_sci_file, time_range, energy_range, mapcenter_stix, $
                                          path_bkg_file=path_bkg_file,subc_index=subc_index,  /silent, $
                                          _extra=extra)

;;******* Use Giordano's (u,v) points: no need to perform projection correction (see Giordano et al., 2015)
subc_str = stx_construct_subcollimator()
uv = stx_uv_points_giordano()
u = -uv.u * subc_str.phase
v = -uv.v * subc_str.phase
vis.u = u[subc_index]
vis.v = v[subc_index]

vis = stx_calibrate_visibility(vis)

;;******* Compute the Back Projection map
bp_nat_map = stx_bproj(vis,imsize,pixel,aux_data)

;;******* Compute the coordinates of the peak of the Back Projection map (coarse estimate of the flare location)
max_bp       = max(bp_nat_map.data, ind_max)
ind_max      = array_indices(bp_nat_map.data, ind_max)
max_bp_coord = [(ind_max[0]-imsize[0]/2)*pixel[0]+mapcenter[0], (ind_max[1]-imsize[1]/2)*pixel[1]+mapcenter[1]]

;;******* VIS_FWDFIT reconstruction around the peak of the Back Projection map to improve the accuracy 
;         of the flare location estimate

max_bp_coord_stix = stx_hpc2stx_coord(max_bp_coord, aux_data)
vis = stx_construct_calibrated_visibility(path_sci_file, time_range, energy_range, max_bp_coord_stix, $
                                          path_bkg_file=path_bkg_file, xy_flare=max_bp_coord_stix, /silent, _extra=extra)

configuration = 'circle'
vis_fwdfit_pso_map = stx_vis_fwdfit_pso(configuration,vis,aux_data,srcstr=srcstr,/silent)

; Estimate of the flare location: coordinates of the center of the Gaussian fitting                                        
flare_loc = [srcstr.SRCX, srcstr.SRCY]

if ~silent then begin
  
  loadct,3, /silent
  device, Window_State=win_state
  if win_state[this_win] then wset, this_win else window,this_win,xsize=1200,ysize=600
  cleanplot, /silent
  !p.multi = [0,2,1]
                        
  ;;******* Plot of full-disk Back Projection map                      
  plot_map, bp_nat_map, /limb, grid_spacing=10, charsize=2, title = 'Full-disk Back-projection'
  linecolors, /quiet
  tvcircle, rsun/4, flare_loc[0], flare_loc[1], color=7, thick=2

  ;;******* Plot of the estimated flare location (red cross)
  plot_map, bp_nat_map, /cbar, /limb, grid_spacing=10, /no_data,charsize=2, title = 'Estimated flare location'
  linecolors, /quiet
  oplot, [flare_loc[0]], [flare_loc[1]], psym=1, color=2, symsize=3, thick=3
  ssw_legend, ['X=' + num2str(fix(flare_loc[0])) + ' arcsec', 'Y=' + num2str(fix(flare_loc[1])) + ' arcsec'], $
    TEXTCOLORS=[2], /right, charsize=1.5, BOX=0, CHARTHICK=1.5

endif


end

