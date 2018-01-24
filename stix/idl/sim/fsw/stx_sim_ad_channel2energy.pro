;+
; :description:
;     This function converts a given detector channel number of the ad-converter to photon energy (keV)
;     This function inverts the stx_sim_energy2ad_channel() function
;      
; :modification history:
;     11-Feb-2014 - Mel Byrne (TCD) adapted from stx_sim_energy2ad_channel()
;
; Gordon Hurford:
;     ... the a/d will have 4096 channels, with the upper one corresponding to ~200 keV 
;     (TBC but slightly greater than 150 keV) and the lower one corresponding to ~-2 keV (TBC).  The latter is slightly negative to ensure 
;     that no pulse would be assigned a negative a/d value. The limits will differ slightly from detector to detector and will vary during 
;     the mission as the detector undergoes temperature and radiation damage.   The linearity is excellent so no need to allow for that.  
;     With these numbers, the formula would be A/D = (keV+2)*4095/202.  Energies comfortably greater than 150 keV will be flagged bad based 
;     on analog comparators and generate only triggers, not event words.
;-

function stx_sim_ad_channel2energy, ad_channel
  return, uint(round(ad_channel * 202.0 / 4095.0) - 2.0)
end
