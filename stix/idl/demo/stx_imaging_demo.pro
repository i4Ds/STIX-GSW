;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_imaging_demo
;
; :description:
;    This demonstration script shows how to read a Level 1(A) STIX science data file and to reconstruct the image of the 
;    flaring X-ray source by means of every available imaging algorithm
;
; :categories:
;    demo, imaging
;
; :history:
;   02-september-2021, Massa P., first release
;   23-august-2022, Massa P., made compatible with the up-to-date imaging sofwtare
;
;-

;;******************************** LOAD DATA - June 7 2020, 21:41 UT ********************************

; Folder in which the files downloaded for this demonstration are stored
out_dir = concat_dir( getenv('STX_DEMO_DATA'),'imaging', /d)


; URL of the STIX data center
website_url = 'https://datacenter.stix.i4ds.net/download/fits/bsd/'

; UID of the science fits file to be dowloaded from the website
uid_sci_file = "1178428688"
; Download the science fits file (if not already stored in out_dir)
sock_copy, website_url + uid_sci_file, out_name, status = status, out_dir = out_dir, $
           local_file=path_sci_file, clobber=0

; UID of the background fits file to be dowloaded from the website           
uid_bkg_file = "1178082832"
; Download the background fits file (if not already stored in out_dir)
sock_copy, website_url + uid_bkg_file, out_name, status = status, out_dir = out_dir, $
           local_file=path_bkg_file, clobber=0

; URL of the server containing the L2 auxiliary fits files
website_url = 'http://dataarchive.stix.i4ds.net/fits/L2/'
; Filename of the auxiliary L2 fits file to be downloaded
file_name    = '2020/06/07/AUX/solo_L2_stix-aux-ephemeris_20200607_V01.fits'
; Download the L2 auxiliary fits file (if not already stored in out_dir)
sock_copy, website_url + file_name, out_name, status = status, out_dir = out_dir, $
           local_file=aux_fits_file, clobber=0

stop

;;*********************************** SET TIME AND ENERGY RANGES ***********************************

; Time range to be selected for image reconstruction
time_range    = ['7-Jun-2020 21:39:00', '7-Jun-2020 21:42:49']
; Energy range to be selected for image reconstruction (keV) 
energy_range  = [6,10]

stop

;;******************************** CONSTRUCT AUXILIARY DATA STRUCTURE ********************************

; Create a structure containing auxiliary data to use for image reconstruction
; - STX_POINTING: X and Y coordinates of STIX pointing (arcsec, SOLO_SUN_RTN coordinate frame). 
;                 The coordinates are derived from the STIX SAS solution (when available) or from 
;                 the spacecraft pointing information 
; - RSUN: apparent radius of the Sun in arcsec
; - ROLL_ANGLE: spacecraft roll angle in degrees
; - L0: Heliographic longitude in degrees
; - B0: Heliographic latitude in degrees

aux_data = stx_create_auxiliary_data(aux_fits_file, time_range)

stop

;*************************************** ESTIMATE FLARE LOCATION **************************************

; Returns the coordinates of the estimated flare location (arcsec, Helioprojective Cartesian coordinates 
; from Solar Orbiter vantage point) in the 'flare_loc' keyword. These coordinates are used for setting the
; center of the maps to be reconstructed

stx_estimate_flare_location, path_sci_file, time_range, aux_data, flare_loc=flare_loc, $
                             path_bkg_file=path_bkg_file

stop

;************************************ CONSTRUCT VISIBILITY STRUCTURE ***********************************

; Set the coordinates of the center of the map to be reconstruct ed ('mapcenter') and of the estimated flare 
; location ('xy_flare'). The latters are used for performing a projection correction to the visibility
; phases and for correcting the grid internal shadowing effect. The coordinates given as input to the 
; imaging pipeline have to be conceived in the STIX reference frame; hence, we perform a transformation
; from Helioprojective Cartesian to STIX reference frame with 'stx_hpc2stx_coord'

mapcenter = stx_hpc2stx_coord(flare_loc, aux_data)
xy_flare  = mapcenter

; Create a calibrated visibility structure. For selecting the subcollimators to be used, uncomment the following
; lines and set the labels of the sub-collimators to be considered

;subc_index = stx_label2ind(['10a','10b','10c','9a','9b','9c','8a','8b','8c','7a','7b','7c',$
;                             '6a','6b','6c','5a','5b','5c','4a','4b','4c','3a','3b','3c'])

