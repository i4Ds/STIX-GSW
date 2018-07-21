function hsi_spec_counts, edg, srm, fmodel, apar

edg2 = get_edges(edg,/edges_2)
wdg  = get_edges(edg,/width)
ndg  = n_elements(wdg)
napar = [size( apar,/dim),1]
cnt = fltarr(ndg, napar[1])
for i=0,napar[1]-1 do cnt[0,i] = (srm #(call_function( fmodel, edg2, apar[*,i])*wdg))*wdg
return, cnt*(hessi_constant()).detector_area
end