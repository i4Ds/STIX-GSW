;Image Data Cube Generation from Independent Data Cube Rows
;We use existing RHESSI software for this demonstration because the necessary pieces haven't yet been
;built for STIX as we have been developing the FSW SIM for more than one year.  This demo and the
;code it calls should be viewed as a development model for STIX

                                           
pro hsi_image_script_rows, obj=obj                                                        
;     
im_time_interval= [['20-Feb-2002 11:05:54.996', '20-Feb-2002 11:06:06.372'], $
  ['20-Feb-2002 11:06:06.372', '20-Feb-2002 11:06:17.748'], ['20-Feb-2002 11:06:17.748', $
  '20-Feb-2002 11:06:32.470'], ['20-Feb-2002 11:06:32.470', '20-Feb-2002 11:06:47.192']]
energy_axis = [ 6., 12, 18, 25, 40, 100]     
if ~exist( im_time_intervali ) then begin
  im_time_intervali = ptrarr( 5, /all)
  *im_time_intervali[0] = im_time_interval
  *im_time_intervali[1] = im_time_interval
  *im_time_intervali[2] = im_time_interval
  *im_time_intervali[3] = im_time_interval ; [['20-Feb-2002 11:05:54.996',  '20-Feb-2002 11:06:17.748'], ['20-Feb-2002 11:06:17.748', '20-Feb-2002 11:06:47.192']]
  *im_time_intervali[4] = im_time_interval ;[['20-Feb-2002 11:05:54.996',  '20-Feb-2002 11:06:17.748'], ['20-Feb-2002 11:06:17.748', '20-Feb-2002 11:06:47.192']]
  
endif
obj = is_class(obj, 'hsi_image') ? obj : hsi_image()
obj-> set, det_index_mask= [0B, 0B, 1B, 1B, 1B, 1B, 1B, 1B, 0B]

obj-> set, image_algorithm= 'Clean'
obj-> set, modpat_skip= 4
obj-> set, pixel_size= [1.00000, 1.00000]
obj-> set, smoothing_time= 4.00000
obj-> set, time_bin_def= [1.00000, 1.00000, 2.00000, 4.00000, 8.00000, 16.0000, 16.0000, $
  32.0000, 64.0000]
obj-> set, time_bin_min= 512L
obj-> set, use_phz_stacker= 1L
obj-> set, clean_niter= 400
obj-> set, clean_show_maps= 0
obj-> set, clean_frac= 0.0200000
obj-> set, clean_progress_bar= 0
obj-> set, clean_regress_combine= 1
filename = 'hsi_imagecube_row_'
stime    = (time2file(obj->get(/obs_time),/sec))[0]
for i=0,4 do begin
  obj-> set, im_energy_binning= energy_axis[i:i+1]
  obj-> set, im_time_interval = *im_time_intervali[ i ]
  im_time_interval =  *im_time_intervali[ i ]
  senergy = arr2str( strtrim( fix( energy_axis[i:i+1]), 2 ), delim='_')
  out_filename = filename + strtrim( n_elements( im_time_interval[0,*] ), 2) +'tx1e_'+stime+'_'+ senergy+ '.fits'
  obj-> set, im_out_fits_filename = out_filename
  obj->fitswrite
  
endfor
                                                                                        
;            
end                                              
                                        
hsi_image_script_rows, obj=obj     
fs = file_search('hsi_imagecube_row_4tx1e_*.fits')
img_objs = objarr(5)
for i=0,4 do begin &$
  img_objs[i] = hsi_image( im_input_fits = fs[i] ) &$
  image_row = img_objs[i]->getdata() &$
  endfor
img_cube_obj = hsi_image_merge( img_objs )
hessi, img_cube_obj
end