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
; OUTPUTS:
;
;   A float number that represent the subcollimator transmission value
;
; HISTORY: August 2022, Massa P., first version (working only for detectors 3 to 10)
;          11-Jul-2023, ECMD (Graz), updated following Recipe for STIX Flux and Amplitude Calibration (8-Nov 2022 gh)
;                                    to include transparency and corner cutting for pure Tungsten grids
;
; CONTACT:
;   paolo.massa@wku.edu
;-


function stx_subc_transmission, flare_loc, ph_in

  restore,loc_file( 'grid_temp.sav', path = getenv('STX_GRID') )
  fff=read_ascii(loc_file( 'grid_param_front.txt', path = getenv('STX_GRID') ),temp=grid_temp)
  rrr=read_ascii(loc_file( 'grid_param_rear.txt', path = getenv('STX_GRID') ),temp=grid_temp)

  transm = fltarr(n_elements(ph_in),32)

  mass_attenuation = xsec(ph_in, 74,'AB',/cm2perg, error=error,use_xcom=1)
  gmcm = 19.30

  linear_attenuation = mass_attenuation*gmcm/10.

  theta = sqrt( ( flare_loc[0]* flare_loc[0]) +( flare_loc[1]* flare_loc[1]) ) / 3600./!radeg
  costheta = cos( theta )


  grid_orient_front = 180.-fff.o ;; Orientation of the slits of the grid as seen from the detector side
  grid_pitch_front  = fff.p
  grid_slit_front   = fff.slit
  grid_thick_front  = fff.thick
  bridge_width_front = fff.bwidth
  bridge_pitch_front = fff.bpitch

  grid_orient_rear = 180.-rrr.o ;; Orientation of the slits of the grid as seen from the detector side
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
        grid_pitch_front[i], grid_slit_front[i], grid_thick_front[i], bridge_width_front[i], bridge_pitch_front[i], linear_attenuation, flux = 1.)

      transm_rear  = stx_grid_transmission(flare_loc[0], flare_loc[1], grid_orient_rear[i], $
        grid_pitch_rear[i], grid_slit_rear[i], grid_thick_rear[i], bridge_width_rear[i], bridge_pitch_rear[i], linear_attenuation, flux = 1.)

      transm[*,sc[i]-1] = transm_front * transm_rear

    endif

  endfor

  transm[where(transm eq 0.)] = 1

  return, transm

end
