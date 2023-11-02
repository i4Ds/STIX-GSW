;+
; Description :
;   This procedure computes the aspect solution for each measurement given in the input data, using pre-computed
;   simulated signals stored as a data-cube in a local file.
;
; Category    : analysis
;
; Syntax      :
;   stx_derive_aspect_solution, data
;
; Input       :
;   data      = a structure as returned by read_L1_data
;   simu_data_file = name of the file with simulated data, including full absolute path
;
; Keywords    :
;   interpol_r  = if set, results are computed for the two nearest values of r_sol, and the weighted average
;                 (R2-r)/(R2-R1) * (X1,Y1) + (r-R1)/(R2-R1) * (X2,Y2) is returned.
;   interpol_xy = if set, interpolate results along each axis of the X'Y' grid
;
; Output      : 
;   Results are stored in attributes y_srf and z_srf of the input structure.
;
; History     :
;   2021-04-15, F. Schuller (AIP) : created
;   2021-06-17, FSc: changed from function to procedure, store results in input data structure
;   2021-07-06, FSc: renamed derive_aspect_solution to avoid conflict with previous function solve_aspect
;   2021-11-15 - FSc: removed common block "config", pass full path to file with simulated data as input
;   2022-01-18, FSc: added optional arguments 'interpol_r' and 'interpol_xy'; major rewriting
;   2022-01-28, FSc (AIP) : adapted to STX_ASPECT_DTO structure
;   2022-04-22, FSc (AIP) : changed name from "derive_aspect_solution" to "stx_derive_aspect_solution"
;   2023-09-19, FSc (AIP) : implemented more error messages
;-

