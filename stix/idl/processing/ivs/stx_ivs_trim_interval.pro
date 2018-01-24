;---------------------------------------------------------------------------
; Document name: stx_ivs_trim_interval.pro
; Created by:    Nicky Hochmuth, 2013/08/03
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
;       trimmed_interval = stx_ivs_trim_interval(orig_interval,spectrogram,split_times)
;
; HISTORY:
;       2013/08/03, Nicky.Hochmuth@fhnw.ch, initial release
;       
; TODO:
;       2013/08/03 Nicky Hochmuth: get default fraction from dbase 
;-
;+
; :description:
;     Let ti be complete set of (non duplicated) time boundaries. The ending time of the last
;     image in each energy channel is redetermined as follows. (a process called trimming). If
;     shortening the time interval by deleting counts that are between the last N time
;     boundaries does not reduce the number of count by more than a fraction,Ftrim, then
;     shorten that interval accordingly, Continue this process with N=1,2,3,,, until further
;     shortening does reduce the number of counts by more than the fraction,, Ftrim.
;       
; :params:
;    interval: the original interval to trim
;    
;    spectrogram: the spectrogram the interval is defind on
;    
;    times: all timesplits in the RCR block as candidates for trimming positions 
;     
; :keywords:
;    right: applay a left or right trimming
;     
;-
function stx_ivs_trim_interval, interval, spectrogram, times, right=right, max_loss=max_loss
  
  
  return, interval
  default, max_loss, double(0.05)
  default, right, 0
  
  ;find all indexes on time and energy axes from the values
  ;start_time_idx = (where(stx_time_eq(spectrogram.t_axis.time_start , interval.start_time)))[0]
  ;end_time_idx = (where(stx_time_eq(spectrogram.t_axis.time_end,interval.end_time)))[0]
  ;e_idx = (where(float(spectrogram.e_axis.low[*]) eq interval.start_energy))[0]
  
  start_time_idx = interval.start_time_idx
  end_time_idx = interval.end_time_idx
  
  e_idx_start =  value_locate(spectrogram.energy_axis.LOW_FSW_IDX, interval.start_energy_idx)
  e_idx_end =  value_locate(spectrogram.energy_axis.HIGH_FSW_IDX, interval.end_energy_idx)

  
  ;set the threshold for no further trimming
  min_count = uint(interval.counts * (1-max_loss))
  
  ;split_end_idx = where(times eq end_time_idx)
  ;split_start_idx = where(times eq start_time_idx)
  
  moved = 1
  
  ;trim the left or right side as fare as possible 
  while moved do begin
    moved = 0
    if right && start_time_idx lt end_time_idx && total(spectrogram.counts[e_idx_start : e_idx_end, start_time_idx:end_time_idx-1]) gt min_count then begin
      moved = 1
      ;end_time_idx = times[split_end_idx--]
      end_time_idx--
    end
    if ~right && end_time_idx gt start_time_idx && total(spectrogram.counts[e_idx_start : e_idx_end, start_time_idx+1:end_time_idx]) gt min_count then begin
      ;start_time_idx = times[split_start_idx++]+1
      start_time_idx++
      moved = 1
    end
  end
  
  ;end_time_idx<=18
  
  ;create the new interval 
  trimed_interval = stx_construct_fsw_ivs_interval( $
        spectrogram.time_axis.time_start[start_time_idx], spectrogram.time_axis.time_end[end_time_idx], $
        total(spectrogram.counts[e_idx_start : e_idx_end, start_time_idx:end_time_idx]),$
        start_time_idx=start_time_idx, end_time_idx=end_time_idx, $
        start_energy_idx = interval.start_energy_idx, end_energy_idx = interval.end_energy_idx, $
        spectroscopy = interval.spectroscopy, $
        trim = 10)
  print, trimed_interval.counts, interval.counts
  return, trimed_interval
end