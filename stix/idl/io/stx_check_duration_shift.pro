;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_check_duration_shift
;
; :description:
;    This procedure checks a given FITS file header for strings related to the time bin shift
;
; :categories:
;    fits
;
; :params:
;    primary_header : in, required, type="string"
;             a string array containing the contents of the primary header for the relevant
;             STIX science data FITS file.
;
; :keywords:
;    duration_shifted : out
;                   if 1 is returned the duration shift has already been applied to the FITS file
;                   data
;
;    duration_shift_not_possible : out
;                   if 1 is returned it has been assessed that the data request was most likely
;                   binned in time onboard making direct shifting of the time bins impossible.
;
;
;
; :examples:
;    stx_check_time_shift, primary_header, duration_shifted = duration_shifted, duration_shift_not_possible = duration_shift_not_possible
;
; :history:
;    27-Mar-2023 - ECMD (Graz), initial release
;
;-
pro stx_check_duration_shift, primary_header, duration_shifted = duration_shifted, duration_shift_not_possible = duration_shift_not_possible

  history = sxpar(primary_header,'HISTORY', count = count)
  duration_shift_done_message = 'Time and count arrays were shifted to fix offset'
  duration_shifted = count gt 0 ? total(history.contains(duration_shift_done_message), /pre) < 1 : 0
  if duration_shifted then message, duration_shift_done_message, /info

  duration_shift_not_possible_message = 'Time and count arrays offset not fixed as possibly summed on board'
  comment = sxpar(primary_header,'COMMENT', count = count)
  duration_shift_not_possible = count gt 0 ? total(comment.contains(duration_shift_not_possible_message), /pre) < 1 : 0
  if duration_shift_not_possible then message, duration_shift_not_possible_message, /info

end