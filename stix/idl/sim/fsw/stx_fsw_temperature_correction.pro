;+
;  :description
;    This function apply the temperature correction for each pixel and each detector on the energy in A/D for each event of an event list
;
;  :categories:
;    STIX flight software simulator
;
;  :params:
;    eventlist : in, required, type='stx_sim_detector_eventlist'
;      the original detector eventlist
;       
;    temperature_correction_table : in, required, type='fltarr(12,32)'
;      the temperature correction table with 2 indexes (d from 1 to 32 and p from 0 to 11)
;
;  :example:
;    detector_eventlist = fsw_temperature_correction(eventlist, correction_table)
;
;  :history:
;    25-feb-2014 - Sophie Musset (LESIA), initial release
;    25-feb-2014 - Laszlo I. Etesi (FHNW), minor adjustments
;    30-jun-2014 - Laszlo I. Etesi (FHNW), bound the adjusted energies to [0, 4095)
;    14-Sep-2015 - Laszlo I. Etesi (FHNW), changed routine to expect detector indices to be between 1 and 32 (agreeing with specification!)
;    30-Oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;
;  :todo:
;    25-Feb-2014 - Sophie Musset (LESIA), check format of input 'temperature_correction_table'
;-

function stx_fsw_temperature_correction, eventlist, temperature_correction_table
  ; checking pixel and detector indices
  mm_pxl = minmax(eventlist.detector_events.pixel_index)
  mm_det = minmax(eventlist.detector_events.detector_index)
  
  if(mm_pxl[0] lt 0 || mm_pxl[1] gt 11) then message, 'Pixel index must be between 0 and 11'
  if(mm_det[0] lt 1 || mm_det[1] gt 32) then message, 'Detector index must be between 1 and 32'
  
  corrected_eventlist = eventlist
  corrected_eventlist.detector_events.energy_ad_channel = ((eventlist.detector_events.energy_ad_channel + temperature_correction_table[eventlist.detector_events.detector_index-1, eventlist.detector_events.pixel_index]) < 4095) > 0
  
  return, corrected_eventlist
end
