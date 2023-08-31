;+
;
; name:
;       stx_create_auxiliary_data
;
; :description:
;    Read an auxiliary fits file an returns the values of the STIX pointing coordinates, apparent radius of the Sun, 
;    roll angle, pitch, yaw, L0 and B0 for a considered time range
;
; :params:
;    fits_path : in, required, type="string"
;                the path of the FITS file to be read. Passed through to mrdfits.
;                
;    time_range: in, required, type="string array"
;                array containing the UTC start time and end time of the considered time range      
;
; :keywords:
;    force_sas: if set, avoid check on the reliability and use SAS solution for providing an estimate of STIX pointing 
;    no_sas: if set, bypass SAS solution and use spacecraft pointing (corrected for systematics) instead
;    silent: if set, don't dieplay information regarding pointing
;
; :returns:
;
;    a structure containing the average values of the STIX pointing estimate, 
;    apparent radius of the Sun, roll angle, L0 and B0 
;    computed over a considered time range
;
; :examples:
;
;    aux_data = stx_create_auxiliary_data(fits_path, time_range)
;
; :history:
;
;    May 1, 2022: Massa P. (MIDA, Unige), created
;    2022-08-24, F. Schuller (AIP, Germany): implemented interpolation if no measurement found in time range
;    2022-09-09, FSc: added optional argument 'dont_use_sas' - renamed no_sas [2022-10-21]
;    2022-09-23, FSc: keyword 'silent' added; if not set, now displays messages about the pointing correction used
;    2022-09-28, FSc: displays a warning if dispersion in pointing > 3 arcsec
;    2023-05-25, A. F. Battaglia (FHNW, Switzerland): added a few keywords for returing header informations of the FITS file
;    2023-10-06, FSc (AIP): also allow input fits_path to be a list of (two) strings, to deal with cases where a change of day
;                           in the time range requires to read two files
;-
function stx_create_auxiliary_data, fits_path, time_range, force_sas=force_sas, no_sas=no_sas, silent=silent, $
  primary_header = primary_header, data_header = data_header, control_header= control_header, idb_version_header = idb_version_header

  default, force_sas, 0
  default, no_sas, 0
  default, silent, 0

  if keyword_set(force_sas) and keyword_set(no_sas) then $
     message, 'WARNING: keywords force_sas and no_sas both set, will not use SAS.', /info, /cont

  n_files = n_elements(fits_path)
  if n_files eq 2 then begin
    stx_read_aux_fits, fits_path[0], aux_data=aux_data_str_1, primary_header = primary_header, data_header = data_header, $
                       control_header= control_header, idb_version_header = idb_version_header
    stx_read_aux_fits, fits_path[1], aux_data=aux_data_str_2, primary_header = primary_header, data_header = data_header, $
                       control_header= control_header, idb_version_header = idb_version_header
    aux_data_str = [aux_data_str_1, aux_data_str_2]
  endif else stx_read_aux_fits, fits_path, aux_data=aux_data_str, primary_header = primary_header, data_header = data_header, $
                                control_header= control_header, idb_version_header = idb_version_header

;************** Get the indices corresponding to the considered time range
this_time_range = anytim(time_range)
time_data       = anytim(aux_data_str.TIME_UTC)
time_data      -= 32.   ; shift AUX data by half a time bin (starting time vs. bin centre)

;; CHECK: if the considered time interval is not contained in the time range of the aux_data structure, then throw an error
if this_time_range[1] lt min(time_data) or $
   this_time_range[0] gt max(time_data) then $
   message, "The aux fits file does not contain information for the considered time range."

time_ind = where((time_data ge this_time_range[0]) and (time_data le this_time_range[1]), nb_within)

