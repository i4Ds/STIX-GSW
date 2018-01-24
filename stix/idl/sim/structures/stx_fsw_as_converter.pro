function stx_fsw_as_converter, stx_fsw_science_data

  
  if ~(isa(stx_fsw_science_data, 'LIST') || ppl_typeof(stx_fsw_science_data, compareto='stx_fsw_science_data', /raw)) then message, 'stx_fsw_science_data have to be of type "stx_fsw_science_data" or LIST'   
  
  all_as_data = list()
  
  entries = n_elements(stx_fsw_science_data)
  
  for i=0, entries-1 do begin
    flare_fsw_data = stx_fsw_science_data[i]
    if ~ppl_typeof(flare_fsw_data, compareto='stx_fsw_science_data') then continue
    as_data = {   type                : 'stx_as_science_data', $
                  start_time          : flare_fsw_data.start_time, $
                  flare_time          : flare_fsw_data.flare_time $
              }
    
    if tag_exist(flare_fsw_data, 'L0_ARCHIVE_BUFFER_GROUPED') then begin
         all_ab = list()
         energy_axis = stx_energy_axis()
         foreach groupe, flare_fsw_data.L0_ARCHIVE_BUFFER_GROUPED do all_ab->add, groupe.archive_buffer, /extract 
         PIXEL_COUNT_SPECTROGRAM = stx_fsw_compact_archive_buffer(all_ab->toArray(), start_time = flare_fsw_data.start_time)
         
         dim = size(PIXEL_COUNT_SPECTROGRAM)
         n_t = dim[4]
         n_e = dim[1]
         
         stx_raw_pixel_data = replicate(stx_pixel_data(), n_t*n_e)
         
         foreach groupe, flare_fsw_data.L0_ARCHIVE_BUFFER_GROUPED, index do begin
            idx = lindgen(n_e)+(n_e*index)
            stx_raw_pixel_data[idx].live_time = reproduce(reform(groupe.LIVETIME),32)
            stx_raw_pixel_data[idx].time_range = [groupe.start_time, groupe.end_time]
            stx_raw_pixel_data[idx].energy_range = energy_axis.edges_2
            stx_raw_pixel_data[idx].counts = reform(reform(PIXEL_COUNT_SPECTROGRAM[*,*,*,index],1,n_e,12,32))
            stx_raw_pixel_data[idx].attenuator_state = groupe.rcr
         end
         
         stx_raw_pixel_data.type = "stx_raw_pixel_data"
         as_data = add_tag(as_data,stx_raw_pixel_data, "stx_raw_pixel_data", /no_copy)
    endif
    
    if tag_exist(flare_fsw_data, 'L1_IMG_COMBINED_ARCHIVE_BUFFER_GROUPED') then begin
      as_data = add_tag(as_data, stx_construct_pixel_data(from_stx_fsw_pixel_data = flare_fsw_data.L1_IMG_COMBINED_ARCHIVE_BUFFER_GROUPED, time_range=flare_fsw_data.start_time), "stx_pixel_data", /no_copy)
    endif
    
    if tag_exist(flare_fsw_data, 'L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED') then begin
    endif
    
    if tag_exist(flare_fsw_data, 'L2_IMG_COMBINED_PIXEL_SUMS_GROUPED') then begin
    endif
    
    if tag_exist(flare_fsw_data, 'L3_IMG_COMBINED_VISIBILITY_GROUPED') then begin
    endif
    
    all_as_data->add, as_data
  end
    
  entries = n_elements(all_as_data)
  
  if entries eq 0 then return, []
  if entries eq 1 then return, all_as_data[0] 
  return, all_as_data 

end