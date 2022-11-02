; OSPEX script created Fri Jul 26 17:52:17 2013 by OSPEX writescript method.             
;                                                                                        
;  Call this script with the keyword argument, obj=obj to return the                     
;  OSPEX object reference for use at the command line as well as in the GUI.             
;  For example:                                                                          
;     ospex_script_26_jul_2013, obj=obj                                                  
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
pro ospex_script_26_jul_2013, obj=obj, demo_input_dir = demo_input_dir                                                    
if not is_class(obj,'SPEX',/quiet) then obj = ospex()        
default, demo_input_dir, concat_dir( getenv('STX_DEMO_DATA'),'ospex/sample_data/20020220',/dir)                            
obj-> set, spex_specfile= file_search( demo_input_dir, 'hsi_spectrum_20020220_105020.fits')       
obj-> set, spex_drmfile= file_search( demo_input_dir, 'hsi_srm_20020220_105020.fits'  )           
obj-> set, spex_source_angle= 81.4157                                                    
obj-> set, spex_source_xy= [914.168, 255.662]                                            
obj-> set, spex_bk_time_interval=['20-Feb-2002 10:53:11.692', '20-Feb-2002 10:56:58.710']
obj-> set, spex_eband= [[3.00000, 6.00000], [6.00000, 12.0000], [12.0000, 25.0000], $    
 [25.0000, 50.0000], [50.0000, 100.000], [100.000, 300.000]]                             
obj-> set, spex_tband= [['20-Feb-2002 10:53:11.692', '20-Feb-2002 10:59:46.597'], $      
 ['20-Feb-2002 10:59:46.597', '20-Feb-2002 11:06:21.501'], ['20-Feb-2002 11:06:21.501', $
 '20-Feb-2002 11:12:56.406'], ['20-Feb-2002 11:12:56.406', '20-Feb-2002 11:19:31.311']]  
end                                                                                      
