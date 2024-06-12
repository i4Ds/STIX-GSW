;+
;
; NAME:
;
;   stx_subc_transmission
;
; PURPOSE:
;
;   Compute the transmission of a STIX subcollimator corrected for internal shadowing
;
; CALLING SEQUENCE:
;
;   subc_transmission = stx_subc_transmission(flare_loc)
;
; INPUTS:
;
;   flare_loc: bidimensional array containing the X and Y coordinate of the flare location
;             (arcsec, in the STIX coordinate frame)
;
;   ph_in: an array of photon energies [keV] (restricted to range 1-1000)
;
; KEYWORDS:
; 
;   simple_transm: if set a simplified version of the grid transmission is computed
;
; OUTPUTS:
;
;   A float number that represent the subcollimator transmission value
;
; HISTORY: August 2022, Massa P., first version (working only for detectors 3 to 10)
;          11-Jul-2023, ECMD (Graz), updated following Recipe for STIX Flux and Amplitude Calibration (8-Nov 2022 gh)
;                                    to include transparency and corner cutting for pure Tungsten grids
;          24-Oct-2023, ECMD (Graz), added default to calculate low energy approximation if no input photon energies are passed
;          31-Oct-2023, Massa P., added 'simple_transm' keyword to compute a simple version of the grid transmission
;                                 (temporary solution used for imaging)
;          12-Jun-2024, Massa P., corrected bug in the definition of grid orientation to be used for computing 
;                                 the offset angle of the flare location relative to the slats.
;          
; CONTACT:
;   paolo.massa@wku.edu
;-


function stx_subc_transmission, flare_loc, ph_in, flux = flux, simple_transm = simple_transm, silent = silent

  restore,loc_file( 'grid_temp.sav', path = getenv('STX_GRID') )
  fff=read_ascii(loc_file( 'grid_param_front.txt', path = getenv('STX_GRID') ),temp=grid_temp)
  rrr=read_ascii(loc_file( 'grid_param_rear.txt', path = getenv('STX_GRID') ),temp=grid_temp)

; To determine the transmission through the tungsten slats a Linear Attenuation Coefficient [mm-1] 
; (1/absorption length in mm) is estimated for an each expected incoming photon energy and passed to stx_grid_transmission. 
; The mass attenuation coefficient [cm^2/gm] is calculated using the xcom tabulated values in xsec.pro 
; and a value of 19.3 g/cm3 is used for the density of tungsten. This is then divided by 10 to convert from [cm-1] to [mm-1].
;
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


  transm = fltarr(n_elements(ph_in), 32) ; the tranmission is calculated 

  mass_attenuation = xsec(ph_in, (Element2Z('W'))[0], 'AB', /cm2perg, error=error, use_xcom=1)
  gmcm = 19.30

  linear_attenuation = mass_attenuation*gmcm/10.


  grid_orient_front = fff.o ;; Orientation of the slits of the grid as seen from the detector side
  grid_pitch_front  = fff.p
  grid_slit_front   = fff.slit
  grid_thick_front  = fff.thick
  bridge_width_front = fff.bwidth
  bridge_pitch_front = fff.bpitch

  grid_orient_rear = rrr.o ;; Orientation of the slits of the grid as seen from the detector side
  grid_pitch_rear  = rrr.p
  grid_slit_rear   = rrr.slit
  grid_thick_rear  = rrr.thick
  bridge_width_rear = rrr.bwidth
  bridge_pitch_rear = rrr.bpitch


  sc = fff.sc

  for i=0,n_elements(grid_pitch_front)-1 do begin

    ;; Exclude detectors 1 and 2
    if (sc[i] ne 11) and (sc[i] ne 12) and (sc[i] ne 13) and (sc[i] ne 17) and (sc[i] ne 18) and (sc[i] ne 19) then begin

      transm_front = stx_grid_transmission(flare_loc[0], flare_loc[1], grid_orient_front[i], $
        grid_pitch_front[i], grid_slit_front[i], grid_thick_front[i], bridge_width_front[i], bridge_pitch_front[i], $
        linear_attenuation, flux = flux, simple_transm = simple_transm)

      transm_rear  = stx_grid_transmission(flare_loc[0], flare_loc[1], grid_orient_rear[i], $
        grid_pitch_rear[i], grid_slit_rear[i], grid_thick_rear[i], bridge_width_rear[i], bridge_pitch_rear[i], $
        linear_attenuation, flux = flux, simple_transm = simple_transm)

      transm[*,sc[i]-1] = transm_front * transm_rear

    endif

  endfor

  transm[where(transm eq 0.)] = 0.25

  return, transm

end
