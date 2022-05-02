;+
;
; name:
;       stx_read_aux_fits
;
; :description:
;    Read the values contained in an auxiliary fits files
;
;
; :categories:
;    fits, io
;
; :params:
;    fits_path : in, required, type="string"
;                the path of the FITS file to be read. Passed through to mrdfits.
;   
;    time_in: in, required, type="string"
;             time for which the values (aspect solution, apparent radius of the Sun, spacecraft roll angle , L0, B0) are reurned
;
;
; :keywords:
;
;    primary_header : out, type="string array"
;               an output float value;
;
;    data_header : out, type="string array"
;              The header of the data extension of the auxiliary file
;
;    data_str : out, type="structure"
;              The contents of the data extension of the auxiliary file
;
;    control_header : out, type="string array"
;                The header of the control extension of the auxiliary file
;
;    control_str : out, type="structure"
;               The contents of the control extension of the auxiliary file
;               
;    idb_version_header : out, type="string array"
;               The header of the idb version extension of the auxiliary file
;               
;    idb_version_str : out, type="structure"
;               The contents of the idb version extension of the auxiliary file
;
; :returns:
;
;    a structure containing the values of aspect solution, apparent radius of the Sun, spacecraft roll angle, L0, B0 corresponding to 'time_in'
;
; :examples:
;
;    data = stx_read_aux_fits( fits_path, time_in )
;
; :history:
;
;    May 1, 2022: Massa P. (MIDA, Unige), created
;
;-

function stx_read_aux_fits, fits_path, time_in, primary_header = primary_header, data_str = data, data_header = data_header, control_str = control, $
  control_header= control_header, idb_version_str = idb_version, idb_version_header = idb_version_header

  !null = stx_read_fits(fits_path, 0, primary_header,  mversion_full = mversion_full)
  control = stx_read_fits(fits_path, 'control', control_header, mversion_full = mversion_full)
  data = stx_read_fits(fits_path, 'data', data_header, mversion_full = mversion_full)
  idb_version = stx_read_fits(fits_path, 'idb_versions', idb_version_header, mversion_full = mversion_full)
  
  time_data = data.TIME_UTC
  if anytim(time_in) lt min(anytim(time_data)) or anytim(time_in) gt max(anytim(time_data)) then $
    message, "The aux fits file does not contain information for " + time_in
  
  ;Select the time closer to 'time_in'
  dummy_min = min(abs(anytim(time_data) - anytim(time_in)), ind_min)
  
  ;**** Read the values that are closer to 'time_in'
  
  ; Aspect solution
  Y_SRF = data[ind_min].Y_SRF
  Z_SRF = data[ind_min].Z_SRF
  ;Apparent solar radius (arcsec)
  RSUN = data[ind_min].spice_disc_size
  ;Roll angle (degrees)
  ROLL_ANGLE = data[ind_min].ROLL_ANGLE_RPY[0]
  ;Pitch (arcsec)
  PITCH = data[ind_min].ROLL_ANGLE_RPY[1] * 3600.
  ;Yaw (arcsec)
  YAW = data[ind_min].ROLL_ANGLE_RPY[2] * 3600.
  ;L0 (degrees)
  L0 = data[ind_min].solo_loc_carrington_lonlat[0]
  ;B0 (degrees)
  B0 = data[ind_min].solo_loc_carrington_lonlat[1]
  
  aux_data = {Y_SRF: Y_SRF, $
              Z_SRF: Z_SRF, $
              RSUN: RSUN, $
              ROLL_ANGLE: ROLL_ANGLE, $
              PITCH: PITCH, $
              YAW: YAW, $
              L0: L0, $
              B0: B0}
              
  return, aux_data

end