;+
; Description :
;   This procedure computes the aspect solution for each measurement given in the input data, using pre-computed
;   simulated signals stored as a data-cube in a local file.
;
; Category    : analysis
;
; Syntax      :
;   derive_aspect_solution, data
;
; Input       :
;   data      = a structure as returned by read_L1_data
;
; Keywords    :
;   None.
;
; Output      : 
;   Results are stored in attributes y_srf and z_srf of the input structure.
;
; History     :
;   2021-04-15, F. Schuller (AIP) : created
;   2021-06-17, FSc: changed from function to procedure, store results in input data structure
;   2021-07-06, FSc: renamed derive_aspect_solution to avoid conflict with previous function solve_aspect
;
;-
pro derive_aspect_solution, data
  common config   ; needed to find 'param_dir'

  ; Make sure that input data is a structure
  if not is_struct(data) then begin
    print,"ERROR: input variable is not a structure."
    return
  endif

  rsol = get_solrad(data.UTC)
  ; merged cubes - added 2021-05-12
  restore, param_dir + 'SAS_simu_2500-6000.sav'    ; covers -400 to +400 mic along X' and Y'

  nb_X = n_elements(all_X)  &  nb_Y = n_elements(all_Y)
  y_center = where(abs(all_Y) eq min(abs(all_Y)))  &  y_center = y_center[0]   ; index corresponding to closest to no-offset in orthogonal direction

  ; prepare array of results
  nb = n_elements(rsol)
  x_sas = fltarr(nb)  &  y_sas = fltarr(nb)
  
  for i=0,nb-1 do begin
    delta_r = rsol[i] - all_r
    tmp = where(abs(delta_r) eq min(abs(delta_r)))
    ind_r = tmp[0]   ; indice of the plane where rsol is the closest to the input value

    inputA_B = (data.signal[0,i]- data.signal[1,i])*1.e9
    inputC_D = (data.signal[2,i]- data.signal[3,i])*1.e9

    ; 1st: look for optimal offset along A-B assuming no offset along C-D      
    d_sigAB = inputA_B - sigA_sigB[*,y_center,ind_r]
    tmpAB = where(abs(d_sigAB) eq min(abs(d_sigAB)))  &  tmpAB = tmpAB[0]
    x_AB_tmp = all_X[tmpAB]

    ; 2nd: use this 1st estimate to find the optimal offset along C-D
    dif_Y = all_Y - x_AB_tmp
    ind_Y = where(abs(dif_Y) eq min(abs(dif_Y)))  &  ind_Y = ind_Y[0]
    d_sigCD = inputC_D - sigC_sigD[*,ind_Y,ind_r]
    tmpCD = where(abs(d_sigCD) eq min(abs(d_sigCD)))  &  tmpCD = tmpCD[0]
    x_CD_tmp = all_X[tmpCD]

    ; 3rd: refine solution along A-B using the found x_CD
    dif_Y = all_Y - x_CD_tmp
    ind_Y = where(abs(dif_Y) eq min(abs(dif_Y)))  &  ind_Y = ind_Y[0]
    d_sigAB = inputA_B - sigA_sigB[*,ind_Y,ind_r]
    tmpAB = where(abs(d_sigAB) eq min(abs(d_sigAB)))  &  tmpAB = tmpAB[0]
    x_AB = all_X[tmpAB]

    ; 4th: finally refine solution along C-D using final solution along A-B
    if x_AB ne X_AB_tmp then begin
      dif_Y = all_Y - x_AB
      ind_Y = where(abs(dif_Y) eq min(abs(dif_Y)))  &  ind_Y = ind_Y[0]
      d_sigCD = inputC_D - sigC_sigD[*,ind_Y,ind_r]
      tmpCD = where(abs(d_sigCD) eq min(abs(d_sigCD)))  &  tmpCD = tmpCD[0]
      x_CD = all_X[tmpCD]
    endif else x_CD = x_CD_tmp
    
    ; convert to SAS frame
    x_sas[i] = (x_AB - x_CD) / sqrt(2.) * 1.e-6
    y_sas[i] = (x_AB + x_CD) / sqrt(2.) * 1.e-6
  endfor
  
  ; Store results as arcsec in SRF in the data structure
  data.y_srf = y_sas * 0.375e6
  data.z_srf = x_sas * 0.375e6
  
end
