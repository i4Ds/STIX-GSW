;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_imaging_demo
;
; :description:
;    This demonstration script shows how to read a Level 1(A) STIX science data files and create a visibility structure.
;    This structure is then used for image reconstruction by means of all the available imaging algorithms
;
; :categories:
;    demo, imaging
;
; :history:
;   02-september-2021, Massa P., first release
;   23-august-2022, Massa P., made compatible with the up-to-date imaging sofwtare
;
;-


; Folder in which the files downloaded for this demonstration are stored
out_dir = concat_dir( getenv('stx_demo_data'),'imaging', /d)

;;**************** LOAD DATA - June 7 2020, 21:41 UT

; STIX data center URL
website_url = 'https://datacenter.stix.i4ds.net/download/fits/bsd/'

uid_sci_file = "1178428688"

sock_copy, website_url + uid_sci_file, out_name, status = status, out_dir = out_dir, $
           local_file=path_sci_file, clobber=0
           
uid_bkg_file = "1178451984"

sock_copy, website_url + uid_bkg_file, out_name, status = status, out_dir = out_dir, $
           local_file=path_bkg_file, clobber=0

; L2 auxiliary fits files server URL
website_url = 'http://dataarchive.stix.i4ds.net/fits/L2/'
file_name    = '2020/06/07/AUX/solo_L2_stix-aux-ephemeris_20200607_V01.fits'

sock_copy, website_url + file_name, out_name, status = status, out_dir = out_dir, $
           local_file=aux_fits_file, clobber=0
 
time_range    = ['7-Jun-2020 21:39:00', '7-Jun-2020 21:42:49'] ; Time range to consider
energy_range  = [6,10]        ; Energy range to consider (keV)
mapcenter     = [-1575, -780] ; Coordinates of the center of the map to reconstruct (Helioprojective Cartesian from Solar Orbiter vantage point)
xy_flare      = mapcenter     ; Estimated flare location (Helioprojective Cartesian from Solar Orbiter vantage point)


;;**************** CONSTRUCT VISIBILITY STRUCTURE

; Create a structure containing auxiliary data to use for image reconstruction
; - STX_POINTING: X and Y coordinates of STIX pointing (arcsec, SOLO_SUN_RTN coordinate frame). 
;                 It is derived from the SAS solution (if available) or from the spacecraft pointing 
;                 (plus average SAS solution)
; - RSUN: apparent radius of the Sun in arcsec
; - ROLL_ANGLE: spacecraft roll angle in degrees
; - L0: Heliographic longitude in degrees
; - B0: Heliographic latitude in degrees
aux_data = stx_create_auxiliary_data(aux_fits_file, time_range)

stx_estimate_flare_location, path_sci_file, time_range, aux_data, flare_loc=flare_loc, path_bkg_file=path_bkg_file

; Compute the array of detector indices (from 0 to 31) from the corresponding labels.
; Used for selecting the detectors to consider for making the images
;subc_index = stix_label2ind(['10a','10b','10c','9a','9b','9c','8a','8b','8c','7a','7b','7c',$
;                             '6a','6b','6c','5a','5b','5c','4a','4b','4c','3a','3b','3c'])

; Create the visibility structure filled with the measured data

; Coordinate transformaion: from Helioprojective Cartesian to STIX coordinate frame
mapcenter_stix = stx_hpc2stx_coord(mapcenter, aux_data)
xy_flare_stix  = stx_hpc2stx_coord(xy_flare, aux_data)

vis=stx_construct_calibrated_visibility(path_sci_file, time_range, energy_range, mapcenter_stix, $
                                        path_bkg_file=path_bkg_file, xy_flare=xy_flare_stix)

stop

;;**************** SET PARAMETERS FOR IMAGING

imsize    = [129, 129]    ; number of pixels of the map to recinstruct
pixel     = [2.,2.]       ; pixel size in arcsec

;******************************************* BACKPROJECTION ********************************************************

