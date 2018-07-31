;+
; :description:
;    Run through several scenarios with different flux levels applying a rate dependent energy shift to the simulated data for each one.
;    Each scenario is the same except for the flux levels - processing them as separate scenarios makes it easier to find IVS intervals
;    which are the same between the original and the energy shifted eventlists
;
; :categories:
;    demo
;
; :examples:
;    stx_scenario_rate_change_comparison_demo
;
; :history:
;    10-Oct-2017 - ECMD (Graz), initial release
;
;-
pro stx_scenario_rate_change_comparison_demo

  ; these levels correspond to 4700, 15000, 47000 and 150000 photons/s/cm in the specified scenario
  scenario_flux_levels = ['low', 'medium', 'moderate', 'high']
  
  ;loop through each scenario separately applying the energy shift and creating the comparison plots
  for i = 0, n_elements(scenario_flux_levels) - 1 do begin
  
    stx_scenario_rate_change_comparison, scenario_flux = scenario_flux_levels[i]
    
  endfor
  
end
