function stx_convert_fsw_visibility_time_group_to_asw, image_block, subc_str, energy_axis=energy_axis, datasource=datasource
  default, energy_axis, stx_construct_energy_axis()
  default, datasource, "?"
  
  
  all_vis_data = list()
  
 
  foreach group, image_block do begin
    time_range = [group.start_time, group.end_time]

    ;get the phase sense for each found detector
    phase_sense = subc_str[where(group.detector_mask)].phase
    
    foreach iv, group.intervals do begin
      energy_range = [energy_axis.low[iv.energy_science_channel_range[0]], energy_axis.high[iv.energy_science_channel_range[1]-1]]
      viscomp = complex(iv.vis.real_part, iv.vis.imag_part)
      
      
      vis_bag_in = { $
          type          : "stx_visibility_bag", $
          vis           : viscomp, $
          time_range    : time_range, $
          energy_range  : energy_range, $
          total_flux     : iv.vis.total_flux $
      }
      
      visibility = stx_visgen(vis_bag_in, subc_str)
      
      bag = {$
        type          : "stx_visibility_bag", $
        time_range    : time_range, $
        energy_range  : energy_range , $
        datasource    : datasource, $
        visibility    : visibility $
      }
      all_vis_data->add, bag

    endforeach
  endforeach

  return, all_vis_data->toarray()

end