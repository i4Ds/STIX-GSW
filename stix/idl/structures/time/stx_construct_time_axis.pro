;+
; :Description: Stx_construct_time_axis is a time axis structure constructor function
; :Params:
;   time_edges - required, 1d times, unspecified format readable with stx_time2any (stx times and anytim)
;-
function stx_construct_time_axis, time_edges, time_axis=time_axis, idx=idx 
  
  if keyword_set(time_axis) && ppl_typeof(time_axis,compareto="stx_time_axis") && isa(idx, /array, /number)  then begin
    time_edges = [time_axis.time_start[idx], time_axis.time_end[idx]]
    time_edges_any = stx_time2any(time_edges)
    time_edges = time_edges[uniq(time_edges_any, sort(time_edges_any))]
  end
  
  n_times = n_elements(time_edges)-1
  
  time_axis             = stx_time_axis(n_times)
  time_axis.time_start  = stx_construct_time(time=time_edges[0:-2])
  time_axis.time_end    = stx_construct_time(time=time_edges[1:*])
  time_axis.mean        = stx_construct_time(time=mean([[stx_time2any(time_axis.time_end)],[stx_time2any(time_axis.time_start)]],DIMENSION=2))
  time_axis.duration    = stx_time_diff(time_axis.time_end,time_axis.time_start)
  
  return, time_axis
end

  
  