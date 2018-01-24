;+
; :description:
;     This procedure defines stx_sim_photon structure
;     Structure contains the basic information of simulated photon:
;     x_loc, y_loc - heliocentric (arcsec) coordinates of photon on the solar disk 
;     theta - photon path tilt from STIX optical axis (assumes that STIX is pointing at Sun centre)
;     omega - photon source position angle 
;     x_pos, y_pos - incident photon locations on the STIX front plane 
; 
; :modification history:
;     29-Oct-2012 - Marek Steslicki (Wro), initial release
;     15-Oct-2013 - Shaun Bloomfield (TCD), modified tag names during
;                   merging with STX_SIM_FLARE.pro
;     01-Nov-2013 - Shaun Bloomfield (TCD), now anonymous structure
;                   and 'name' tag changed to 'source'
;     04-Nov-2013 - Shaun Bloomfield (TCD), added detector pixel tag,
;                   transmission probability changed to path length
;     28-Jul-2014 - Shaun Bloomfield (TCD), lengths converted to mm
;     30-Jul-2014 - Laszlo I. Etesi (FHNW), named structure, adjusted word width (minimized)
;-
function stx_sim_photon_structure
  
  src = { stx_sim_photon,       $
          source_id:1b,         $ ; source number
          source_sub_id:1b,     $ ; source sub number
          time:0.d,             $ ; time of photon arrival
          energy:0.,            $ ; photon energy [keV]
          x_loc:0.,             $ ; photon sky X location wrt. STIX optical axis [arcsec]
          y_loc:0.,             $ ; photon sky Y location wrt. STIX optical axis [arcsec]
          theta:0.,             $ ; photon path tilt from STIX optical axis [degrees]
          omega:0.,             $ ; photon source position angle [degrees] measured CCW from STIX +Y-axis when viewed from Sun
          x_pos:0.,             $ ; STIX front grid photon arrival X position wrt. STIX optical axis [mm]
          y_pos:0.,             $ ; STIX front grid photon arrival Y position wrt. STIX optical axis [mm]
          f_path_length:0.,     $ ; photon front grid plane path length [mm]
          r_path_length:0.,     $ ; photon rear grid plane path length [mm]
          subc_f_n:0b,          $ ; photon front grid subcollimator number
          subc_r_n:0b,          $ ; photon rear grid subcollimator number
          subc_d_n:0b,          $ ; photon detector subcollimator number
          pixel_n:0b            $ ; photon detector pixel number
        }
  
  return, src
  
end