; For using 'stix_show_bproj' create the visibility structure with the default 'subc_index' (from 10 to 3). Otherwise
; it throws an error
stx_show_bproj,vis,aux_data,imsize=imsize,pixel=pixel,out=bp_map,scaled_out=scaled_out
;
; - Window 0: each row corresponds to a different resolution (from top to bottom, label 10 to 3). The first three
;             columns refer to label 'a', 'b' and 'c'; the last column is the  sum of the first three.
; - Window 2: Natural weighting (first row) and uniform weighting (second row). From left to right, backprojection
;             obtained starting from subcollimators 10 and subsequently adding subcollimators with finer resolution


; BACKPROJECTION natural weighting
bp_nat_map = stx_bproj(vis,imsize,pixel,aux_data)

; BACKPROJECTION uniform weighting
bp_uni_map = stx_bproj(vis,imsize,pixel,aux_data,/uni)

stop

;**************************************** CLEAN (from visibilities) **********************************************

niter  = 200    ;number of iterations
gain   = 0.1    ;gain used in each clean iteration
nmap   = 1      ;only every 20th integration is shown in plot

;Output are 5 maps
;index 0: CLEAN map
;index 1: Bproj map
;index 2: residual map
;index 3: clean component map
;index 4: clean map without residuals added
beam_width = 20.
clean_map=stx_vis_clean(vis,aux_data,niter=niter,image_dim=imsize[0],PIXEL=pixel[0],uni=0,gain=0.1,nmap=nmap,/plot,/set, beam_width=beam_width)

stop

;;************************************************ MEM_GE *********************************************************

; Maximum entropy method (see Massa P. et al 2020 for details)
mem_ge_map=stx_mem_ge(vis,imsize,pixel,aux_data)

window, 0
cleanplot
plot_map, mem_ge_map, /cbar,title='MEM_GE - CLEAN contour (50%)'
plot_map,clean_map[0],/over,/perc,level=[50]

stop

;*************************************** Expectation Maximization ************************************************

pixel_data_summed = stx_construct_pixel_data_summed(path_sci_file, time_range, energy_range, path_bkg_file=path_bkg_file, $
                                                    xy_flare=xy_flare_stix)

em_map = stx_em(pixel_data_summed, aux_data, imsize=imsize, pixel=pixel,$
                mapcenter=mapcenter_stix)

loadct, 5
window, 0
cleanplot
plot_map, em_map, /cbar,title='EM - CLEAN contour (50%)'
plot_map,clean_map[0],/over,/perc,level=[50]

stop

;*************************************** VIS_FWDFIT ************************************************

configuration = ['circle','circle'];'ellipse'

; Comments:
; 1) use the keyword srcin to fix some of the parameters (and fit the remaining ones);
;    Please, see the header of the FWDFIT-PSO procedure for details
; 2) 'srcstrout_pso' is a structure containing the values of the optimized parameters
; 3) 'fitsigmasout_pso' is a structure containing the uncertainty on the optimized parameters
; 4) set /uncertainty for computing an estimate of the uncertainty on the parameters

vis_fwdfit_pso_map = stx_vis_fwdfit_pso(configuration,vis,aux_data,imsize=imsize,pixel=pixel, $
                                        srcstr = srcstrout_pso,fitsigmas=fitsigmasout_pso,/uncertainty)

loadct, 5
window, 0
cleanplot
plot_map, vis_fwdfit_pso_map, /cbar,title='VIS_FWDFIT_PSO - CLEAN contour (50%)'
plot_map,clean_map[0],/over,/perc,level=[50]

stop

;*********************************************** COMPARISON ******************************************************

window,0,xsize=5*imsize[0],ysize=5*imsize[0]
cleanplot
!p.multi=[0,2,2]
chs2=1.
plot_map,clean_map[0],charsize=chs2,title='CLEAN'
plot_map,mem_ge_map,charsize=chs2,title='MEM_GE'
plot_map,em_map,charsize=chs2,title='EM'
plot_map,vis_fwdfit_pso_map,charsize=chs2,title='VIS_FWDFIT_PSO'



end