function stx_convert_fsw_archive_buffer_time_group_to_asw, archive_buffer_block, energy_axis=energy_axis, datasource=datasource
  default, energy_axis, stx_construct_energy_axis()
  default, datasource, "?"
  
  all_ab = list()
  triggers = list()
  foreach group, archive_buffer_block do begin
    all_ab->add, group.archive_buffer, /extract
    triggers->add, group.trigger
  endforeach


  spec = stx_fsw_compact_archive_buffer(all_ab->toarray(),start_time=stx_construct_time(),time_axis=time_axis)

  all_raw_pixel_data = list()

  dims = size(spec)
  for e = 0, dims[1]-1 do begin
    for t = 0, dims[4]-2 do begin
      rpd = stx_pixel_data()
      rpd.type             =  "stx_raw_pixel_data"
      rpd.time_range       = [time_axis.time_start[t], time_axis.time_end[t]]
      rpd.energy_range     = [energy_axis.low[e], energy_axis.high[e]]
      rpd.counts           = transpose(spec[e,*,*,t])
      rpd.datasource       = datasource
      all_raw_pixel_data->add, rpd
    endfor
  endfor

  
  
  pd = all_raw_pixel_data->toarray()
  td = triggers->toarray()
  
  if (size(td, /dim))[0] eq 1 and N_ELEMENTS(time_axis.duration) eq 2 then begin
    ;TODO: NH remove hack for archive buffers with obly one collumns from real TMTC
    ;td = reform(td)
    td = [td,td]
    pd_dum = pd
    pd_dum.time_range.value.time += 100
    pd=[pd,pd_dum]
     
  endif
  
  

  return, { pixel_data : pd, $
            triggers   : td, $
            spec       : spec, $
            time_axis  : time_axis }
      
 
end