function solve_aspect_one_plane, inputA_B, inputC_D, plane_AB, plane_CD, all_X, all_Y, max_iter=max_iter, delta_conv=delta_conv, interpol_xy=interpol_xy
  ; find aspect solution in a X',Y' plane, for a fixed value of solar radius
  ;
  default, max_iter, 10      ; stop after iterations...
  default, delta_conv, 10.   ; or if successive solutions don't differ by more than 10 mic

  ; Store number of elements along main direction in simulated data
  nb_X = n_elements(all_X)
  
  ; Test: if inputA_B or inputC_D is not within the range covered by simulated data,
  ; then we cannot derive any solution: set results to NaN
  if inputA_B lt min(plane_AB) or inputC_D lt min(plane_CD) or $
    inputA_B gt max(plane_AB) or inputC_D gt max(plane_CD) then begin
    x_AB = float('NaN')
    x_CD = float('NaN')
  endif else begin
    ; 1st: look for optimal offset along A-B assuming no offset along C-D
    y_center = where(abs(all_Y) eq min(abs(all_Y)))  &  y_center = y_center[0]   ; or closest to no-offset
    d_sigAB = inputA_B - plane_AB[*,y_center]
    tmpAB = where(abs(d_sigAB) eq min(abs(d_sigAB)))  &  tmpAB = tmpAB[0]
    x_AB = all_X[tmpAB]

    ; 2nd: use this 1st estimate to find the optimal offset along C-D
    dif_Y = all_Y - x_AB
    ind_Y_CD = where(abs(dif_Y) eq min(abs(dif_Y)))  &  ind_Y_CD = ind_Y_CD[0]
    d_sigCD = inputC_D - plane_CD[*,ind_Y_CD]
    tmpCD = where(abs(d_sigCD) eq min(abs(d_sigCD)))  &  tmpCD = tmpCD[0]
    x_CD = all_X[tmpCD]

    ; Iterate until convergence or max. number of iterations
    do_more = 1  &  n_iter=0
    while do_more do begin
      x_AB_prev = x_AB
      x_CD_prev = x_CD
      ; refine solution along A-B using the found x_CD
      dif_Y = all_Y - x_CD
      ind_Y_AB = where(abs(dif_Y) eq min(abs(dif_Y)))  &  ind_Y_AB = ind_Y_AB[0]
      d_sigAB = inputA_B - plane_AB[*,ind_Y_AB]
      tmpAB = where(abs(d_sigAB) eq min(abs(d_sigAB)))  &  tmpAB = tmpAB[0]
      x_AB = all_X[tmpAB]

      ; and refine solution along C-D using new solution along A-B
      if x_AB ne X_AB_prev then begin
        dif_Y = all_Y - x_AB
        ind_Y_CD = where(abs(dif_Y) eq min(abs(dif_Y)))  &  ind_Y_CD = ind_Y_CD[0]
        d_sigCD = inputC_D - plane_CD[*,ind_Y_CD]
        tmpCD = where(abs(d_sigCD) eq min(abs(d_sigCD)))  &  tmpCD = tmpCD[0]
        x_CD = all_X[tmpCD]
      endif else x_CD = x_CD_prev
      sol_diff = sqrt((x_AB-x_AB_prev)^2 + (x_CD-x_CD_prev)^2)
      n_iter += 1
      if n_iter ge max_iter or sol_diff lt delta_conv then do_more = 0
    endwhile

    if keyword_set(interpol_XY) then $
      ; refine solution by interpolating between two nearest points on the grid,
      ; but only if not on the edge of the parameter space:
      if tmpAB gt 0 and tmpAB lt nb_X-1 and tmpCD gt 0 and tmpCD lt nb_X-1 then begin
        delta_AB = inputA_B - plane_AB[tmpAB,ind_Y_AB]
        ; At least near Sun centre, plane_AB[*,ind_Y] is monotonically increasing, 
        ; therefore delta_AB is decreasing. Thus:
        if delta_AB lt 0 then begin
          ind_AB_pos = tmpAB-1  &  ind_AB_neg = tmpAB
        endif else begin
          ind_AB_pos = tmpAB  &  ind_AB_neg = tmpAB+1
        endelse
        delta_pos = inputA_B - plane_AB[ind_AB_pos,ind_Y_AB]
        delta_neg = plane_AB[ind_AB_neg,ind_Y_AB] - inputA_B
        x_AB = delta_pos / (delta_pos+delta_neg) * all_X[ind_AB_neg] + delta_neg / (delta_pos+delta_neg) * all_X[ind_AB_pos]

        ; Same game for x_CD
        delta_CD = inputC_D - plane_CD[tmpCD,ind_Y_CD]
        if delta_CD lt 0 then begin
          ind_CD_pos = tmpCD-1  &  ind_CD_neg = tmpCD
        endif else begin
          ind_CD_pos = tmpCD  &  ind_CD_neg = tmpCD+1
        endelse
        delta_pos = inputC_D - plane_CD[ind_CD_pos,ind_Y_CD]
        delta_neg = plane_CD[ind_CD_neg,ind_Y_CD] - inputC_D
        x_CD = delta_pos / (delta_pos+delta_neg) * all_X[ind_CD_neg] + delta_neg / (delta_pos+delta_neg) * all_X[ind_CD_pos]
      endif
  endelse

  result = {x_AB:x_AB, x_CD:x_CD}
  return,result
end

