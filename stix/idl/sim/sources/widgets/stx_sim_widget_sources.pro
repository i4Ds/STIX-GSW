;+
; :description:
;     This program starts widget version of simulations
; 
; :modification history:
;     4-Jan-2013 - Tomek Mrozek (Wro), initial release
;-
pro stx_sim_widget_sources
  
  photons=stx_sim_widget_set_sources()
  
  print,'total number of photons = ',n_elements(photons)
  
end