; if time range is too short to contain any measurement, interpolate between nearest values
if ~nb_within then begin
  if ~silent then print, " + STX_CREATE_AUXILIARY_DATA : no measurement found, doing interpolation."
  time_middle = (this_time_range[0]+this_time_range[1])/2.
  time_diff   = time_data - time_middle
  t_near = where(abs(time_diff) eq min(abs(time_diff)))  &  t_near = t_near[0]
  if time_diff[t_near] gt 0 then begin
    t_before = t_near-1  &  t_after = t_near
  endif else begin
    t_before = t_near  &  t_after = t_near+1
  endelse

  ; Compute interpolated values for all parameters
  ; Aspect solution
  X_SAS = ((time_data[t_after]-time_middle) * aux_data_str[t_before].Y_SRF + $
           (time_middle-time_data[t_before]) * aux_data_str[t_after].Y_SRF) / $
           (time_data[t_after]-time_data[t_before])
  Y_SAS = -1.*((time_data[t_after]-time_middle) * aux_data_str[t_before].Z_SRF + $
           (time_middle-time_data[t_before]) * aux_data_str[t_after].Z_SRF) / $
           (time_data[t_after]-time_data[t_before])
  sigma_X = 0.  &  sigma_Y = 0.
  ; convert to single precision
  X_SAS = float(X_SAS)  &  Y_SAS = float(Y_SAS)
  ; SAS_OK: can the aspect solution be used? (added 2023-10-06)
  nb_sas_ok = aux_data_str[t_before].sas_ok AND aux_data_str[t_after].sas_ok

  ; Apparent solar radius (arcsec)
  RSUN = ((time_data[t_after]-time_middle) * aux_data_str[t_before].spice_disc_size + $
          (time_middle-time_data[t_before]) * aux_data_str[t_after].spice_disc_size) / $
          (time_data[t_after]-time_data[t_before])
  RSUN = float(RSUN)

  ;Roll angle (degrees)
  ROLL_ANGLE = ((time_data[t_after]-time_middle) * aux_data_str[t_before].ROLL_ANGLE_RPY[0] + $
                (time_middle-time_data[t_before]) * aux_data_str[t_after].ROLL_ANGLE_RPY[0]) / $
                (time_data[t_after]-time_data[t_before])
  ROLL_ANGLE = float(ROLL_ANGLE)

  ;Yaw (arcsec)
  YAW = ((time_data[t_after]-time_middle) * aux_data_str[t_before].ROLL_ANGLE_RPY[2] + $
         (time_middle-time_data[t_before]) * aux_data_str[t_after].ROLL_ANGLE_RPY[2]) / $
         (time_data[t_after]-time_data[t_before])
  YAW = -1.*float(YAW) * 3600.

  ;Pitch (arcsec)
  PITCH = ((time_data[t_after]-time_middle) * aux_data_str[t_before].ROLL_ANGLE_RPY[1] + $
           (time_middle-time_data[t_before]) * aux_data_str[t_after].ROLL_ANGLE_RPY[1]) / $
           (time_data[t_after]-time_data[t_before])
  PITCH = float(PITCH) * 3600.
 
  ;L0 (degrees)
  L0 = ((time_data[t_after]-time_middle) * aux_data_str[t_before].solo_loc_carrington_lonlat[0] + $
        (time_middle-time_data[t_before]) * aux_data_str[t_after].solo_loc_carrington_lonlat[0]) / $
        (time_data[t_after]-time_data[t_before])
  L0 = float(L0)

  ;B0 (degrees)
  B0 = ((time_data[t_after]-time_middle) * aux_data_str[t_before].solo_loc_carrington_lonlat[1] + $
        (time_middle-time_data[t_before]) * aux_data_str[t_after].solo_loc_carrington_lonlat[1]) / $
        (time_data[t_after]-time_data[t_before])
  B0 = float(B0)

endif else begin
  ;************* Compute the average of the values of interest over the considered time range
  ; Aspect solution: use only the data marked as "SAS_OK"
  sas_ok = where(aux_data_str[time_ind].sas_ok eq 1, nb_sas_ok)
  if nb_sas_ok lt nb_within then $
    print, nb_sas_ok, nb_within, format='(" *** WARNING - STIX Aspect solution only available for",I4," out of",I4," time stamps.")'
  if nb_sas_ok gt 0 then begin
    X_SAS = average(aux_data_str[time_ind[sas_ok]].Y_SRF)
    Y_SAS = -average(aux_data_str[time_ind[sas_ok]].Z_SRF)
    ; Also compute sigma and issue a warning if above 3 arcsec
    tolerance = 3.
    if nb_sas_ok gt 1 then sigma_X = sigma(aux_data_str[time_ind[sas_ok]].Y_SRF) else sigma_X = 0.
    if nb_sas_ok gt 1 then sigma_Y = sigma(aux_data_str[time_ind[sas_ok]].Z_SRF) else sigma_Y = 0.
    if sigma_X gt tolerance then print, sigma_X, format='(" *** WARNING - pointing unstable [rms(X) = ",F6.1," arcsec]")'
    if sigma_Y gt tolerance then print, sigma_Y, format='(" *** WARNING - pointing unstable [rms(Y) = ",F6.1," arcsec]")'
  endif else begin
    X_SAS = 0.  &  Y_sas = 0.
  endelse
  
  ; Apparent solar radius (arcsec)
  RSUN = average(aux_data_str[time_ind].spice_disc_size)
  ;Roll angle (degrees)
  ROLL_ANGLE = average(aux_data_str[time_ind].ROLL_ANGLE_RPY[0])
  ;Yaw (arcsec)
  YAW = -average(aux_data_str[time_ind].ROLL_ANGLE_RPY[2] * 3600.)
  ;Pitch (arcsec)
  PITCH = average(aux_data_str[time_ind].ROLL_ANGLE_RPY[1] * 3600.)
  ;L0 (degrees)
  L0 = average(aux_data_str[time_ind].solo_loc_carrington_lonlat[0])
  ;B0 (degrees)
  B0 =average(aux_data_str[time_ind].solo_loc_carrington_lonlat[1])
