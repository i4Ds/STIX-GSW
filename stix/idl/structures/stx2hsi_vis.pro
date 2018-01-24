function stx2hsi_vis,  vis
;Convert stx visibility container to rhessi format for use in rhessi-like vis routines

hsi_vis =  is_struct( vis ) && tag_exist( vis, 'type' ) && (vis[0].type eq 'stx_visibility_bag')  ?  vis.visibility : vis
;
;Add erange and trange based on energy_range and time_range to make the form acceptable to vis_fwdfit based on RHESSI visibility format
hsi_vis = rep_tag_name( hsi_vis, 'energy_range', 'erange')
hsi_vis = add_tag( hsi_vis, anytim( hsi_vis.time_range.value ), 'trange')
hsi_vis = rem_tag( hsi_vis, 'time_range' )
return, hsi_vis
end