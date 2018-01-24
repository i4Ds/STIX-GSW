; OSPEX script created Thu Apr 25 16:08:29 2013 by OSPEX writescript method.                
;                                                                                           
;  Call this script with the keyword argument, obj=obj to return the                        
;  OSPEX object reference for use at the command line as well as in the GUI.                
;  For example:                                                                             
;     ospex_script_event20021031_4F, obj=obj                                                
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
pro ospex_script_event20021031_4F, obj=obj                                                  
if not is_class(obj,'SPEX',/quiet) then obj = ospex()              
spex_specfile = loc_file('hsi_spectrum4F_20021031.fits', path=[getenv('IDL_WORKSPACE_PATH'), getenv('SSW')+'/so']+'/stix/idl/sim/ospex/sample_data/20021031')
spex_drmfile = loc_file('hsi_srm4F_20021031.fits', path=[getenv('IDL_WORKSPACE_PATH'), getenv('SSW')+'/so']+'/stix/idl/sim/ospex/sample_data/20021031')
obj-> set, spex_specfile=spex_specfile
obj-> set, spex_drmfile=spex_specfile                                                  
obj-> set, spex_source_angle= 90.0000                                                       
obj-> set, spex_source_xy= [859.102, 484.132]                                               
obj-> set, spex_fit_firstint_method= 'f7'                                                   
obj-> set, spex_fit_auto_erange= 1                                                          
obj-> set, spex_erange= [6.00000, 40.0000]                                                  
obj-> set, spex_fit_time_interval= [['31-Oct-2002 16:50:00.000', $                          
 '31-Oct-2002 16:50:20.000'], ['31-Oct-2002 16:50:20.000', '31-Oct-2002 16:50:40.000'], $   
 ['31-Oct-2002 16:50:40.000', '31-Oct-2002 16:51:00.000'], ['31-Oct-2002 16:51:00.000', $   
 '31-Oct-2002 16:51:20.000'], ['31-Oct-2002 16:51:20.000', '31-Oct-2002 16:51:40.000'], $   
 ['31-Oct-2002 16:51:40.000', '31-Oct-2002 16:52:00.000'], ['31-Oct-2002 16:52:00.000', $   
 '31-Oct-2002 16:52:20.000'], ['31-Oct-2002 16:52:20.000', '31-Oct-2002 16:52:40.000'], $   
 ['31-Oct-2002 16:52:40.000', '31-Oct-2002 16:53:00.000'], ['31-Oct-2002 16:53:00.000', $   
 '31-Oct-2002 16:53:20.000'], ['31-Oct-2002 16:53:20.000', '31-Oct-2002 16:53:40.000'], $   
 ['31-Oct-2002 16:53:40.000', '31-Oct-2002 16:54:00.000'], ['31-Oct-2002 16:54:00.000', $   
 '31-Oct-2002 16:54:20.000'], ['31-Oct-2002 16:54:20.000', '31-Oct-2002 16:54:40.000'], $   
 ['31-Oct-2002 16:54:40.000', '31-Oct-2002 16:55:00.000'], ['31-Oct-2002 16:55:00.000', $   
 '31-Oct-2002 16:55:20.000'], ['31-Oct-2002 16:55:20.000', '31-Oct-2002 16:55:40.000'], $   
 ['31-Oct-2002 16:55:40.000', '31-Oct-2002 16:56:00.000'], ['31-Oct-2002 16:56:00.000', $   
 '31-Oct-2002 16:56:20.000'], ['31-Oct-2002 16:56:20.000', '31-Oct-2002 16:56:40.000'], $   
 ['31-Oct-2002 16:56:40.000', '31-Oct-2002 16:57:00.000'], ['31-Oct-2002 16:57:00.000', $   
 '31-Oct-2002 16:57:20.000'], ['31-Oct-2002 16:57:20.000', '31-Oct-2002 16:57:40.000'], $   
 ['31-Oct-2002 16:57:40.000', '31-Oct-2002 16:58:00.000']]                                  
obj-> set, spex_bk_sep= 1                                                                   
obj-> set, spex_bk_eband=[[4.0000000D, 12.000000D], [12.000000D, 25.728001D], [25.728001D, $
 48.291000D], [48.291000D, 102.80600D], [102.80600D, 150.00000D]]                           
obj-> set, this_band=0, this_time=[['31-Oct-2002 16:38:20.000', $                           
 '31-Oct-2002 16:40:00.000'], ['31-Oct-2002 17:39:40.000', '31-Oct-2002 17:42:00.000']]     
obj-> set, this_band=1, this_time=[['31-Oct-2002 16:38:00.000', $                           
 '31-Oct-2002 16:40:00.000'], ['31-Oct-2002 17:40:00.000', '31-Oct-2002 17:42:00.000']]     
obj-> set, this_band=2, this_time=[['31-Oct-2002 16:38:00.000', $                           
 '31-Oct-2002 16:40:00.000'], ['31-Oct-2002 17:40:00.000', '31-Oct-2002 17:42:00.000']]     
obj-> set, this_band=3, this_time=[['31-Oct-2002 16:38:00.000', $                           
 '31-Oct-2002 16:40:00.000'], ['31-Oct-2002 17:39:20.000', '31-Oct-2002 17:42:00.000']]     
obj-> set, this_band=4, this_time=[['31-Oct-2002 16:38:00.000', $                           
 '31-Oct-2002 16:40:00.000'], ['31-Oct-2002 17:39:40.000', '31-Oct-2002 17:42:00.000']]     
obj-> set, fit_function= 'vth+bpow'                                                         
obj-> set, fit_comp_params= [0.839434, 1.61285, 1.00000, 0.000880724, 8.33275, 400.000, $   
 1.93000]                                                                                   
obj-> set, fit_comp_minima= [1.00000e-20, 0.500000, 0.0100000, 1.00000e-10, 1.70000, $      
 10.0000, 1.70000]                                                                          
obj-> set, fit_comp_maxima= [1.00000e+20, 8.00000, 10.0000, 1.00000e+10, 10.0000, 400.000, $
 10.0000]                                                                                   
obj-> set, fit_comp_free_mask= [1B, 1B, 0B, 1B, 1B, 1B, 1B]                                 
obj-> set, fit_comp_spectrum= ['full', '']                                                  
obj-> set, fit_comp_model= ['chianti', '']                                                  
obj-> set, spex_autoplot_photons= 1                                                         
obj-> set, spex_autoplot_units= 'Flux'                                                      
obj-> set, spex_fitcomp_plot_bk= 1                                                          
obj-> set, spex_fitcomp_plot_err= 1                                                         
obj-> set, spex_eband= [[4.0000000D, 12.000000D], [12.000000D, 25.728001D], [25.728001D, $  
 48.291000D], [48.291000D, 102.80600D], [102.80600D, 150.00000D]]                           
obj-> set, spex_tband= [['31-Oct-2002 16:38:00.000', '31-Oct-2002 16:54:00.000'], $         
 ['31-Oct-2002 16:54:00.000', '31-Oct-2002 17:10:00.000'], ['31-Oct-2002 17:10:00.000', $   
 '31-Oct-2002 17:26:00.000'], ['31-Oct-2002 17:26:00.000', '31-Oct-2002 17:42:00.000']]     
 restorefit = loc_file('ospex_results_event20021031_4F.fits', path=[getenv('IDL_WORKSPACE_PATH'), getenv('SSW')+'/so']+'/stix/idl/sim/ospex/sample_data/20021031')
 obj -> restorefit, file=restorefit           
end                                                                                         