endelse


;; Rotate YAW and PITCH by roll angle (for passing from SOLO_SUN_RTN to the spacecraft reference frame)
ROT_YAW   = YAW * cos(ROLL_ANGLE * !dtor) + PITCH * sin(ROLL_ANGLE * !dtor)
ROT_PITCH = -YAW * sin(ROLL_ANGLE * !dtor) + PITCH * cos(ROLL_ANGLE * !dtor)

;************* STIX pointing estimate 
; If aspect solution is available (i.e., ~NaN) and is reliable (i.e. not much different from the spacecraft estimate) 
; use it. Otherwise, use spacecraft pointing estimate

readcol, loc_file( 'Mapcenter_correction_factors.csv', path = getenv('STX_SAS') ), $
  avg_shift_x, avg_shift_y, offset_x, offset_y, /silent

 ;;;;;;;
 ; 2023-07-27: reset (avg_shift_x, avg_shift_y) to (0,0) in order to measure it again
 ; with a larger sample of events
;;   avg_shift_x = 0.  &  avg_shift_y = 0.   ; commented out 2023-08-31

spacecraft_pointing = [avg_shift_x,avg_shift_y] + [ROT_YAW, ROT_PITCH]
STX_POINTING = spacecraft_pointing

if ~X_SAS.isnan() and ~Y_SAS.isnan() and nb_sas_ok gt 0 then begin
  if ~silent then begin
    print, " + STX_CREATE_AUXILIARY_DATA : "
    print, X_SAS, Y_SAS, format='(" --- found (Y_SRF, -Z_SRF) = ", F7.1,",",F7.1)'
    print, sigma_X, sigma_Y, format='("                 std. dev. = ", F7.1,",",F7.1)'
  endif
  
  ; Correct SAS solution for systematic error measured in 2021
  X_SAS += offset_X  &  Y_SAS += offset_Y
  sas_pointing = [X_SAS, Y_SAS]

  if ~silent then begin
    print, X_SAS, Y_SAS, format='("  ==>  STIX (SAS) pointing = ", F7.1,",",F7.1)'
    print
    print, ROT_YAW, ROT_PITCH, format='(" --- spacecraft pointing = ", F7.1,",",F7.1)'
    print, spacecraft_pointing[0], spacecraft_pointing [1], format='("  ==> s/c pointing + systematics = ", F7.1,",",F7.1)'
  endif

  diff_ptg = norm(sas_pointing - spacecraft_pointing)

  if diff_ptg lt 200. or force_sas then begin
    if not keyword_set(no_sas) then $
      STX_POINTING = sas_pointing $
    else if ~silent then print, " --- Using spacecraft pointing (and NOT SAS solution)."
  endif else if ~silent then print," --- difference greater than 200 arcsec, using spacecraft pointing."
endif else if ~silent then print," SAS solution not available, using spacecraft pointing."

if ~silent then begin
  print
  print, STX_POINTING[0], STX_POINTING[1], format='(" --- using STIX pointing = ", F7.1,",",F7.1)'
endif

aux_data = {STX_POINTING: STX_POINTING, $
            RSUN: RSUN, $
            ROLL_ANGLE: ROLL_ANGLE, $
            L0: L0, $
            B0: B0}
            

return, aux_data
            
end
