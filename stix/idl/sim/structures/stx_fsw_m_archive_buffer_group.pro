;+
; :description:
;   This function creates an uninitialized archive buffer structure for the flight software simulation, which differs
;   slightly from the archive buffer format used in the analysis software (stx_archive_buffer).
;
; :categories:
;    flight software, structure definition, simulation
;
; :returns:
;    an uninitialized stx_sim_archive_buffer structure
;
; :examples:
;    ab = stx_sim_archive_buffer()
;
; :history:
;     23-Jan-2014, Laszlo I. Etesi (FHNW), initial release
;     11-Sep-2014, Nicky Hochmuth changed to named struct
;     07-Jul-2015, Laszlo I. Etesi (FHNW), changed specification (in documentation) for detector_index and
;                                          relative_time_range
;     10-May-2016, Laszlo I. Etesi (FHNW), FKA stx_fsw_archive_buffer__define, changed structure for new FSW SIM release
;
;-
function stx_fsw_m_archive_buffer_group, archive_buffer=archive_buffer, triggers=triggers, time_axis=time_axis, total_counts=total_counts
  default, time_axis, stx_construct_time_axis([0, 1])
  
  return, { $
    type              : 'stx_fsw_m_archive_buffer_group', $
    time_axis         : time_axis, $
    archive_buffer    : archive_buffer, $
    triggers          : triggers, $
    total_counts      : total_counts $
  }
end