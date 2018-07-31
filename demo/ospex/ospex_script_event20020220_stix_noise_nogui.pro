; OSPEX script created Mon Apr  8 16:38:02 2013 by OSPEX writescript method.                
;                                                                                           
;  Call this script with the keyword argument, obj=obj to return the                        
;  OSPEX object reference for use at the command line as well as in the GUI.                
;  For example:                                                                             
;     ospex_script_event20020220_stix_noise_nogui, obj=obj                                         
;                                                                                           
;  Note that this script simply sets parameters in the OSPEX object as they                 
;  were when you wrote the script, and optionally restores fit results.                     
;  To make OSPEX do anything in this script, you need to add some action commands.          
;  For instance, the command                                                                
;     obj -> dofit, /all                                                                    
;  would tell OSPEX to do fits in all your fit time intervals.                              
;  See the OSPEX methods section in the OSPEX documentation at                              
;  http://hesperia.gsfc.nasa.gov/ssw/packages/spex/doc/ospex_explanation.htm                
;  for a complete list of methods and their arguments.                                      
;                                                                                           
pro ospex_script_event20020220_stix_noise_nogui, obj=obj                                           
if not is_class(obj,'SPEX',/quiet) then obj = ospex(/nogui)                                       
obj-> set, spex_fit_firstint_method= 's6'                                                   
obj-> set, spex_fit_auto_erange= 1                                                          
obj-> set, spex_erange= [6.00000, 20.0000]                                                  
obj-> set, spex_fit_time_interval= [['20-Feb-2002 11:04:12.000', $                          
 '20-Feb-2002 11:04:32.000'], ['20-Feb-2002 11:04:32.000', '20-Feb-2002 11:04:52.000'], $   
 ['20-Feb-2002 11:04:52.000', '20-Feb-2002 11:05:12.000'], ['20-Feb-2002 11:05:12.000', $   
 '20-Feb-2002 11:05:32.000'], ['20-Feb-2002 11:05:32.000', '20-Feb-2002 11:05:52.000'], $   
 ['20-Feb-2002 11:05:52.000', '20-Feb-2002 11:06:12.000'], ['20-Feb-2002 11:06:12.000', $   
 '20-Feb-2002 11:06:32.000'], ['20-Feb-2002 11:06:32.000', '20-Feb-2002 11:06:52.000'], $   
 ['20-Feb-2002 11:06:52.000', '20-Feb-2002 11:07:12.000'], ['20-Feb-2002 11:07:12.000', $   
 '20-Feb-2002 11:07:32.000'], ['20-Feb-2002 11:07:32.000', '20-Feb-2002 11:07:52.000'], $   
 ['20-Feb-2002 11:07:52.000', '20-Feb-2002 11:08:12.000'], ['20-Feb-2002 11:08:12.000', $   
 '20-Feb-2002 11:08:32.000'], ['20-Feb-2002 11:08:32.000', '20-Feb-2002 11:08:52.000'], $   
 ['20-Feb-2002 11:08:52.000', '20-Feb-2002 11:09:12.000'], ['20-Feb-2002 11:09:12.000', $   
 '20-Feb-2002 11:09:32.000'], ['20-Feb-2002 11:09:32.000', '20-Feb-2002 11:09:52.000'], $   
 ['20-Feb-2002 11:09:52.000', '20-Feb-2002 11:10:12.000'], ['20-Feb-2002 11:10:12.000', $   
 '20-Feb-2002 11:10:32.000'], ['20-Feb-2002 11:10:32.000', '20-Feb-2002 11:10:52.000'], $   
 ['20-Feb-2002 11:10:52.000', '20-Feb-2002 11:11:12.000'], ['20-Feb-2002 11:11:12.000', $   
 '20-Feb-2002 11:11:32.000'], ['20-Feb-2002 11:11:32.000', '20-Feb-2002 11:11:52.000'], $   
 ['20-Feb-2002 11:11:52.000', '20-Feb-2002 11:12:12.000'], ['20-Feb-2002 11:12:12.000', $   
 '20-Feb-2002 11:12:32.000'], ['20-Feb-2002 11:12:32.000', '20-Feb-2002 11:12:52.000'], $   
 ['20-Feb-2002 11:12:52.000', '20-Feb-2002 11:13:12.000'], ['20-Feb-2002 11:13:32.000', $   
 '20-Feb-2002 11:13:52.000'], ['20-Feb-2002 11:13:52.000', '20-Feb-2002 11:14:12.000'], $   
 ['20-Feb-2002 11:14:12.000', '20-Feb-2002 11:14:32.000'], ['20-Feb-2002 11:14:32.000', $   
 '20-Feb-2002 11:14:52.000'], ['20-Feb-2002 11:14:52.000', '20-Feb-2002 11:15:12.000']]     
obj-> set, spex_bk_sep= 1                                                                   
obj-> set, spex_bk_order=[0, 0, 0, 0, 0]                                                    
obj-> set, spex_bk_eband=[[4.00000, 12.0000], [12.0000, 25.7280], [25.7280, 48.2910], $     
 [48.2910, 102.806], [102.806, 150.000]]                                                    
obj-> set, this_band=0, this_time=['20-Feb-2002 11:04:12.000', '20-Feb-2002 11:04:13.000']  
obj-> set, this_band=1, this_time=['20-Feb-2002 11:04:12.000', '20-Feb-2002 11:04:13.000']  
obj-> set, this_band=2, this_time=['20-Feb-2002 11:04:12.000', '20-Feb-2002 11:04:13.000']  
obj-> set, this_band=3, this_time=['20-Feb-2002 11:04:12.000', '20-Feb-2002 11:04:13.000']  
obj-> set, this_band=4, this_time=['20-Feb-2002 11:04:12.000', '20-Feb-2002 11:04:13.000']  
obj-> set, fit_function= 'vth+bpow'                                                         
obj-> set, fit_comp_params= [0.0608211, 1.12513, 1.00000, 8.51496e-10, 3.76485, 51.1200, $  
 4.03700]                                                                                   
obj-> set, fit_comp_minima= [1.00000e-20, 0.500000, 0.0100000, 1.00000e-10, 1.70000, $      
 10.0000, 1.70000]                                                                          
obj-> set, fit_comp_maxima= [1.00000e+20, 8.00000, 10.0000, 1.00000e+10, 10.0000, 400.000, $
 10.0000]                                                                                   
obj-> set, fit_comp_free_mask= [1, 1, 0, 1, 1, 0, 0]                                        
obj-> set, fit_comp_spectrum= ['full', '']                                                  
obj-> set, fit_comp_model= ['chianti', '']                                                  
obj-> set, spex_autoplot_units= 'Flux'                                                      
obj-> set, spex_eband= [[4.00000, 12.0000], [12.0000, 25.7280], [25.7280, 48.2910], $       
 [48.2910, 102.806], [102.806, 150.000]]
restorefit = loc_file('ospex_results_20020220_stix_noise_nogui.fits', path=[getenv('IDL_WORKSPACE_PATH'), getenv('SSW')+'/so']+'/stix/idl/sim/ospex/sample_data/20020220')
obj -> restorefit, file=restorefit             
end                                                                                         
