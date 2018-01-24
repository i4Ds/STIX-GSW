;+
; :description:
;     This procedure converts a given photon energy (keV) into the detector channel number of the ad-converter
;
;
; :params:
;    energy    : in, required, type="float"
;                array of energy values in keV
;
;    detector   : in, required, type="integer"
;                array of detector numbers (1 - 32)
;
;    pixel : in, required, type="integer"
;                array of pixel indices (0 - 11)
;
;
; :modification history:
;
;     08-Jul-2015 - ECMD (Graz), initial release, replacing stx_sim_energy2ad_channel()
;
;-
function stx_sim_energy_2_pixel_ad, energy, detector, pixel

  offset_gain = reform( stx_offset_gain_reader( ), 12, 32 )
  gain = offset_gain[ pixel, detector - 1].gain
  offset = offset_gain[ pixel, detector - 1].offset
  energy_ad_channel = round(energy/gain + offset)
  
  return, energy_ad_channel
end
