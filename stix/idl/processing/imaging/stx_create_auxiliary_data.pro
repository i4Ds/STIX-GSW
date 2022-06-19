;+
;
; name:
;       stx_read_aux_fits
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
;    use_sas: is set, avoid check on the reliability and use SAS solution for providing an estimate of STIX pointing 
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
;
;-
function stx_create_auxiliary_data, fits_path, time_range, use_sas=use_sas

default, use_sas, 0
stx_read_aux_fits, fits_path, aux_data=aux_data_str

;************** Get the indices corresponding to the considered time range
this_time_range = anytim(time_range)
time_data       = anytim(aux_data_str.TIME_UTC)

;; CHECK: if the considered time interval is not contained in the time range of the aux_data structure, then throw an error
if this_time_range[0] lt min(time_data) or $
   this_time_range[1] lt min(time_data) or $
   this_time_range[0] gt max(time_data) or $
   this_time_range[1] gt max(time_data) then $
   message, "The aux fits file does not contain information for the considered time range."

time_ind = where((time_data ge this_time_range[0]) and (time_data le this_time_range[1]))

;************* Compute the average of the values of interest over the considered time range

; Aspect solution
X_SAS = average(aux_data_str[time_ind].Y_SRF)
Y_SAS = -average(aux_data_str[time_ind].Z_SRF)

;Apparent solar radius (arcsec)
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



;************* STIX pointing estimate 
; If aspect solution is available (i.e., ~NaN) and is reliable (i.e. not much different from the spacecraft estimate) 
; use it. Otherwise, use spacecraft pointing estimate

readcol, loc_file( 'Mapcenter_correction_factors.csv', path = getenv('STX_VIS_DEMO') ), $
  avg_shift_x, avg_shift_y, offset_x, offset_y

STX_POINTING = [avg_shift_x,avg_shift_y] + [YAW, PITCH]

if ~X_SAS.isnan() and ~Y_SAS.isnan() then begin

  sas_pointing        = [X_SAS, Y_SAS]
  spacecraft_pointing = [YAW, PITCH]
  
  if norm(sas_pointing - spacecraft_pointing) lt 200. or use_sas then begin
    
    STX_POINTING = [X_SAS, Y_SAS] + [offset_x, offset_y]  
    
  endif

endif  

aux_data = {STX_POINTING: STX_POINTING, $
            RSUN: RSUN, $
            ROLL_ANGLE: ROLL_ANGLE, $
            L0: L0, $
            B0: B0}
            

return, aux_data
            
end