;---------------------------------------------------------------------------
; Document name: stx_fsw_ivs_trim_interval.pro
; Created by:    Nicky Hochmuth, 2016/08/25
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; PURPOSE:
;     Let ti be complete set of (non duplicated) time boundaries. The ending time of the last
;     image in each energy channel is redetermined as follows. (a process called trimming). If
;     shortening the time interval by deleting counts that are between the last N time
;     boundaries does not reduce the number of count by more than a fraction,Ftrim, then
;     shorten that interval accordingly, Continue this process with N=1,2,3,,, until further
;     shortening does reduce the number of counts by more than the fraction,, Ftrim.
;
; CATEGORY:
;       Stix on Bord Algorithm
;
; CALLING SEQUENCE:
;       trimmed_interval = stx_fsw_ivs_trim_interval(orig_interval,spectrogram,split_times)
;
; HISTORY:
;       2013/08/03, Nicky.Hochmuth@fhnw.ch, initial release
;
; TODO:
;       2013/08/03 Nicky Hochmuth: get default fraction from dbase
;-
;+
; :DESCRIPTION:
;     Let ti be complete set of (non duplicated) time boundaries. The ending time of the last
;     image in each energy channel is redetermined as follows. (a process called trimming). If
;     shortening the time interval by deleting counts that are between the last N time
;     boundaries does not reduce the number of count by more than a fraction,Ftrim, then
;     shorten that interval accordingly, Continue this process with N=1,2,3,,, until further
;     shortening does reduce the number of counts by more than the fraction,, Ftrim.
;
; :PARAMS:
;    interval: the original interval to trim
;
;    spectrogram: the spectrogram the interval is defind on
;
;    times: all timesplits in the RCR block as candidates for trimming positions
;
; :KEYWORDS:
;    right: applay a left or right trimming
;
;-
function stx_fsw_ivs_trim_interval_orig, interval, spectrogram, times, right=right, max_loss = max_loss

  default, max_loss, double(0.05)
  default, right, 0
  
  ;max_loss = 0.5d
  ;max_loss = 0.000001d
  
  start_time_idx = interval.start_time_idx
  end_time_idx = interval.end_time_idx

  split_end_idx = where(times eq end_time_idx + 1)
  if split_end_idx eq -1 then split_end_idx = n_elements(times)-1
  split_start_idx = where(times eq start_time_idx)
  
  e_idx_start =  value_locate(spectrogram.energy_axis.low_fsw_idx, interval.start_energy_idx)
  e_idx_end =  value_locate(spectrogram.energy_axis.high_fsw_idx, interval.end_energy_idx)


  ;set the threshold for no further trimming
  min_count = uint(interval.counts * (1.0 - max_loss))

  moved = 1
  
  ;trim the right side as fare as possible
  while moved do begin
    moved = 0
    if right && start_time_idx lt end_time_idx && total(spectrogram.counts[e_idx_start : e_idx_end, start_time_idx:end_time_idx]) gt min_count then begin
      split_end_idx--
      end_time_idx = times[split_end_idx] - 1
      moved = 1
    end
    if ~right && end_time_idx gt start_time_idx && total(spectrogram.counts[e_idx_start : e_idx_end, start_time_idx:end_time_idx]) gt min_count then begin
      split_start_idx++
      start_time_idx = times[split_start_idx]
      moved = 1
    end
  end
  
  ;undo the last move because it causes the failure  
  if right then begin
    end_time_idx = times[split_end_idx + 1] - 1
  endif else begin
    start_time_idx = times[split_start_idx-1]
  endelse
  


  ;create the new interval
  trimed_interval = stx_construct_fsw_ivs_interval( $
    spectrogram.time_axis.time_start[start_time_idx], spectrogram.time_axis.time_end[end_time_idx], $
    total(spectrogram.counts[e_idx_start : e_idx_end, start_time_idx:end_time_idx]),$
    start_time_idx=start_time_idx, end_time_idx=end_time_idx, $
    start_energy_idx = interval.start_energy_idx, end_energy_idx = interval.end_energy_idx, $
    spectroscopy = interval.spectroscopy, $
    trim = 10)

  return, trimed_interval
end