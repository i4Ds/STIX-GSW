;+
;
; NAME:
;
;   stx_grid_transmission
;
; PURPOSE:
;
;   Compute the transmission of a STIX grid
;
; CALLING SEQUENCE:
;
;   transmission = stx_grid_transmission(pitch, slit, thickness, L, simple_transm=simple_transm)
;
; INPUTS:
;
;   pitch: float, pitch of the grid (mm)
;   
;   slit: float, effective slit width of the grid at low energies (mm). This value must be
;         pre-calculated from low-energy calibration data, taking into account any potential
;         dependence on the flare location and subcollimator (e.g. using stx_subc_transmission.pro),
;         before being passed to this function.
;   
;   thickness: float, grid thickness (mm)
;   
;   L: float array, path length of X-rays in tungsten (mm) 
;
; KEYWORDS:
; 
; simple_transm: if set a simplified version of the grid transmission is computed (no energy dependence)
; 
; ds: float, width of the wedge model (mm)
; 
; dh: float, height of the wedge model (mm)
;
; OUTPUTS:
;
;   A float number that represents the grid transmission value
;
; HISTORY: August 2022, Massa P., created
;          11-Jul-2023, ECMD (Graz), updated following Recipe for STIX Flux and Amplitude Calibration (8-Nov 2022 gh)
;                                    to include grid transparency and corner cutting
;          31-Oct-2023, Massa P., added 'simple_transm' keyword to compute a simple version of the grid transmission
;                                 (temporary solution used for imaging)
;          14-Oct-2025, Massa P., high energy calibration based on wedge shape model
;
; CONTACT:
;   paolo.massa@fhnw.ch
;-

function stx_grid_transmission, pitch, slit, thickness, L, simple_transm=simple_transm, ds=ds, dh=dh

  ;; Parameters of the wedge grid transmission model. The values are derived from fitting of STIX observation (ds in mm, dh in mm)
  default, ds, 5e-3
  default, dh, 5e-2
  
  if ~keyword_set(simple_transm) then begin
  
    n_energies = n_elements(L)
  
    slit_rep = replicate(slit, n_energies)
    pitch_rep = replicate(pitch, n_energies)
    H_rep = replicate(thickness, n_energies)
  
    ;; Transmission for a wedge shape model for grid imperfections
    g0 = f_div(slit_rep, pitch_rep) + f_div(pitch_rep - slit_rep, pitch_rep) * exp( - f_div(H_rep, L) )
    ttt = f_div(L, dh) * ( 1. - exp(- f_div(dh, L) ) )
    g1 = 2. * f_div(ds, pitch_rep) * (ttt - exp( - f_div(H_rep, L) ))
    
    g_transmission = g0 + g1
  
  endif else begin
    
    g_transmission = f_div(slit, pitch)
  
  endelse
  
  return, g_transmission
  

end
