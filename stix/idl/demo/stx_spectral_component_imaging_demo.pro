;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_spectral_component_imaging_demo
;
; :description:
;    This demonstration script shows how to use the routine stx_spectral_component_imaging. Spectral component imaging is a method of imaging individual 
;    spectral components rather than imaging in energy ranges. The routine is based on the paper: "Spectral component imaging of solar X-ray flares", Stiefel et al. (2025)
;
; :categories:
;    demo, imaging
;
; :history:
;   March-2026, Stiefel, M; first release
;-

; *******************************************
; ************ PREPARE THE DATA *************
; *******************************************

;;******************************** LOAD DATA - Mai 16 2023, 17:20 UT ********************************

; Folder in which the files downloaded for this demonstration are stored
default, out_dir, concat_dir( getenv('STX_DEMO_DATA'),'component_imaging', /d)

; UID of the science fits file to be dowloaded from the website
uid_sci_file = '2305162947'
path_sci_file = stx_get_science_fits_file(uid_sci_file, out_dir=out_dir)

; UID of the background fits file to be dowloaded from the website
uid_bkg_file = '2305176702'
path_bkg_file = stx_get_science_fits_file(uid_bkg_file, out_dir=out_dir)

;;*********************************** SET TIME AND ENERGY RANGES ***********************************

; Time range to be selected for image reconstruction
time_range    = ['16-May-2023 17:20:50','16-May-2023 17:21:10']
; Set energy ranges that should be used for component imaging
energy_ranges = [[7,8],$
  [8,9],$
  [9,10],$
  [10,11],$
  [11,12],$
  [12,13],$
  [13,14],$
  [14,15],$
  [15,16],$
  [16,18],$
  [18,20],$
  [20,22],$
  [22,25],$
  [25,28],$
  [28,32],$
  [32,36],$
  [36,40],$
  [40,45],$
  [45,50]]

;********************************* DOWNLOAD L2 EPHEMERIS FITS FILE ***********************************
; see imaging demo for more details

aux_fits_file = stx_get_ephemeris_file(time_range[0], time_range[1], out_dir=out_dir)
aux_data = stx_create_auxiliary_data(aux_fits_file, time_range)


;********************************* GET FLARE LOCATION ***********************************
stx_estimate_flare_location, path_sci_file, time_range, aux_data, flare_loc=flare_loc, $
  path_bkg_file=path_bkg_file
mapcenter = stx_hpc2stx_coord(flare_loc, aux_data)
xy_flare  = mapcenter

; Angle between Solar Orbiter - Flare to flare normal
angle_sfn = 36.

; Get the SO-Sun distance and the difference in the light travel time
stx_get_header_corrections, path_sci_file, distance = distance, time_shift = time_shift

stop


; *******************************************
; ************ SPECTRAL FITTING *************
; *******************************************

; remove ";" below for fitting
; for the DEMO, the OSPEX fitting outputs are already saved in "Ospex_Output.sav" in the folder

;; Call OSPEX for fitting
;stx_convert_pixel_data, $
;    fits_path_data = path_sci_file,$
;    fits_path_bk = path_bkg_file, $
;    distance = distance, $
;    time_shift = time_shift, $
;    flare_location_stx = xy_flare, $
;    background_data = background_data, $
;    ospex_obj = ospex_obj
;
;ospex_obj->set, spex_source_angle = angle_sfn
;ospex_obj->set, spex_fit_time_interval=anytim(['16-May-2023 17:20:48','16-May-2023 17:20:56'])+time_shift
;ospex_obj->set, fit_function='vth+thick2+albedo' ; careful: order of models does matter for later! If different order, code needs to be adapted below

stop

; save the OSPEX output files
;param_ospex = ospex_obj-> get(/spex_summ)
;spectrum_fits = ospex_obj-> calc_func_components(spex_unit='rate')
;save,param_ospex,spectrum_fits,filename=out_dir+'\Ospex_Output.sav'

stop
; *******************************************
; *******************************************
; ****** Export spectral parameters *********
; *******************************************
; *******************************************

; Here we used two models (thermal and nonthermal) and an albedo component
; In case more models or no albedo component were used, the code needs to be adapted accordingly
restore, out_dir + "\Ospex_Output.sav"

; Read out spectrum parameters from OSPEX
e_axis_ospex = average(param_ospex.spex_summ_energy,1)
e_bin_width = param_ospex.spex_summ_energy[1,*]-param_ospex.spex_summ_energy[0,*]
stix_spectrum = param_ospex.SPEX_SUMM_CT_RATE/e_bin_width 