pro stx_derive_aspect_solution, data, simu_data_file, interpol_r=interpol_r, interpol_xy=interpol_xy
  default, interpol_r, 1
  default, interpol_xy, 1
  
  if n_params() lt 2 then message," SYNTAX: derive_aspect_solution, data, simu_data_file"

  ; Make sure that input data is a structure
  if not is_struct(data) then message, " ERROR: input variable is not a structure."

  ; Also check for existence of simu_data_file
  if strmid(simu_data_file,strlen(simu_data_file)-4,4) ne '.sav' then simu_data_file += '.sav'
  result = file_test(simu_data_file)
  if not result then message," ERROR: File "+simu_data_file+" not found."
  restore, simu_data_file
  rsol_maxi = all_r[-1]

  ; prepare array of results
  foclen = 0.55         ; SAS focal length, in [m]
  ; replace nominal focal length with actual distance from lens to aperture plate (= image plane)
  ; (changed 2023-04-21)
  foclen = 548.16e-3
  rsol = foclen * (data.SPICE_DISC_SIZE * !pi/180. / 3600.)
  nb = n_elements(rsol)
  x_sas = fltarr(nb)  &  y_sas = fltarr(nb)
  
  rsol_mini = 3.28e-3  ; corresponds to 0.75 AU
  for i=0,nb-1 do begin
    ; Test if rsol is less than the mininum value to get usable signals...
    if rsol[i] lt rsol_mini then data[i].ERROR = 'SUN_TOO_FAR'
    ; ... or above the max radius covered by the simu. data
    if rsol[i] gt rsol_maxi then data[i].ERROR = 'SUN_TOO_CLOSE'
    ; also catch error messages previously set:
    if data[i].ERROR eq '' then begin
      delta_r = rsol[i] - all_r
      tmp = where(abs(delta_r) eq min(abs(delta_r)))
      ind_r = tmp[0]   ; index of the plane where rsol is the closest to the input value

      inputA_B = (data[i].CHA_DIODE0 - data[i].CHA_DIODE1)*1.e9
      inputC_D = (data[i].CHB_DIODE0 - data[i].CHB_DIODE1)*1.e9

      if keyword_set(interpol_r) then begin
        ; find the 2nd closest r_sol
        if rsol[i]-all_r[ind_r] lt 0. then begin
          ind_r1 = ind_r -1  &  ind_r2 = ind_r
        endif else begin
          ind_r1 = ind_r  &  ind_r2 = ind_r +1
        endelse
        plane_AB1 = reform(sigA_sigB[*,*,ind_r1])
        plane_CD1 = reform(sigC_sigD[*,*,ind_r1])
        res_AB_CD_1 = solve_aspect_one_plane(inputA_B, inputC_D, plane_AB1, plane_CD1, all_X, all_Y, interpol_xy=interpol_xy)
        x_AB1 = res_AB_CD_1.x_AB  &  x_CD1 = res_AB_CD_1.x_CD
        plane_AB2 = reform(sigA_sigB[*,*,ind_r2])
        plane_CD2 = reform(sigC_sigD[*,*,ind_r2])
        res_AB_CD_2 = solve_aspect_one_plane(inputA_B, inputC_D, plane_AB2, plane_CD2, all_X, all_Y, interpol_xy=interpol_xy)
        x_AB2 = res_AB_CD_2.x_AB  &  x_CD2 = res_AB_CD_2.x_CD
        x_AB = ((all_r[ind_r2]-rsol[i]) * x_AB1 + (rsol[i]-all_r[ind_r1]) * x_AB2) / (all_r[ind_r2]-all_r[ind_r1])
        x_CD = ((all_r[ind_r2]-rsol[i]) * x_CD1 + (rsol[i]-all_r[ind_r1]) * x_CD2) / (all_r[ind_r2]-all_r[ind_r1])
      endif else begin
        plane_AB = reform(sigA_sigB[*,*,ind_r])
        plane_CD = reform(sigC_sigD[*,*,ind_r])
        res_AB_CD = solve_aspect_one_plane(inputA_B, inputC_D, plane_AB, plane_CD, all_X, all_Y, interpol_xy=interpol_xy)
        x_AB = res_AB_CD.x_AB  &  x_CD = res_AB_CD.x_CD
      endelse

      ; convert to SAS frame
      x_sas[i] = -1.*(x_AB - x_CD) / sqrt(2.) * 1.e-6
      y_sas[i] = -1.*(x_AB + x_CD) / sqrt(2.) * 1.e-6
      
      ; Test whether the solution can be used:
      if (~finite(x_AB) or ~finite(x_CD)) then data[i].ERROR = 'NO_SOLUTION' $
        else begin
          ; also not good if too far off the solar limb:
          dist_center = norm([x_AB,x_CD]) * 1.e-6
          if dist_center gt 1.1 * rsol[i] then data[i].ERROR = 'OFFPOINT_TOO_LARGE'
        endelse
    endif
    ; Flag data with sas_ok=0 in case of any error
    if data[i].ERROR eq '' then data[i].sas_ok = 1 else data[i].sas_ok = 0
  endfor
  
  ; Store results as arcsec in SRF in the data structure
  linear_to_asec = (1./foclen) * 180./!pi * 3600.  ; conversion factor from m to arcsec
  data.y_srf = y_sas * linear_to_asec
  data.z_srf = x_sas * linear_to_asec
  
end
