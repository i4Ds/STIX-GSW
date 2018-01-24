;+
;  :description
;    This procedure provides a timed and calibrated event list with the science enegy bin
;
;  :categories:
;    STIX flight software simulator
;
;  :params:
;    eventlist : in, required, type='stx_sim_detector_eventlist'
;      corrected event list with A/D channels
;       
;    science_channels : in, required, type='intarr(32,12,33)'
;      boundaries of the sciences channels in A/D, for each detector and each pixel
;       
;    calibrated_eventlist : out, type='stx_sim_calibrated_eventlist'
;      corrected event list with science channels
;
;  :example:
;    calib_eventlist = stx_fsw_science_energy_application(eventlist, boundaries)
;   
;  :returns:
;    a calibrated event list structure
;
;  :history:
;    25-feb-2014 - Sophie Musset (LESIA), initial release
;    26-feb-2014 - Sophie Musset (LESIA), rewrited with more efficient method
;    26-feb-2014 - Laszlo I. Etesi (FHNW), minor adjustments
;    27-mar-2014 - Sophie Musset (LESIA), remove events which are not in a science energy channel from the output
;                                        change expected number of A/D channels of input from 1024 to 4096
;    22-apr-2014 - Richard Schwartz (rschwartz70@gmail.com), changed order of science channels from det, pix, edge to edge, pix, det
;     also will still work with old format as it checks the dimensions, also replaced loop variables d, p, e with id, ip, ie
;     because I'm old school and think this is a useful practice to maintain (using FORTRAN standard letters (i-n) for integer types
;    01-jul-2015 - Aidan O'Flannagain (TCD), if no events are left after removal, return a single default event                                     
;    03-jul-2015 - Sophie Musset (LESIA) use stx_energy_lut_get to create table of correspondance between AD energy and science energy bins
;    09-jul-2015 - ECMD (Graz), now accepts energy_table in intarr( 32, 12, 4096 ) format and uses stx_energy_lut_get( /full_table ) as the defualt if none is passed
;    30-oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;    10-may-2016 - Laszlo I. Etesi (FHNW), updates due to structure changes
;    
;  :todo:
;    26-feb-2014 - Sophie Musset (LESIA), check input format of science_channels, done, richard schwartz, 22-apr-2014
;   
;-

function stx_fsw_science_energy_application, eventlist, energy_table
  ; creation of calibrated detector event list (it is only the 'detector_events' field in eventlist structure)
  calibrated_detector_events = replicate(stx_sim_calibrated_detector_event(),n_elements(eventlist.detector_events))
  
  ; initialisation of parameters which are identical to input
  calibrated_detector_events.relative_time = eventlist.detector_events.relative_time
  calibrated_detector_events.detector_index = eventlist.detector_events.detector_index
  calibrated_detector_events.pixel_index = eventlist.detector_events.pixel_index
  
  ; creation of table of correspondance between ad energy and science energy
  default, energy_table, stx_energy_lut_get( /full_table )
  
  ; attribution of energy science channels
  calibrated_detector_events.energy_science_channel = energy_table[eventlist.detector_events.detector_index-1, eventlist.detector_events.pixel_index, eventlist.detector_events.energy_ad_channel]
  
  ;remove events which are not in a science channel
  sc = where(calibrated_detector_events.energy_science_channel ne 99, num_sc)
  ;if all events were removed, return a single default event
  final_calibrated_detector_events = (num_sc eq 0)? stx_sim_calibrated_detector_event() : calibrated_detector_events[sc]
  
  ; creation of output, which is a calibrated_eventlist structure
  return, stx_construct_sim_calibrated_detector_eventlist(start_time=eventlist.time_axis.time_start, detector_events=final_calibrated_detector_events, sources=eventlist.sources)
  
end