; Read out fitting models from OSPEX
; Total fit
total_fit = spectrum_fits.yvals[*,0]/e_bin_width

; Single models (s-1 keV-1) ****** ADAPT IF DIFFERENT MODELS USED ******
model_1 = spectrum_fits.yvals[*,1]/e_bin_width ; here: thermal
model_2 = spectrum_fits.yvals[*,2]/e_bin_width ; here: nonthermal
albedo_fit = spectrum_fits.yvals[*,3]/e_bin_width ; here: albedo

; prepare matrices for spectral component imaging
wanted_e_ranges = mean(energy_ranges,dimension=1)
F_tot = fltarr(n_elements(wanted_e_ranges))
frac = fltarr(2,n_elements(wanted_e_ranges)) ; 2: number of models, ****** ADAPT, IF MORE THAN 2 ******
for i=0,(n_elements(wanted_e_ranges)-1) do begin
  ind = where(e_axis_ospex EQ wanted_e_ranges[i])
  ind = ind[0]
  
  F_tot[i] = stix_spectrum[ind]
  frac[0,i] = model_1[ind]/(total_fit[ind]-albedo_fit[ind])
  frac[1,i] = model_2[ind]/(total_fit[ind]-albedo_fit[ind])
endfor
cm_value = 0.096*8*24*0.25 ;(not very nice correction for area)
F_tot = F_tot/cm_value

stop

; *******************************************
; ***** RUN SPECTRAL COMPONENT IMAGING ******
; *******************************************

; define subcollimators
subc_index = stx_label2ind(['10a','10b','10c','9a','9b','9c','8a','8b','8c','7a','7b','7c',$
  '6a','6b','6c','5a','5b','5c','4a','4b','4c','3a','3b','3c'])

; run the spectral component imaging routine
; Output: visibilities for the spectral components, here: thermal + nonthermal
vis_result = stx_spectral_component_imaging(path_sci_file, path_bkg_file, mapcenter, time_range, energy_ranges, F_tot, frac, $
    sumcase='TOP+BOT', chi2_vis=chi2_vis, chi2_e_channel=chi2_e_channel, vis_array=vis_array, sigamp_array=sigamp_array)

vis_A = vis_result[*,0]
vis_B = vis_result[*,1]

stop

; *******************************************
; ********** IMAGING AND PLOTTING ***********
; *******************************************

;Image size
imsize    = [251,251] ;[251,251] [129,129]
pixel     = [2.,2.]*0.5

; Reconstruct images
mem_ge_map_A=stx_mem_ge(vis_A,imsize,pixel,aux_data) 
mem_ge_map_B=stx_mem_ge(vis_B,imsize,pixel,aux_data) 

stx_plot_fit_map, mem_ge_map_A, this_window=10
stx_plot_fit_map, mem_ge_map_B, this_window=11

; comparison: reconstruct energy dependent images
vis_E1=stx_construct_calibrated_visibility(path_sci_file, time_range, [7,10], mapcenter, subc_index=subc_index, $
  path_bkg_file=path_bkg_file, xy_flare=xy_flare, sumcase="TOP+BOT")
vis_E2=stx_construct_calibrated_visibility(path_sci_file, time_range, [22,28], mapcenter, subc_index=subc_index, $
  path_bkg_file=path_bkg_file, xy_flare=xy_flare, sumcase="TOP+BOT")

mem_ge_map_E1=stx_mem_ge(vis_E1,imsize,pixel,aux_data)
mem_ge_map_E2=stx_mem_ge(vis_E2,imsize,pixel,aux_data)

; Plotting

levels=[20,40,60,80,90]
window,1,xsize=800,ysize=500
!P.MULTI=[0,2,1]
loadct,0
plot_map,mem_ge_map_A, title='Using Spectroscopic Imaging'
plot_map,mem_ge_map_A,/over,/per,levels=levels,c_thick=2.0
loadct,2
plot_map,mem_ge_map_B,/over,/per,levels=levels,color=100,c_thick=2.0

loadct,0
plot_map,mem_ge_map_E1, title='Using Energy Ranges'
plot_map,mem_ge_map_E1,/over,/per,levels=levels,c_thick=2.0
loadct,2
plot_map,mem_ge_map_E2,/over,/per,levels=levels,color=100,c_thick=2.0

end