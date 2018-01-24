;---------------------------------------------------------------------------
; Document name: stx_fsw_ivs_column_spc__define.pro
; Created by:    Nicky Hochmuth, 2012/03/05
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; PURPOSE:
;       Performes a recursive interval selection on a spetrogram column
;
; CATEGORY:
;       Stix on Bord Algorithm
;
; CALLING SEQUENCE:
;       obj = stx_fsw_ivs_column_spc(start_time, end_time, rows, spectrogram)
;       intervals = obj->get_intervals()
;
; HISTORY:
;       2012/03/05, Nicky.Hochmuth@fhnw.ch, initial release
;
;-

;+
; :DESCRIPTION:
;    Initializes the stx_fsw_ivs_column_spc object
;
; :PARAMS:
;   start_time: the index on the time axis of the spectrogram the column starts
;   end_time: the index on the time axis of the spectrogram the column ends
;   rows: an array of all indexes on the energy axis this column is created for
;   spectrogram: a pointer to the spectrogram
;
; :AUTHOR: nicky.hochmuth
;-
function stx_fsw_ivs_column_spc::init, start_time, end_time, spectrogram, thermalboundary, min_time, min_count_termal, min_count_nontermal

  ;do some parameter testing
  if ~ppl_typeof(spectrogram, compareto='pointer') then begin
    message, 'Spectrogram has to be a pointer', /continue
    return, 0
  end

  self.thermalboundary      = thermalboundary
  self.min_time             = min_time
  self.min_count_termal     = min_count_termal
  self.min_count_nontermal  = min_count_nontermal

  self.start_time = start_time
  self.end_time = end_time

  self.spectrogram = spectrogram

  return, 1
end

;+
; :description:
;    Cleanup of this class
;-
pro stx_fsw_ivs_column_spc::cleanup
  ;free_pointer, self.spectrogram
end





;+
; :DESCRIPTION:
;    performes the rekursive interval selection by spliting the time intervals into halves
;
; :KEYWORDS:
;    ni: return the ni values for each cell in the column
;    exclusion: 0: a 0-ni cell will be merged with the adjacent interval / back into the former parent cell
;               1: a 0-ni cell will be ignored
;
; :AUTHOR: nicky.hochmuth
;-
function stx_fsw_ivs_column_spc::get_intervals


  split_time = self->getbarycenter()

  if split_time+1 le self.end_time then begin
    ;split the column into two halves and get the intervals of each side recursive

    left = stx_fsw_ivs_column_spc(self.start_time,split_time, self.spectrogram,thermalboundary=self.thermalboundary,min_time=self.min_time, min_count = [self.min_count_termal, self.min_count_nontermal])
    right = stx_fsw_ivs_column_spc(split_time+1,self.end_time, self.spectrogram,thermalboundary=self.thermalboundary,min_time=self.min_time, min_count = [self.min_count_termal, self.min_count_nontermal])

    if left.is_valid() && right.is_valid() then begin

      intervals_left = left->get_intervals()
      intervals_right = right->get_intervals()
      ;concat the left and right intervals to the interval list
      return, [intervals_left,intervals_right]
    end
  endif ;split excists

  ;transform the start and end index to time values
  start_time = (*self.spectrogram).time_axis.time_start[self.start_time]
  end_time = (*self.spectrogram).time_axis.time_end[self.end_time]


  n_rows = (size((*self.spectrogram).counts))[1]
    
  intervals = replicate(stx_fsw_ivs_interval(), n_rows) 

  ;go thru each cell and create a time_energy_bin for spectroscopy
  for row_idx=0, n_rows-1 do begin
    intervals[row_idx] = stx_construct_fsw_ivs_interval(start_time, end_time, $ 
      total((*self.spectrogram).counts[row_idx, self.start_time:self.end_time]), $
      start_time_idx = self.start_time, end_time_idx = self.end_time, $
      start_energy_idx=row_idx, end_energy_idx=row_idx, $
      spectroscopy = 1)
  end

  return,   intervals
end


function stx_fsw_ivs_column_spc::getbarycenter

  split_time = self.start_time
  collumn_mass = total((*self.spectrogram).counts[*, self.start_time:self.end_time], 1, /PRESERVE_TYPE)
  total_mass = total(collumn_mass, /PRESERVE_TYPE)
  left_mass = 0
  step=-1

  while split_time le self.end_time && left_mass lt total_mass/2 do begin
    step++
    split_time++
    left_mass += collumn_mass[step]
  end

  split_time--
  return, split_time
end

function stx_fsw_ivs_column_spc::is_valid


  start_time = (*self.spectrogram).time_axis.time_start[self.start_time]
  end_time = (*self.spectrogram).time_axis.time_end[self.end_time]

  if stx_time_diff(start_time,end_time, /ABS) lt self.min_time then return, 0

  thermal_bands = indgen(self.thermalboundary)
  nonthermal_bands = indgen((size((*self.spectrogram).counts))[1] - self.thermalboundary) + self.thermalboundary
   
  thermal_counts = total((*self.spectrogram).counts[thermal_bands, self.start_time : self.end_time],/integer)
  nonthermal_counts = total((*self.spectrogram).counts[nonthermal_bands, self.start_time : self.end_time],/integer)

  return, thermal_counts gt self.min_count_termal || nonthermal_counts gt self.min_count_nontermal

end


;+
; :description:
;    Constructor
;
; :hidden:
;-
pro stx_fsw_ivs_column_spc__define
  compile_opt idl2, hidden
  void = { stx_fsw_ivs_column_spc, $
    start_time            : 0,$
    end_time              : 0,$
    thermalboundary       : 10, $
    min_time              : 0.0d, $
    min_count_termal      : 0l, $
    min_count_nontermal   : 0l, $
    spectrogram           : ptr_new()}
end