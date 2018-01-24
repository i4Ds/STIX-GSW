;stx_test_livetime, main program to build a testbest for the livetime computaton
;
triggergram = stx_triggergram_construction_4test( rate, duration = duration )
livetime_fraction = stx_livetime_fraction( triggergram,  det_select, tau_array = tau_array )
help, rate, duration
help, triggergram
help, triggergram, /st

help, det_select
print, det_select
help, tau_array

help, livetime_fraction
print, 'Min and Max rate and  Livetime_fraction
pmm, rate, livetime_fraction

rate2 = 10.0 * rate
triggergram = stx_triggergram_construction_4test( rate2, duration = duration )
livetime_fraction = stx_livetime_fraction( triggergram,  det_select, tau_array = tau_array )
print, 'Min and Max rate and  Livetime_fraction
pmm, rate2, livetime_fraction

rate3 = rate2 * 10.0
triggergram = stx_triggergram_construction_4test( rate3, duration = duration )
livetime_fraction = stx_livetime_fraction( triggergram,  det_select, tau_array = tau_array )
print, 'Min and Max rate and  Livetime_fraction
pmm, rate3, livetime_fraction

end