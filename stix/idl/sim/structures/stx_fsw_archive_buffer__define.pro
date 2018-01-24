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
;
;-
pro stx_fsw_archive_buffer__define
  void = { stx_fsw_archive_buffer, $
            relative_time_range     : dblarr(2), $ ; relative start and end time of integration in seconds
            detector_index          : 0b, $ ; 1 - 32 (see stx_subc_params in dbase)
            pixel_index             : 0b, $ ; 0 - 11 (see stx_pixel_data)
            energy_science_channel  : 0b, $ ; [0, 31]
            counts                  : ulong(0) $ ; number of integrated counts
          }
end