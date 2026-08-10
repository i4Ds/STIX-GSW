;+
;
; NAME:
;
;   stx_subc_transmission
;
; PURPOSE:
;
;   Compute STIX subcollimators' transmission:
;   - Low-energy transmission is derived from self-calibration using fully illuminated CFL pixels
;   - High-energy transmission is based on a wedge model for grid imperfections
;
; CALLING SEQUENCE:
;
;   subc_transmission = stx_subc_transmission(flare_loc, ph_in, simple_transm = simple_transm)
;
; INPUTS:
;
;   flare_loc: bidimensional array containing the X and Y coordinate of the flare location
;             (arcsec, in the STIX coordinate frame)
;             
;   ph_in: an array of photon energies [keV] (restricted to range 1-1000)
;
; OUTPUTS:
;
;   Transmission value for every subcollimator
;
; KEYWORDS:
;   
;   simple_transm: if set, the energy-dependence of the grid transmission is not considered
;   
;   silent: if set, no message is displayed
;
; HISTORY: May 2025, Massa P., based on the previous version by ECMD.
;                    Working only for detectors 3 to 10.
;          March 2026, Massa P., new sub-collimator transmission including also 1a,b,c and 2a,b,c 
;          
; CONTACT:
;   paolo.massa@fhnw.ch
;-


