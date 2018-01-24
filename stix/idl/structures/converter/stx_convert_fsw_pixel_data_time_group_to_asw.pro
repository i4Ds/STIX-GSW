function stx_convert_fsw_pixel_data_time_group_to_asw, image_block, energy_axis=energy_axis, datasource=datasource
  default, energy_axis, stx_construct_energy_axis()
  default, datasource, "?"
      
  all_pixel_data = list()

  foreach group, image_block do begin
    foreach iv, group.intervals do begin
      pd = stx_pixel_data()

      pd.time_range       = [group.start_time, group.end_time]
      pd.energy_range     = [energy_axis.low[iv.energy_science_channel_range[0]], energy_axis.high[iv.energy_science_channel_range[1]-1]]
      pd.counts           = transpose(iv.counts)
      pd.live_time        = group.trigger
      pd.rcr              = group.rcr
      pd.datasource       = datasource
      all_pixel_data->add, pd
    endforeach
  endforeach

  return, all_pixel_data->toarray()

end