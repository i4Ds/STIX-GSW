;+
;
; NAME:
; 
;   stx_make_map
;
; PURPOSE:
; 
;   Create a map from a STIX reconstruction (SOLO HPC coordinate). Observed visibilities used to reconstruct the map
;   and visibilities predicted from the map are saved in the map structure
;
; CALLING SEQUENCE:
; 
;   stx_map = stx_make_map(im_map, aux_data, pixel, method, vis)
;
; INPUTS:
; 
;   im_map: image reconstruted with a STIX imaging method (STIX coordinate frame)
;   
;   aux_data: auxiliary data structure containing information on STIX pointing and spacecraft ephemeris
;   
;   pixel: bi-dimensional array containing the pixel size in arcsec
;   
;   method: string indicating which method has been used for reconstructing the image passed in im_map
;   
;   vis: visibility structure used for reconstructing an image
;
; OUTPUTS:
; 
;   Map structure. The following fields are added:
;   
;     - ENERGY_RANGE: array containing the lower and upper edge of the energy interval used for reconstructing 'im_map' (keV)
;     
;     - OBS_VIS: visibility structure used for reconstructing 'im_map'
;     
;     - PRED_VIS: structure containing the complex values of the visibilities predicted from 'im_map'. Used for displaying data 
;                 fitting plots and for computing the chi2 value associated with 'im_map'
;                 
;     - AUX_DATA: auxiliary data srtucture used for reconstructing 'im_map'
;     
;     - RSUN: apparent radius of the SUN (arcsec)
;     
;     - L0: Heliographic longitude (degrees)
;     
;     - B0: Heliographic latitude (degrees)
;              
;     - COORD_FRAME: string indicating the coordinate system of the output map (SOLO HPC)
;
;     - UNITS: string indicating the units of reconstructed map (photons cm^-2 asec^-2 s^-1 keV^-1)
;     
; HISTORY: September 2022, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-

function stx_make_map, im_map, aux_data, pixel, method, vis

imsize = size(im_map, /dim)

;; Compute visibilities predicted from the reconstructed map: used for displaying data fitting plots and 
;; for computing chi2 values associated with the reconstruction
F = vis_map2vis_matrix(vis.u, vis.v, imsize, pixel)
mapvis = F # im_map[*]

pred_vis = {mapvis: mapvis, $     ; Complex visibility values predicted from the map
            isc:    vis.ISC, $    ; Subcollimator index
            label:  vis.LABEL, $  ; Subcollimator label
            u: vis.u, $           ; U coordinates of the frequencies sampled by the subcollimators
            v: vis.v  $           ; V coordinates of the frequencies sampled by the subcollimators
            }


out_map = make_map(rotate(im_map,1))

id_map = 'STX ' + method + ': '
out_map.ID = id_map

out_map.dx = pixel[0]
out_map.dy = pixel[1]

time_range     = vis[0].TIME_RANGE
this_time_range=stx_time2any(time_range,/vms)

out_map.time = anytim((anytim(this_time_range[1])+anytim(this_time_range[0]))/2.,/vms)
out_map.dur  = anytim(this_time_range[1])-anytim(this_time_range[0])

;; Mapcenter coordinates
mapcenter = stx_rtn2stx_coord(vis[0].xyoffset, aux_data, /inverse)

out_map.xc = mapcenter[0]
out_map.yc = mapcenter[1]
out_map=rot_map(out_map,-aux_data.ROLL_ANGLE,rcenter=[0.,0.])
out_map.roll_angle = 0.

;; Add properties
energy_range   = vis[0].ENERGY_RANGE

add_prop, out_map, energy_range   = energy_range          ; energy range in keV
add_prop, out_map, obs_vis        = vis                   ; Visibility structure used for image reconstruction
add_prop, out_map, pred_vis       = pred_vis              ; Visibility values predicted from the reconstucted map       
add_prop, out_map, aux_data       = aux_data              ; Auxiliary data structure
add_prop, out_map, time_range     = time_range            ; Time range considered for image reconstruction
;add_prop, out_map, tot_counts     = vis[0].TOT_COUNTS     ; Total number of counts measured by the selected imaging detector
;add_prop, out_map, tot_counts_bkg = vis[0].TOT_COUNTS_BKG ; Estimate of the total number of background counts measured by the selected imaging detector
add_prop, out_map, rsun = aux_data.RSUN
add_prop, out_map, b0   = aux_data.B0
add_prop, out_map, l0   = aux_data.L0
add_prop, out_map, coord_frame = 'SOLO HPC'
add_prop, out_map, units = 'counts cm^-2 asec^-2 s^-1 keV^-1'

return, out_map


end