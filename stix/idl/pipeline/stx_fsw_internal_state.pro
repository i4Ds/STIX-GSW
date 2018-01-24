;+
; :file_comments:
;    This file contains the specific implementation of the internal state structure
;    for the Flight Software Simulator
;
; :categories:
;    pipeline processing framework
;
; :examples:
;    n/a
;
; :history:
;    10-May-2016 -  Laszlo I. Etesi (FHNW), initial release
;-
;+
; :description:
;   this routine creates a default FSW internal state 
;-
function stx_fsw_internal_state
  is = { $
    type:                         'stx_fsw_internal_state', $
    reference_time:               stx_time(), $               ; the absolute start time (first event, or similar)
    relative_time:                double(0), $                 ; the seconds since reference_time (current_time_bin * time_bin_width)
    current_time:                 stx_time(), $               ; the current time (reference_time + relative_time) as stx_time
    current_bin:                  long(-1), $                 ; this is the current time bin (iteration number), -1 means not initialized
    time_bin_width:               double(0), $                ; the standard bin width in seconds
    output_directories:           hash(), $                   ; a lookup table of accumulator/product, etc. names paired with their output folders
    memory_cached_data:           hash(), $                   ; a lookup table to the data; the data are in structure or array arrays, referenced by a pointer
    memory_cached_data_pos:       hash(), $                   ; contains positional information: [idx of T0, idx of Tcurrent, idx of Tend, increment]
    expected_number_time_bins:    long(0) $                  ; an estimate of the expected number of bins, used to initialized memory cache
  }

  return, is
end