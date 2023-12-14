;+
;
; NAME:
;
;   stx_grid_transmission
;
; PURPOSE:
;
;   Compute the transmission of a STIX grid corrected for internal shadowing
;
; CALLING SEQUENCE:
;
;   transmission = stx_grid_transmission(x_flare, y_flare, grid_orient, grid_pitch, grid_slit, grid_thick)
;
; INPUTS:
;
;   x_flare: X coordinate of the flare location (arcsec, in the STIX coordinate frame)
;
;   y_flare: Y coordinate of the flare location (arcsec, in the STIX coordinate frame)
;
;   grid_orient: orientation angle of the slits of the grid (looking from detector side, in degrees)
;
;   grid_pitch: dimension of pitch of the grid (mm)
;
;   grid_slit: dimension of slit of the grid (mm)
;
;   grid_thick: thickness of the grid (mm)
;
;   bridge_width: width of the bridges for the given grid (mm)
;
;   bridge_pitch: pitch of the bridges for the given grid (mm)
;
;   linear_attenuation: Linear Attenuation Coefficient for grid material [mm^-1] (assumed to be pure Tungsten)
;
;   flux: If set calculate the flux calibration factor rather than the amplitude calibration factor
;
;   simple_transm: if set a simplified version of the grid transmission is computed
;
; OUTPUTS:
;
;   A float number that represent the grid transmission value
;
; HISTORY: August 2022, Massa P., created
;          11-Jul-2023, ECMD (Graz), updated following Recipe for STIX Flux and Amplitude Calibration (8-Nov 2022 gh)
;                                    to include grid transparency and corner cutting
;          31-Oct-2023, Massa P., added 'simple_transm' keyword to compute a simple version of the grid transmission
;                                 (temporary solution used for imaging)
;
; CONTACT:
;   paolo.massa@wku.edu
;-


function stx_grid_transmission, x_flare, y_flare, grid_orient, grid_pitch, grid_slit, grid_thick, $
  bridge_width, bridge_pitch, linear_attenuation, flux = flux, simple_transm = simple_transm

  default, flux, 1

  if ~keyword_set(simple_transm) then begin
  
    bridge_factor = 1.0 - f_div(bridge_width,bridge_pitch)
  
    ;; Distance of the flare on the axis perpendicular to the grid orientation
    flare_dist   = abs(x_flare * cos(grid_orient * !dtor) + y_flare * sin(grid_orient * !dtor))
  
    ;; Internal shadowing
    shadow_width = grid_thick  * tan(flare_dist / 3600. * !dtor)
  
    nenergies = n_elements(linear_attenuation)
  
    slat_optical_depth = grid_thick * linear_attenuation
  
    slat_transmission = exp(-slat_optical_depth)
  
    ;calculate the transmission through the slat edge
    edge_transmission = (1. - slat_transmission) /slat_optical_depth
  
    grid_slit_e = replicate(grid_slit, nenergies)
    shadow_width_e = replicate(shadow_width, nenergies)
    grid_pitch_e =  replicate(grid_pitch, nenergies)
  
    effective_slit_width = grid_slit_e + shadow_width_e * (1. - 2.* (1- edge_transmission)/(1. - slat_transmission))
  
    flux_calibration = 2*(slat_transmission + (1.- slat_transmission)*effective_slit_width*bridge_factor/grid_pitch_e)
  
    amplitude_calibration = (1. - slat_transmission) * bridge_factor * sin(!pi * effective_slit_width / grid_pitch_e )
  
    transmission = keyword_set(flux) ? flux_calibration : amplitude_calibration 

    ; factors are relative to 0.5 value for ideal grids
    return, transmission/2.

  endif else begin
    
    ;; Distance of the flare on the axis perpendicular to the grid orientation
    flare_dist   = abs(x_flare * cos(grid_orient * !dtor) + y_flare * sin(grid_orient * !dtor))

    ;; Internal shadowing
    shadow_width = grid_thick  * tan(flare_dist / 3600. * !dtor)

    return, (grid_slit - shadow_width) / grid_pitch
    
  endelse
  
  

end
