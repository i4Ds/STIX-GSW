function stx_time_axis_sub, time_axis, start_idx, end_idx
  error = 0
  catch, error
  if (error ne 0)then begin
    catch, /cancel
    err = err_state()
    message, err, /cont
    return, 0
  endif
  
  ; Do some parameter checking
 
  if ~(ppl_typeof(time_axis,compareto='stx_time_axis')) then message, "Parameter 't_axis' must be a stx_time_axis structure"
 
  
  ; If all goes well, put the hsp_time_axis structure together and return it to caller
  str = { type       : 'stx_time_axis', $
          time       : time_axis.time[start_idx:end_idx], $
          starttime  : time_axis.starttime[start_idx:end_idx], $
          endtime    : time_axis.endtime[start_idx:end_idx], $
          duration   : time_axis.duration[start_idx:end_idx] }
    
  return, str
end