;---------------------------------------------------------------------------
; Document name: stx_ivs_column_spc__define.pro
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
;       obj = stx_ivs_column_spc(start_time, end_time, rows, spectrogram)
;       intervals = obj->get_intervals()
;
; HISTORY:
;       2012/03/05, Nicky.Hochmuth@fhnw.ch, initial release
;
;-

;+
; :DESCRIPTION:
;    Initializes the stx_ivs_column_spc object
;    
; :PARAMS:
;   start_time: the index on the time axis of the spectrogram the column starts
;   end_time: the index on the time axis of the spectrogram the column ends
;   rows: an array of all indexes on the energy axis this column is created for
;   spectrogram: a pointer to the spectrogram
;
; :AUTHOR: nicky.hochmuth
;-
function stx_ivs_column_spc::init, start_time, end_time, spectrogram,thermalboundary,min_time,min_count
   
   ;do some parameter testing
   if ~ppl_typeof(spectrogram, compareto='pointer') then begin
    message, 'Spectrogram has to by a pointer', /continue
    return, 0
   end
   
   self.thermalboundary    = thermalboundary
   self.min_time          = min_time
   self.min_count         = min_count
   
   self.start_time = start_time
   self.end_time = end_time
      
   self.spectrogram = spectrogram
   
  return, 1
end

;+
; :description:
;    Cleanup of this class
;-
pro stx_ivs_column_spc::cleanup
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
function stx_ivs_column_spc::get_intervals
  
  
   split_time = self->getbarycenter()
  
  if split_time+1 lt self.end_time then begin
      ;split the column into two halves and get the intervals of each side recursive
        
      left = stx_ivs_column_spc(self.start_time,split_time, self.spectrogram,thermalboundary=self.thermalboundary,min_time=self.min_time,min_count=self.min_count)
      right = stx_ivs_column_spc(split_time+1,self.end_time, self.spectrogram,thermalboundary=self.thermalboundary,min_time=self.min_time,min_count=self.min_count)
      
      if left.is_valid() && right.is_valid() then begin
      
        intervals_left = left->get_intervals()
        intervals_right = right->get_intervals()
        ;concat the left and right intervals to the interval list
        return, [intervals_left,intervals_right]
      end
  endif ;split excists
  
  ;transform the start and end index to time values 
  start_time = (*self.spectrogram).t_axis.time_start[self.start_time] 
  end_time = (*self.spectrogram).t_axis.time_end[self.end_time]
   
  intervals = []
   
  row_idx = 0
  
  n_rows = n_elements((*self.spectrogram).e_axis.mean)
  
  ;go thru each cell and create a time_energy_bin for spectroscopy
  for row_idx=0, n_rows-1 do begin
    intervals = [intervals, stx_construct_ivs_interval(start_time, end_time, $
                                                       start_time_idx=self.start_time, end_time_idx=self.end_time, $
                                                       (*self.spectrogram).e_axis.low[row_idx] ,(*self.spectrogram).e_axis.high[row_idx], $
                                                       start_energy_idx=(*self.spectrogram).e_axis.LOW_FSW_IDX[row_idx], end_energy_idx=(*self.spectrogram).e_axis.HIGH_FSW_IDX[row_idx], $
                                                       total((*self.spectrogram).data[row_idx, self.start_time:self.end_time]),spectroscopy=1)]
  end
  
  return,   intervals
end


function stx_ivs_column_spc::getbarycenter
      
      split_time = self.start_time
      collumn_mass = total((*self.spectrogram).data[*, self.start_time:self.end_time], self.end_time gt self.start_time ? 2 : 1) 
      total_mass = total(collumn_mass)
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

function stx_ivs_column_spc::is_valid
   
  
  start_time = (*self.spectrogram).t_axis.time_start[self.start_time] 
  end_time = (*self.spectrogram).t_axis.time_end[self.end_time]
  
  if stx_time_diff(start_time,end_time) lt self.min_time then return, 0
  
  thermal_bands = where(*(self.spectrogram).e_axis.mean lt self.thermalboundary,complement=nonthermal_bands)
  
  thermal_counts = total(*(self.spectrogram).data[thermal_bands, *],/integer)
  nonthermal_counts = total(*(self.spectrogram).data[nonthermal_bands, *],/integer)
  
  return, thermal_counts gt self.min_count[0] || nonthermal_counts gt self.min_count[1]

end


;+
; :description:
;    Constructor
;
; :hidden:
;-
pro stx_ivs_column_spc__define
   compile_opt idl2, hidden
   void = { stx_ivs_column_spc, $
            start_time        : 0,$
            end_time          : 0,$
            thermalboundary    : 25.0, $
            min_time          : 0.0, $
            min_count         : [0l,0l], $
            spectrogram       : ptr_new()}
end