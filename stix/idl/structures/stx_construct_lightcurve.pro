function stx_construct_lightcurve, from=from
    
    
  if ppl_typeof(from, compareto='stx_fsw_ql_lightcurve') then begin
      dim = size(from.accumulated_counts, /dimensions)
      
      if(n_elements(dim) eq 2) then begin
        lc = stx_lightcurve(dim[0], dim[1])
        lc.data = from.accumulated_counts
      end else begin
        lc = stx_lightcurve(dim[0], 1)
        lc.data = from.accumulated_counts[*,0,0,*]
      end
      
      lc.unit = "total detector counts"
      lc.energy_axis = from.energy_axis
      lc.time_axis = from.time_axis
   end
   
   if ppl_typeof(from, compareto='stx_asw_ql_lightcurve') then begin
     dim = size(from.counts, /dimensions)

     lc = stx_lightcurve(dim[0], dim[1])
     lc.data = from.counts
 
     lc.unit = "total detector counts"
     lc.energy_axis = from.energy_axis
     lc.time_axis = from.time_axis
   end
   
   if ppl_typeof(from, compareto='stx_asw_ql_background_monitor') then begin
     dim = size(from.BACKGROUND, /dimensions)

     lc = stx_lightcurve(dim[0], dim[1])
     lc.data = from.BACKGROUND

     lc.unit = "background avg rate / s / detector"
     lc.energy_axis = from.energy_axis
     lc.time_axis = from.time_axis
   end
   
   
   
   if ppl_typeof(from, compareto='stx_fsw_m_background') then begin
     dim = size(from.BACKGROUND, /dimensions)
     
     if(n_elements(dim) gt 1) then begin
       lc = stx_lightcurve(dim[0], dim[1])
       lc.data = from.BACKGROUND
     end else begin
       lc = stx_lightcurve(dim[0], 1)
       lc.data = from.BACKGROUND
     end
     
     
     lc.unit = "background avg rate / s / detector"
     ;lc.energy_axis = from.energy_axis
     lc.time_axis = from.time_axis
   end
    
   ;legacy old fsw format
   if ppl_typeof(from, compareto='stx_fsw_result_background') then begin
      dim = size(from.data, /dimensions)

      lc = stx_lightcurve(dim[1], dim[0])
      lc.unit = "background avg rate / s / detector"
      lc.data = transpose(from.data)
      lc.energy_axis = from.energy_axis
      lc.time_axis = from.time_axis
    end
  
  return, lc
end