function stx_subc_transmission, flare_loc, ph_in, simple_transm = simple_transm, silent = silent, _extra=extra


  ; For backwards compatibility if no photon energy array is passed in the transmission is calculated for 1 keV
  ; (the lowest tabulated value). This should provide a reasonable approximation to the previously assumed
  ; fully opaque grids.

  if ~keyword_set(ph_in) then begin
    ph_in = 1.
    if ~keyword_set(silent) then begin
      if ~keyword_set(simple_transm) then message, 'No photon energies passed, calculating low energy approximation at 1 keV.', /info $
      else message, 'Simple grid transmission selected, calculating opaque approximation.', /info
    endif
  endif


  ;;************ Read grid parameters
  restore,loc_file( 'grid_temp.sav', path = getenv('STX_GRID') )
  fff=read_ascii(loc_file( 'grid_param_front.txt', path = getenv('STX_GRID') ),temp=grid_temp)
  rrr=read_ascii(loc_file( 'grid_param_rear.txt', path = getenv('STX_GRID') ),temp=grid_temp)
  
  ;; Orientation of the slits of the grid as seen from the detector side
  grid_orient_front_all = fff.o 
  grid_orient_rear_all = rrr.o
  
  pitch_front_all = fff.P
  pitch_rear_all = rrr.P
  
  thickness_front_all = fff.THICK
  thickness_rear_all = rrr.THICK

  sc = fff.SC
  
  ;;************ Read intercept and slope of the transmission linear fits
  fpath = loc_file( 'stix_subcoll_transmission_10_15keV.csv', path = getenv('STX_GRID') )
  
  ; Ensure the transmission file exists before attempting to read it
  if ~file_exist(fpath) then message, 'stx_subc_transmission: Transmission file not found.'
  
  ; Read the transmission parameters with error trapping
  catch, error_status
  if error_status ne 0 then begin
    
    ; An error occurred during READCOL
    catch, /cancel
    message, 'stx_subc_transmission: Error reading transmission file: ' + !error_state.msg
    
  endif
  
  subc_transmission = read_csv(fpath, n_table_header=1)
  subc_n_all = subc_transmission.FIELD1
  subc_label = subc_transmission.FIELD2
  intercept_all = subc_transmission.FIELD3
  slope_all = subc_transmission.FIELD5

  ; Cancel error trapping now that READCOL has completed
  catch, /cancel
  ; Basic sanity checks on the loaded columns
  if (n_elements(subc_n_all) eq 0) or $
    (n_elements(subc_label)    ne n_elements(subc_n_all)) or $
    (n_elements(intercept_all) ne n_elements(subc_n_all)) or $
    (n_elements(slope_all)     ne n_elements(subc_n_all)) then begin
    message, 'stx_subc_transmission: Malformed transmission file (unexpected number of columns/rows): ' + fpath
  endif
  
  
  if ~keyword_set(simple_transm) then begin
  
    ;;************ Compute path length in tungsten (L)
    
    ; To determine the transmission through the tungsten slats a Linear Attenuation Coefficient [mm-1]
    ; (1/absorption length in mm) is estimated for an each expected incoming photon energy and passed to stx_grid_transmission.
    ; The mass attenuation coefficient [cm^2/gm] is calculated using the xcom tabulated values in xsec.pro
    ; and a value of 19.3 g/cm3 is used for the density of tungsten. This is then divided by 10 to convert from [cm-1] to [mm-1].
    
    mass_attenuation = xsec(ph_in, (Element2Z('W'))[0], 'AB', /cm2perg, error=error, use_xcom=1)
    gmcm = 19.30
    L = f_div(1., (mass_attenuation*gmcm/10.)) ;; in mm 
   
    subc_transmission=fltarr(n_elements(L),32) 
    
    for subc_n=0,31 do begin
      
      if ((subc_n+1) eq 9) or ((subc_n+1) eq 10) then continue ;; Exclude CFL and BKG
      
      ;;-------- FRONT GRID

      subc_n_front = fff.SC
      idx = where(subc_n_front eq (subc_n+1), count)

      if count ne 0 then begin 

        if ((subc_n+1) ne 11) and ((subc_n+1) ne 12) and ((subc_n+1) ne 13) and ((subc_n+1) ne 17) and ((subc_n+1) ne 18) and ((subc_n+1) ne 19) then begin ;; Detectors from 3a,b,c to 10a,b,c
  
          grid_orient_front = grid_orient_front_all[idx]
          pitch_front = pitch_front_all[idx]
          thickness_front = thickness_front_all[idx]
  
  
        endif else begin
  
          if ((subc_n+1) eq 12) or ((subc_n+1) eq 17) or ((subc_n+1) eq 19) then begin ;; Detectors 2a,b,c
  
            grid_orient_front = mean(grid_orient_front_all[idx])
            pitch_front = mean(pitch_front_all[idx]) / 2.
            thickness_front = 0.2
  
          endif else begin ;; Detectors 1a,b,c
  
            grid_orient_front = mean(grid_orient_front_all[idx])
            pitch_front = mean(pitch_front_all[idx]) / 3.
            thickness_front = 0.133
  
          endelse
  
        endelse
      
      endif

      ;;-------- REAR GRID

      subc_n_rear = rrr.SC
      idx = where(subc_n_rear eq (subc_n+1), count)
      
      if count ne 0 then begin 

        if ((subc_n+1) ne 11) and ((subc_n+1) ne 12) and ((subc_n+1) ne 13) and ((subc_n+1) ne 17) and ((subc_n+1) ne 18) and ((subc_n+1) ne 19) then begin ;; Detectors from 3a,b,c to 10a,b,c
  
          grid_orient_rear = grid_orient_rear_all[idx]
          pitch_rear = pitch_rear_all[idx]
          thickness_rear = thickness_rear_all[idx]
  
  
        endif else begin
  
          if ((subc_n+1) eq 12) or ((subc_n+1) eq 17) or ((subc_n+1) eq 19) then begin ;; Detectors 2a,b,c
  
            grid_orient_rear = mean(grid_orient_rear_all[idx])
            pitch_rear = mean(pitch_rear_all[idx]) / 2.
            thickness_rear = 0.2
  
          endif else begin ;; Detectors 1a,b,c
  
            grid_orient_rear = mean(grid_orient_rear_all[idx])
            pitch_rear = mean(pitch_rear_all[idx]) / 3.
            thickness_rear = 0.133
  
          endelse
  
        endelse
      
      endif
      
      grid_orient_avg = (grid_orient_front + grid_orient_rear) / 2.

      ;;------ Off-axis angle theta
      flare_loc_deg = flare_loc / 3600. ;; Convert coordinates to deg
      theta = flare_loc_deg[0] * cos(grid_orient_avg * !dtor) + flare_loc_deg[1] * sin(grid_orient_avg * !dtor)

      ;;------ Subcollimator transmission at low energies
      idx = where(subc_n_all eq (subc_n+1), count)
      if count eq 0 then message, 'File ' + fpath + ' does not contain information on subcollimator '+ STRTRIM(STRING(subc_n+1), 2)

      intercept = intercept_all[idx]
      slope = slope_all[idx]

      value = intercept + slope * theta

      if value le 0.0 then message, "Transmission value for subcollimator " + STRTRIM(STRING(subc_n+1), 2) + " is <= 0. Please, check if the provided flare location is correct."
      
      subc_transm_low_e = value

      ;;------ Transmission of front and rear grid
      slit_to_pitch = sqrt(subc_transm_low_e)

      slit_front = slit_to_pitch*pitch_front
      slit_rear = slit_to_pitch*pitch_rear

      if ((subc_n+1) ne 11) and ((subc_n+1) ne 12) and ((subc_n+1) ne 13) and ((subc_n+1) ne 17) and ((subc_n+1) ne 18) and ((subc_n+1) ne 19) then begin ;; Detectors from 3a,b,c to 10a,b,c
        transm_front = stx_grid_transmission(pitch_front, slit_front, thickness_front, L, simple_transm=simple_transm, _extra=extra)
        transm_rear = stx_grid_transmission(pitch_rear, slit_rear, thickness_rear, L, simple_transm=simple_transm, _extra=extra)
      endif else begin
        transm_front = stx_grid_transmission(pitch_front, slit_front, thickness_front, L, simple_transm=simple_transm, ds=0, dh=0, _extra=extra)
        transm_rear = stx_grid_transmission(pitch_rear, slit_rear, thickness_rear, L, simple_transm=simple_transm, ds=0, dh=0, _extra=extra)
      endelse

      subc_transmission[*,subc_n] = transm_front * transm_rear
      
    endfor
    
  endif else begin
    
    ;;************ SIMPLE GRID TRANSMISSION: NO ENERGY DEPENDENCE
    
    subc_transmission=fltarr(32)

    for subc_n=0,31 do begin
      
      if ((subc_n+1) eq 9) or ((subc_n+1) eq 10) then continue ;; Exclude CFL and BKG
      
      ;;-------- FRONT GRID

      subc_n_front = fff.SC
      idx = where(subc_n_front eq (subc_n+1), count)

      if count ne 0 then begin 

        if ((subc_n+1) ne 11) and ((subc_n+1) ne 12) and ((subc_n+1) ne 13) and ((subc_n+1) ne 17) and ((subc_n+1) ne 18) and ((subc_n+1) ne 19) then begin ;; Detectors from 3a,b,c to 10a,b,c

          grid_orient_front = grid_orient_front_all[idx]

        endif else begin ;; Detectors 1a,b,c, 2a,b,c

          grid_orient_front = mean(grid_orient_front_all[idx])

        endelse

      endif

      ;;-------- REAR GRID

      subc_n_rear = rrr.SC
      idx = where(subc_n_rear eq (subc_n+1), count)

      if count ne 0 then begin 

        if ((subc_n+1) ne 11) and ((subc_n+1) ne 12) and ((subc_n+1) ne 13) and ((subc_n+1) ne 17) and ((subc_n+1) ne 18) and ((subc_n+1) ne 19) then begin ;; Detectors from 3a,b,c to 10a,b,c

          grid_orient_rear = grid_orient_rear_all[idx]


        endif else begin ;; Detectors 1a,b,c, 2a,b,c

          grid_orient_rear = mean(grid_orient_rear_all[idx])
 
        endelse

      endif
      
      grid_orient_avg = (grid_orient_front + grid_orient_rear) / 2.

      ;;------ Off-axis angle theta
      flare_loc_deg = flare_loc / 3600. ;; Convert coordinates to deg
      theta = flare_loc_deg[0] * cos(grid_orient_avg * !dtor) + flare_loc_deg[1] * sin(grid_orient_avg * !dtor)
      
      ;;------ Subcollimator transmission at low energies
      idx = where(subc_n_all eq (subc_n+1), count)
      if count eq 0 then message, 'File ' + fpath + ' does not contain information on subcollimator '+ STRTRIM(STRING(subc_n+1), 2)
      
      intercept = intercept_all[idx]
      slope = slope_all[idx]
      
      value = intercept + slope * theta
      
      if value le 0. then message, "Transmission value for subcollimator " + STRTRIM(STRING(subc_n+1), 2) + " is <= 0. Please, check if the provided flare location is correct."
        
        subc_transmission[subc_n] = value
      
    endfor

  endelse
  
  return, subc_transmission

end
