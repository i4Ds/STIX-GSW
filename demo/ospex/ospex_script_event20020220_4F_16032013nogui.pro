; OSPEX script created Sat Mar 16 21:14:49 2013 by OSPEX writescript method.                
;                                                                                           
;  Call this script with the keyword argument, obj=obj to return the                        
;  OSPEX object reference for use at the command line as well as in the GUI.                
;  For example:                                                                             
;     ospex_script_event20020220_4F_16032013new, obj=obj                                    
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
pro ospex_script_event20020220_4F_16032013nogui, obj=obj                                      
if not is_class(obj,'SPEX',/quiet) then obj = ospex(/no_gui)                                       
spex_specfile = loc_file('hsi_spectrum4F_20020220_105500.fits', path=[getenv('IDL_WORKSPACE_PATH'), getenv('SSW')+'/so']+'/stix/idl/sim/ospex/sample_data/20020220')
spex_drmfile = loc_file('hsi_srm4F_20020220_105500.fits', path=[getenv('IDL_WORKSPACE_PATH'), getenv('SSW')+'/so']+'/stix/idl/sim/ospex/sample_data/20020220')                                  
obj-> set, spex_specfile=spex_specfile              
obj-> set, spex_drmfile=spex_specfile               
obj-> set, spex_source_angle= 80.2366                                                       
obj-> set, spex_source_xy= [910.869, 255.764]                                               
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
 ['20-Feb-2002 11:12:52.000', '20-Feb-2002 11:13:12.000'], ['20-Feb-2002 11:13:12.000', $   
 '20-Feb-2002 11:13:32.000'], ['20-Feb-2002 11:13:32.000', '20-Feb-2002 11:13:52.000'], $   
 ['20-Feb-2002 11:13:52.000', '20-Feb-2002 11:14:12.000'], ['20-Feb-2002 11:14:12.000', $   
 '20-Feb-2002 11:14:32.000'], ['20-Feb-2002 11:14:32.000', '20-Feb-2002 11:14:52.000'], $   
 ['20-Feb-2002 11:14:52.000', '20-Feb-2002 11:15:12.000']]                                  
obj-> set, spex_bk_sep= 1                                                                   
obj-> set, spex_bk_order=[0, 0, 1, 1, 2]                                                    
obj-> set, spex_bk_eband=[[4.0000000D, 12.000000D], [12.000000D, 25.728001D], [25.728001D, $
 48.291000D], [48.291000D, 102.80600D], [102.80600D, 150.00000D]]                           
obj-> set, this_band=0, this_time=[['20-Feb-2002 10:55:04.000', $                           
 '20-Feb-2002 10:57:28.000'], ['20-Feb-2002 11:19:20.000', '20-Feb-2002 11:22:36.000']]     
obj-> set, this_band=1, this_time=[['20-Feb-2002 10:55:04.000', $                           
 '20-Feb-2002 10:57:36.000'], ['20-Feb-2002 11:17:12.000', '20-Feb-2002 11:21:20.000']]     
obj-> set, this_band=2, this_time=[['20-Feb-2002 10:55:08.000', $                           
 '20-Feb-2002 10:57:00.000'], ['20-Feb-2002 11:01:00.000', '20-Feb-2002 11:03:28.000'], $   
 ['20-Feb-2002 11:17:12.000', '20-Feb-2002 11:21:30.000']]                                  
obj-> set, this_band=3, this_time=[['20-Feb-2002 11:00:52.000', $                           
 '20-Feb-2002 11:02:04.000'], ['20-Feb-2002 11:03:40.000', '20-Feb-2002 11:05:04.000'], $   
 ['20-Feb-2002 11:07:00.000', '20-Feb-2002 11:08:32.000']]                                  
obj-> set, this_band=4, this_time=[['20-Feb-2002 11:01:24.000', $                           
 '20-Feb-2002 11:02:20.000'], ['20-Feb-2002 11:04:28.000', '20-Feb-2002 11:05:44.000'], $   
 ['20-Feb-2002 11:07:04.000', '20-Feb-2002 11:08:00.000'], ['20-Feb-2002 11:10:44.000', $   
 '20-Feb-2002 11:12:24.000'], ['20-Feb-2002 11:15:00.000', '20-Feb-2002 11:16:32.000']]     
obj-> set, fit_function= 'vth+bpow'                                                         
obj-> set, fit_comp_params= [0.00803689, 1.34837, 1.00000, 3.61283e-08, 4.13625, 51.1200, $ 
 4.03700]                                                                                   
obj-> set, fit_comp_minima= [1.00000e-20, 0.500000, 0.0100000, 1.00000e-10, 1.70000, $      
 10.0000, 1.70000]                                                                          
obj-> set, fit_comp_maxima= [1.00000e+20, 8.00000, 10.0000, 1.00000e+10, 10.0000, 400.000, $
 10.0000]                                                                                   
obj-> set, fit_comp_free_mask= [1B, 1B, 0B, 1B, 1B, 0B, 0B]                                 
obj-> set, fit_comp_spectrum= ['full', '']                                                  
obj-> set, fit_comp_model= ['chianti', '']                                                  
obj-> set, spex_autoplot_units= 'Flux'                                                      
obj-> set, spex_fitcomp_plot_units= 'Flux'                                                  
obj-> set, spex_fitcomp_plot_bk= 1                                                          
obj-> set, spex_fitcomp_plot_err= 1                                                         
obj-> set, spex_fitcomp_plot_photons= 1                                                     
obj-> set, spex_eband= [[4.0000000D, 12.000000D], [12.000000D, 25.728001D], [25.728001D, $  
 48.291000D], [48.291000D, 102.80600D], [102.80600D, 150.00000D]]                           
obj-> set, spex_tband= [['20-Feb-2002 10:55:12.000', '20-Feb-2002 11:03:32.000'], $         
 ['20-Feb-2002 11:03:32.000', '20-Feb-2002 11:12:32.000'], ['20-Feb-2002 11:12:32.000', $   
 '20-Feb-2002 11:21:12.000'], ['20-Feb-2002 11:21:12.000', '20-Feb-2002 11:29:52.000']]
 restorefit = loc_file('ospex_results_20020220_4F_16032013new.fits', path=[getenv('IDL_WORKSPACE_PATH'), getenv('SSW')+'/so']+'/stix/idl/sim/ospex/sample_data/20020220')
 obj -> restorefit, file=restorefit
end                                                                                         
