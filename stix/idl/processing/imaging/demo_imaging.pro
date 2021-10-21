;************************************************************************************************************************************************;
;                                                                                                                                                ;
;                                                        STIX IMAGING SOFTWARE DEMO                                                              ;
;                                                                                                                                                ;
;************************************************************************************************************************************************;

;;;;;;;;;;;; COMMENTS:
;
; 1- The absolute location of the reconstructed images is the row one inferred just from visibilities. No corrections for aspect solution is applied
; 2- The field RSUN of the reconstructed maps (containing the value of the solar radius in arcsec as seen from Solar Orbiter) has to be manually set
;    by the user. Authomatic ways to do that will be implemented in the next future
; 3- The reconstructed maps are conceived in the heliocentric coordinate system (north up)

;;;;;;;;;;;;


data_folder = getenv('SSW_STIX') + '/idl/processing/imaging/data/'

;;;;;;;;;;;; LOAD DATA

;;;;; June 7 2021 - 21:41

path_sci_file = data_folder + 'solo_L1_stix-sci-xray-l1-1178428688_20200607T213708-20200607T215208_V01.fits' ; Path of the science L1 fits file
path_bkg_file = data_folder + 'solo_L1_stix-sci-xray-l1-1178451984_20200607T225959-20200607T235900_V01.fits' ; Path of the background L1 fits file
time_range = ['7-Jun-2020 21:39:00', '7-Jun-2020 21:42:49'] ; Time range to consider
energy_range = [6,10]       ; Energy range to consider (keV)
xy_flare = [-1600., -800.]  ; CFL solution (heliocentric, north up). Needed for the visibility phase calibration
mapcenter = [-1650., -750.] ; Coordinates of the center of the map to reconstruct (heliocentric, north up)

;;;;;;;;;; CONSTRUCT VISIBILITY STRUCTURE

; Compute the array of detector indices (from 0 to 31) from the corresponding labels.
; Used for selecting the detectors to consider for making the images
;subc_index = stix_label2ind(['10a','10b','10c','9a','9b','9c','8a','8b','8c','7a','7b','7c',$
;                             '6a','6b','6c','5a','5b','5c','4a','4b','4c','3a','3b','3c'])

; Create the visibility structure filled with the measured data
vis=stix2vis_sep2021(path_sci_file, path_bkg_file, time_range, energy_range, mapcenter, $
                     subc_index=subc_index, xy_flare=xy_flare, pixels=pixels)
; in 'stix2vis_sep2021':
; - avoid the plots by setting the keyword /silent
; - select the detector pixels (to use for computing the visibilities) by setting the keyword 'pixels' equal to 
;   'TOP', 'BOT' or 'TOP+BOT' (top row pixels, bottom row pixels, or top+bottom pixels, respectively).
;   Default is 'TOP+BOT'

print, " "
print, "Press SPACE to continue"
print, " "
pause


;;;;;;;;;; SET PARAMETERS FOR IMAGING

imsize    = [129, 129]    ; number of pixels of the map to recinstruct
pixel     = [2.,2.]       ; pixel size in arcsec

;******************************************* BACKPROJECTION ********************************************************

; For using 'stix_show_bproj' create the visibility structure with the default 'subc_index' (from 10 to 3). Otherwise
; it throws an error
stix_show_bproj,vis,imsize=imsize,pixel=pixel,out=bp_map,scaled_out=scaled_out
;
; - Window 0: each row corresponds to a different resolution (from top to bottom, label 10 to 3). The first three 
;             columns refer to label 'a', 'b' and 'c'; the last column is the  sum of the first three.
; - Window 2: Natural weighting (first row) and uniform weighting (second row). From left to right, backprojection
;             obtained starting from subcollimators 10 and subsequently adding subcollimators with finer resolution


; BACKPROJECTION natural weighting
bp_nat_map = bproj_stix_sep2021(vis,imsize,pixel)

; BACKPROJECTION uniform weighting
bp_uni_map = bproj_stix_sep2021(vis,imsize,pixel,/uni)

print, " "
print, "Press SPACE to continue"
print, " "
pause


;**************************************** CLEAN (from visibilities) **********************************************

niter  = 200    ;number of iterations
gain   = 0.1    ;gain used in each clean iteration
beam   = 10.  ;FWHM of CLEAN beam
nmap   = 20   ;only every 20th integration is shown in plot

;Output are 5 maps
;index 0: CLEAN map
;index 1: Bproj map
;index 2: residual map
;index 3: clean component map
;index 4: clean map without residuals added

clean_map=clean_stix_sep2021(vis,niter=niter,image_dim=imsize[0],PIXEL=pixel[0],uni=0,gain=0.1,$
                             beam_width=beam,nmap=nmap,/plot,/set)

print, " "
print, "Press SPACE to continue"
print, " "
pause


;;************************************************ MEM_GE *********************************************************

; Maximum entropy method (see Massa P. et al 2020 for details)
mem_ge_map=mem_ge_stix_sep2021(vis,imsize,pixel)

window, 0
cleanplot
plot_map, mem_ge_map, /cbar,title='MEM_GE - CLEAN contour (50%)'
plot_map,clean_map[0],/over,/perc,level=[50]


print, " "
print, "Press SPACE to continue"
print, " "
pause


;*************************************** Expectation Maximization ************************************************

; EM is a count-based method, therefore it starts from the countrates recorded by the detector pixels
data = stix_compute_vis_amp_phase(path_sci_file,path_bkg_file,anytim(time_range),energy_range, xy_flare=xy_flare, /silent)
em_map = em_stix_sep2021(data.RATE_PIXEL,energy_range,time_range,IMSIZE=imsize,PIXEL=pixel,$
                         MAPCENTER=mapcenter,xy_flare=xy_flare, WHICH_PIX=pixels)

loadct, 5
window, 0
cleanplot
plot_map, em_map, /cbar,title='EM - CLEAN contour (50%)'
plot_map,clean_map[0],/over,/perc,level=[50]

print, " "
print, "Press SPACE to continue"
print, " "
pause


;*********************************************** COMPARISON ******************************************************

window,0,xsize=5*imsize[0],ysize=5*imsize[0]
cleanplot
!p.multi=[0,2,2]
chs2=1.
plot_map,bp_nat_map,charsize=chs2,title='BPROJ NAT. WEIGHTING'
plot_map,clean_map[0],charsize=chs2,title='CLEAN'
plot_map,mem_ge_map,charsize=chs2,title='MEM_GE'
plot_map,em_map,charsize=chs2,title='EM'



end