
;+
; :description:
;   This function creates an uninitialized stx_sim_calibration_spectrum structure.
;   
; :categories:
;    flight software, structure definition, simulation
;
; :returns:
;    an uninitialized stx_sim_calibration_spectrum structure
;
; :examples:
;    cs = stx_sim_calibration_spectrum()
;
; :history:
;     25-Feb-2014, Laszlo I. Etesi (FHNW), initial release
;     27-Feb-2014, Laszlo I. Etesi (FHNW), renamed tag
;     20-May-2015, Laszlo I. Etesi (FHNW), added tags used by SW for gate handling
;     27-May-2015, Richard Schwartz (CUA), changed structure with t_open
;     28-May-2015, Laszlo I. Etesi (FHNW), added start and end time tags
;
;-
function stx_sim_calibration_spectrum
  return, { type    : 'stx_sim_calibration_spectrum', $
            accumulated_counts    : ulon64arr(1024,12,32), $  ; 1024 channels, 12 pixel, 32 det 
            live_time             : 0.d, $
            tq_open               : 0.0d0, $                  ; time the gate will open from the start of the t_bin_width data pack in the next call to the accumulation routine
            ts_open               : 0.0d0, $
            start_time            : stx_time(), $
            end_time              : stx_time() } 
end