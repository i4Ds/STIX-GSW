function stx_fsw_get_timex_axis_from_archive_buffer, stx_fsw_archive_buffer, start_time = start_time, $
  time_edges_out = time_edges_out, add_timebin_dummy=add_timebin_dummy
  
  default, add_timebin_dummy, 1
  
  default, start_time, stx_time()
  
  ;create time axes
  time_edges = stx_time2any(stx_fsw_archive_buffer.RELATIVE_TIME_RANGE)
  time_edges = reform(time_edges, 2L * N_ELEMENTS(stx_fsw_archive_buffer))
  time_edges = time_edges[uniq(time_edges,sort(time_edges))]
  
  if add_timebin_dummy then begin
    ;dummy end bin for real TMTC
    time_edges = [time_edges, time_edges[-1]+0.1, time_edges[-1]+0.2]
  endif


  time_axis = stx_construct_time_axis(time_edges+stx_time2any(start_time))
  
  if ARG_PRESENT(time_edges_out) then time_edges_out = time_edges
  return, time_axis
end