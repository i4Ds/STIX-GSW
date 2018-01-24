;+
; :description:
;     This procedure converts a given photon energy (keV) into the detector channel number of the ad-converter  
; 
; :how to use:
; 
;     plot, findgen(204)-2,stx_sim_energy2ad_channel(findgen(204)-2), psym=10, /xstyle, /ystyle
; 
; :modification history:
;     05-Feb-2014 - Nicky Hochmuth (FHNW), initial release
;     08-Jul-2015 - ECMD (Graz), added stop as this routine is now defunct 
;
; Gordon Hurford: 
;     ... the a/d will have 4096 channels, with the upper one corresponding to ~200 keV 
;     (TBC but slightly greater than 150 keV) and the lower one corresponding to ~-2 keV (TBC).  The latter is slightly negative to ensure 
;     that no pulse would be assigned a negative a/d value. The limits will differ slightly from detector to detector and will vary during 
;     the mission as the detector undergoes temperature and radiation damage.   The linearity is excellent so no need to allow for that.  
;     With these numbers, the formula would be A/D = (keV+2)*4095/202.  Energies comfortably greater than 150 keV will be flagged bad based 
;     on analog comparators and generate only triggers, not event words.
;-

function stx_sim_energy2ad_channel, energy
  stop ; this routine is no longer to be used, please replace with call to stx_sim_energy_2_pixel_ad
return, uint((energy + 2) * (4095 / 202.))
end