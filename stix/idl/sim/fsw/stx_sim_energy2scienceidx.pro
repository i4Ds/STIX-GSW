function stx_sim_energy2scienceidx, energy
  e_axis = stx_construct_energy_axis()
  
  low = value_locate(e_axis.low,energy)
  e_axis.high[-1]+=0.001
  high = value_locate(e_axis.high,energy)
  
  low--
    
  bad_idx = where(low ne high , count_bad)
  
  high++
  if count_bad gt 0 then high[bad_idx] = -1
  
  ;print, [[e_axis.low[high]], [energy], [e_axis.high[high]]] 
   
  return, high
  
end 
 