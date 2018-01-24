function stx_fsw_ivs_spc, spectrogram, time_splits, $
  min_count=min_count, min_time=min_time, thermalboundary=thermalboundary, plotting=plotting
  
 default, min_time, 4.0; sec
 default, min_count, [400L,400] ; [thermal, nonthermal] not corected detetcor counts over all pixel and detectors counts
 default, thermalboundary, 10

  intervals = list()
  
  spectrogram_p = ptr_new(spectrogram)
  
  for t=0, n_elements(time_splits)-2 do begin

    spectroscopy_column = stx_fsw_ivs_column_spc(time_splits[t], time_splits[t+1]-1, spectrogram_p,thermalboundary=thermalboundary, min_count=min_count, min_time=min_time)

    new_intervals = spectroscopy_column->get_intervals()

    intervals->add,  new_intervals, /extract

  endfor
  
  intervals = intervals->toarray()
  
  if plotting then begin
    stx_interval_plot, spectrogram, intervals=intervals
  endif
  
  return, { type              : "stx_fsw_ivs_spc_result" ,$
    intervals         : intervals $
  }
  
end