;+
;  :description:
;    Create a new STX_FSW_MODULE_EVENTLIST_TO_ARCHIVE_BUFFER object
;    
;  :history:
;    07-Jul-2015 - Laszlo I. Etesi (FHNW), - added new parameter close_last_time_bin
;                                         - removed has_leftovers
;                                         - changed starttime to be double instead ulong64
;    30-Oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;    07-Jan-2016 - Laszlo I. Etesi (FHNW), bugfix in the input specification
;    10-May-2016 - Laszlo I. Etesi (FHNW), updated structure type names
;
; returns the new module
;-
function stx_fsw_module_eventlist_to_archive_buffer
  return , obj_new('stx_fsw_module_eventlist_to_archive_buffer','stx_fsw_module_eventlist_to_archive_buffer', $
                    ['stx_sim_calibrated_detector_eventlist', 'stx_sim_calibrated_detector_event*',  'double',          'stx_fsw_m_detector_monitor',             'byte'],$
                    ['eventlist',                            'leftovers',                'starttime', 'detector_monitor',  'close_last_time_bin'])
end
