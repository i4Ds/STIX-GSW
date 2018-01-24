;+
; :Description: Stx_construct_energy_axis is an energy axis structure constructor function
; :Params:
;   energy_edges - keyword, keV, floating point format
;   select - keyword, integer type, energy bins edges
; :History:
;   27-apr-2014 - richard.schwartz@nasa.gov, remove COMBINE keyword, added select
;   10-jun-2014 - richard.schwartz@nasa.gov, from n_bins-1 to n_bins in call to stx_energy_axis
;   22-jan-2017 - richard.schwartz@nasa.gov, default edges now referencing the current(?) database spreadsheet
;-
function stx_construct_energy_axis, energy_edges=energy_edges, select = select;, combine=combine

  ;default, energy_edges, [(findgen(16)+4),20d*(150/20)^(dindgen(16)/16),150]
  default, energy_edges, (stx_science_energy_channels()).edges_1 ;33 edges for 32 channels
  ;referencing the current(?) database spreadsheet
  
  default, select, indgen(33)
  
  ;if keyword_set(combine) then energy_edges = energy_edges[combine]
  
  energy_edges_used = energy_edges[select]
  n_bins = n_elements(energy_edges_used)
  
  energy_axis = stx_energy_axis(n_bins-1) ;from n_bins-1, ras, 10-jun-2014
  
  Edge_Products, energy_edges_used, MEAN=out_mean, $
    GMEAN=out_gmean, EDGES_2=out_edges, width = width, edges_1=edges_1 
  
  energy_axis.mean  = out_mean
  energy_axis.gmean = out_gmean
  energy_axis.low   = out_edges[0,*]
  energy_axis.high  = out_edges[1,*]
  energy_axis.width = width
  energy_axis.edges_1 = edges_1
  energy_axis.edges_2 = out_edges
  energy_axis.low_fsw_idx = select[0:-2] 
  energy_axis.high_fsw_idx = select[1:-1]-1
  return, energy_axis
  
end