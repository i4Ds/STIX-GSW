;+
;
; NAME:
;
;   stx_spectral_component_imaging
;
; PURPOSE:
;   
;   Calculates the visibilites of the spectral components using energy dependent visibilites and spectral fitting 
;
; CALLING SEQUENCE:
;
;
;   
;   vis = stx_spectral_component_imaging(path_sci_file, path_bkg_file, mapcenter, time_range, energy_ranges, F_tot, frac)
;
; INPUTS:
; 
;   path_sci_file:    path to the STIX science file
;
;   path_bkg_file:    path to the STIX background file
;   
;   mapcenter:        center around which visibilites are determined
;
;   time_range:       time range to calculate the visibilites
;
;   energy_ranges:    energy ranges to consider
;   
;   F_tot:            total flux in each energy bin (counts/s/cm2/keV)
;   
;   frac:             fractional contribution of each component to the total spectrum for each energy bin
;
; KEYWORDS:
;
;   sumcase:           which pixels to use, default TOP+BOT
;   
;   subc_index:        which detectors to use, default TOP24
;   
;   chi2_vis:          estimated chi2 of the linear system, output
;   
;   chi2_e_channel:    estimated chi2 of linear system for each energy channel, output
;  
;   vis_array:         array with the visibilities for each energy channel, output 
;   
;   sigamp_array:      array with the sigma on amplitudes of visibilites per energy channel, output
;
; OUTPUTS:
; 
;   vis_components:    visibilities of the spectral components
;   
;
; HISTORY:  August 2025, Muriel Stiefel, created 
;           Ocotber 2025, Muriel Stiefel, updated
;
; CONTACT:
;   muriel.stiefel@fhnw.ch
;-

function stx_spectral_component_imaging, path_sci_file, path_bkg_file, mapcenter, time_range, energy_ranges, F_tot, frac, $
  sumcase=sumcase, subc_index=subc_index,$
  chi2_vis=chi2_vis, chi2_e_channel=chi2_e_channel, vis_array=vis_array, sigamp_array=sigamp_array
  
  ; default values
  default, sumcase, 'TOP + BOT'
  default, subc_index, stx_label2ind(['10a','10b','10c','9a','9b','9c','8a','8b','8c','7a','7b','7c',$
    '6a','6b','6c','5a','5b','5c','4a','4b','4c','3a','3b','3c'])
    
  num_energy = n_elements(F_tot) ; number of energy ranges/energy dependent visibilities
  n_free_vis = n_elements(subc_index) ; number of visibilities
  xy_flare = mapcenter
  
  ; Loop through the energy ranges to get the energy dependent visibilites
  vis_array = []
  sigamp_array = []
  for i=0,num_energy-1 do begin
    vis = stx_construct_calibrated_visibility(path_sci_file, time_range, energy_ranges[*,i], mapcenter, subc_index=subc_index, $
          path_bkg_file=path_bkg_file, xy_flare=xy_flare, sumcase=sumcase)
    
    vis_array = [[vis_array], [vis.obsvis/(F_tot[i])]]
    sigamp_array = [[sigamp_array], [vis.sigamp/(F_tot[i])]] 

  endfor
  
  
  ; prepare for solving linear system
  num_elem = n_elements(frac)/num_energy
  dvis_array = vis_array[*,0:(num_elem-1)]
  dsigamp_array = sigamp_array[*,0:(num_elem-1)]
  sig_dvis_array = COMPLEXARR(24,num_elem,num_elem)
  
  ; Solve the linear least square problem to get the spectral component visibilites
  trans_frac = transpose(frac)

  for i=0,23 do begin
    ; Construct the covariant matrix
    V_inv = COMPLEXARR(num_energy,num_energy)
    V = COMPLEXARR(num_energy,num_energy)
    for j=0,num_energy-1 do V_inv[j,j] = complex((1./sigamp_array[i,j]^2),(1./sigamp_array[i,j]^2))
    for j=0,num_energy-1 do V[j,j] = complex(sigamp_array[i,j]^2,sigamp_array[i,j]^2)
    
    ; Linear least square method on the visibilites
    A = complex(invert(trans_frac ## real_part(V_inv) ## frac) ## trans_frac ## real_part(V_inv), $
      invert(trans_frac ## IMAGINARY(V_inv) ## frac) ## trans_frac ## IMAGINARY(V_inv))
    dvis_array[i,*] = complex(real_part(A) ## real_part(vis_array[i,*]), $
      IMAGINARY(A) ## IMAGINARY(vis_array[i,*]))
      
    ; Error propagation of the visibilities
    sig_dvis_array[i,*,*] = complex(real_part(A) ## real_part(V) ## transpose(real_part(A)), $
      IMAGINARY(A) ## IMAGINARY(V) ## transpose(IMAGINARY(A)))
    
    ; Calculate amplitude sigma for the visibilities 
    for j = 0,num_elem-1 do begin
      vis_real = real_part(dvis_array[i,j])
      vis_im = IMAGINARY(dvis_array[i,j])
      vis_real_sig = real_part(sig_dvis_array[i,j,j]) ; is squared!
      vis_im_sig = IMAGINARY(sig_dvis_array[i,j,j])
      dsigamp_array[i,j] = sqrt((vis_real^2/(vis_real^2+vis_im^2)) * vis_real_sig + (vis_im^2/(vis_real^2+vis_im^2))*vis_im_sig)
    endfor
    
  endfor
  
  ; Calculate the chi2 on the linear system solution
  pred_vis = frac ## dvis_array ; predicted energy dependent visibilities
  chi2_vis = (total(abs(real_part(vis_array) - real_part(pred_vis))^2./(sigamp_array^2.)) + $
    total(abs(imaginary(vis_array) - imaginary(pred_vis))^2./(sigamp_array^2.))) /(n_free_vis*num_energy-1)
  
  chi2_e_channel = fltarr(num_energy)
  for i=0,num_energy-1 do begin
    chi2_e_channel[i] = (total(abs(real_part(vis_array[*,i]) - real_part(pred_vis[*,i]))^2./(sigamp_array[*,i]^2.)) + $
      total(abs(real_part(vis_array[*,i]) - real_part(pred_vis[*,i]))^2./(sigamp_array[*,i]^2.))) /(n_free_vis-1)
  endfor
  
  ; Prepare visibility structure for the spectral component visibiliites
  vis_structure = stx_construct_calibrated_visibility(path_sci_file, time_range, energy_ranges[*,0], mapcenter, subc_index=subc_index, $
  path_bkg_file=path_bkg_file, xy_flare=xy_flare, sumcase=sumcase)
  vis_components = []
  
  for i = 0,num_elem-1 do begin
    vis_comp = vis_structure
    
    vis_comp.type = 'stx_visibility comp ' + string(i+1)
    vis_comp.obsvis = dvis_array[*,i]
    vis_comp.sigamp = dsigamp_array[*,i]
    vis_comp.TOTFLUX = max(abs(vis_comp.obsvis))
    
    vis_components = [[vis_components], [vis_comp]]
    
  endfor
  
  return, vis_components

end