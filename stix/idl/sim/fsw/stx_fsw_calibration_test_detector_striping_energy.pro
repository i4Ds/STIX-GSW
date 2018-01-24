;+
; :Description:
;    replace energies (energy_ad_channel) in eventlist with striping energies based on pixel and detector indices
;    use first 96 ad channels for pixel index, allow 8 channels per pixel, extra pixels to allow for temp drift
;    then use 8*32 (256) ad channels for detector index stripe starting at ad_channel 104
;    divide the events into two groups, one for the pixel index stripe and the other for the detector index stripe
;
; :Params:
;    events - use this data structure to pass in an eventlist which is to be modified
;IDL> help, events,/st
;** Structure <178cfe80>, 5 tags, length=16, data length=13, refs=1:
;   RELATIVE_TIME   DOUBLE        0.0018805000
;   DETECTOR_INDEX  BYTE        10
;   PIXEL_INDEX     BYTE         2
;   ENERGY_AD_CHANNEL
;                   UINT          1469
;   ATTENUATOR_FLAG BYTE         0
; :Author: rschwartz70@gmail.com, richard schwartz
; :History: 27-may-2015
;-
function stx_fsw_calibration_test_detector_striping_energy, events

nevents = n_elements( events )
coin    = randomu( seed, nevents ) gt 0.5
ipix    = where( coin, pcount, complement= idet, ncomp = dcount )
events[ipix].energy_ad_channel = 8 * events[ipix].pixel_index + 4 ;put it in the middle
events[idet].energy_ad_channel = 8 * ( events[idet].detector_index - 1 ) + 4 + 104 
return, events
end