vis=stx_construct_calibrated_visibility(path_sci_file, time_range, energy_range, mapcenter, subc_index=subc_index, $
                                        path_bkg_file=path_bkg_file, xy_flare=xy_flare)

stop

;*************************************** SET IMAGE AND PIXEL SIZE ***********************************

; Number of pixels of the map to be reconstructed
imsize    = [129, 129]
; Pixel size in arcsec  
pixel     = [2.,2.]       

stop

;******************************************* BACKPROJECTION ********************************************************

; For using 'stx_show_bproj', create the visibility structure with the default 'subc_index' (from 10 to 3). Otherwise
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

;**************************************** CLEAN (from visibilities) *********************************************

; Number of iterations
niter  = 200
; Gain used in each clean iteration
gain   = 0.1
; The plot of the clean components and of the cleaned map is shown at every iteration
nmap   = 1      

;Output are 5 maps
;index 0: CLEAN map
;index 1: Bproj map
;index 2: residual map
;index 3: clean component map
;index 4: clean map without residuals added
beam_width = 20.
clean_map=stx_vis_clean(vis,aux_data,niter=niter,image_dim=imsize[0],PIXEL=pixel[0],uni=0,gain=0.1,nmap=nmap,$
                        /plot,/set, beam_width=beam_width)

;; Plot of visibility amplitudes and phases fit: use clean components map
stx_plot_fit_map, clean_map[3], this_window=1

stop

;;************************************************ MEM_GE *********************************************************

; Maximum entropy method (see Massa P. et al (2020) for details)
mem_ge_map=stx_mem_ge(vis,imsize,pixel,aux_data)

loadct,5,/silent
window, 0
cleanplot
plot_map, mem_ge_map, /cbar,title='MEM_GE - CLEAN contour (50%)'
plot_map,clean_map[0],/over,/perc,level=[50]

stx_plot_fit_map, mem_ge_map, this_window=1

stop

;*************************************** Expectation Maximization ************************************************

; Expectation Maximization algorithm from STIX counts (see Massa P. et al (2019) for details). Takes as input a 
; summed pixel data structure
pixel_data_summed = stx_construct_pixel_data_summed(path_sci_file, time_range, energy_range, path_bkg_file=path_bkg_file, $
                                                    xy_flare=xy_flare, /silent)

em_map = stx_em(pixel_data_summed, aux_data, imsize=imsize, pixel=pixel,$
                mapcenter=mapcenter)

loadct,5,/silent
window, 0
cleanplot
plot_map, em_map, /cbar,title='EM - CLEAN contour (50%)'
plot_map,clean_map[0],/over,/perc,level=[50]

stx_plot_fit_map, em_map, this_window=1

stop

;*************************************** VIS_FWDFIT ************************************************

configuration = 'ellipse'

; Comments:
; 1) use the 'srcin' keyword to fix the value of some of the parameters (and fit the remaining ones);
;    Please, refer to the header of the FWDFIT-PSO procedure for details.
; 2) 'srcstrout_pso' is a structure containing the values of the optimized parameters.
; 3) set /uncertainty for computing an estimate of the uncertainty on the parameters. The values of 
;    the uncertainties are stored in 'fitsigmasout_pso' 

vis_fwdfit_pso_map = stx_vis_fwdfit_pso(configuration,vis,aux_data,imsize=imsize,pixel=pixel, $
                                        srcstr = srcstrout_pso,fitsigmas=fitsigmasout_pso,/uncertainty)

loadct,5,/silent
window, 0
cleanplot
plot_map, vis_fwdfit_pso_map, /cbar,title='VIS_FWDFIT_PSO - CLEAN contour (50%)'
plot_map,clean_map[0],/over,/perc,level=[50]

stx_plot_fit_map, vis_fwdfit_pso_map, this_window=1

stop

;*********************************************** COMPARISON ******************************************************

loadct,5,/silent
window,0,xsize=5*imsize[0],ysize=5*imsize[0]
cleanplot
!p.multi=[0,2,2]
chs2=1.
plot_map,clean_map[0],charsize=chs2,title='CLEAN'
plot_map,mem_ge_map,charsize=chs2,title='MEM_GE'
plot_map,em_map,charsize=chs2,title='EM'
plot_map,vis_fwdfit_pso_map,charsize=chs2,title='VIS_FWDFIT_PSO'



end