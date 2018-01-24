;+
; :description:
;    When two stix analysis software objects are passed the maps and visibilities for selected times and energies for each object are calculated and plotted
;    together for comparison
;
; :params:
; 
;    asw         : in, required, type='stx_analysis_software object'
;                  the analysis software object containing the imaging pixel data for the original simulated
;
;    asw_shifted : in, required, type='stx_analysis_software object'
;                   the analysis software object containing the imaging pixel data for the simulated data which has been shifted by a rate dependent energy offset
;
; :keywords:
;
;    times          : in, type='float array', default='(findgen(3)+1)*48/5.' i.e. [6.85, 13.71, 20.57, 27.42, 34.28]
;                     an array of times used to define the imaging intervals used for comparison
;
;   energies        : in, type='float array', default='findgen(5)*3 + 4.5' i.e. [9.6, 19.2, 28.8]
;                     an array of energies used to define the imaging intervals used for comparison
;
;   scenario_name   : in, type='float', default=''stx_scenario_rate_dept_' + scenario_flux + '_rate''
;                     the name of the scenario file to be processed
;
;   scenario_flux   : in, type='string', default='high'
;                     a short (e.g. 1 word) description of the scenario used for naming plots and telemetry files
;
;   img_algo        : in, type='string', default='clean'
;                     imaging algorithm used to make map plots
;
;
; :examples:
;    stx_plot_shifted_image_comparison, asw, asw_shifted, scenario_name = 'stx_scenario_rate_dept_'+scenario_flux+'_rate'
;
; :history:
;    10-Oct-2017 - ECMD (Graz), initial release
;
;-
pro stx_plot_shifted_image_comparison, asw, asw_shifted, times= times, energies = energies, scenario_flux = scenario_flux, $
    img_algo=img_algo, scenario_name = scenario_name
    
  if (~keyword_set(scenario_flux) and keyword_set(scenario_name)) then begin
    split_scenario_name = strsplit(scenario_name, '_' , /ex)
    sloc = where(strlowcase(split_scenario_name) eq 'scenario')
    scenario_flux = strjoin(split_scenario_name[sloc+1:-1], '_')
  endif
  
  default, scenario_flux,  'high'
  default, img_algo, 'clean'
  default, times, (findgen(3)+1)*48/5.
  default, energies, findgen(5)*3 + 4.5
  default, scenario_name, 'stx_scenario_rate_dept_' + scenario_flux + '_rate'
  
  asw->set, img_algo = img_algo
  asw_shifted->set, img_algo = img_algo
  comp_dir = concat_dir(scenario_name,'comp_plots')
  file_mkdir, comp_dir
  
  for i = 0,n_elements(times)-1 do begin
    for j  = 0,n_elements(energies)-1 do begin
    
      visibilities = asw->getdata(out_type='stx_visibility',time=stx_construct_time(time=times[i]), energy=energies[j], /reprocess)
      
      img = asw->getdata(out_type='stx_image', time=stx_construct_time(time=times[i]), energy=energies[j], /reprocess, skip_ivs=1)
      
      visibilities_shifted = asw_shifted->getdata(out_type='stx_visibility',time=stx_construct_time(time=times[i]), energy=energies[j], /reprocess)
      
      img_shifted = asw_shifted->getdata(out_type='stx_image', time=stx_construct_time(time=times[i]), energy=energies[j], /reprocess, skip_ivs=1)
      
      map = img.map
      map.id = 'Original Image'
      map.time = stx_time2any(img.time_range[0],/ecs)
      map.xunits += ' Duration: '+trim(stx_time_diff(img.time_range[1],img.time_range[0]))+'sec'
      map.yunits += ' Energy Range: '+trim(img.energy_range[0])+'-'+trim(img.energy_range[1])+'keV'
      
      
      map_shifted = img_shifted.map
      map_shifted.id = 'Shifted Image'
      map_shifted.time = stx_time2any(img.time_range[0],/ecs)
      map_shifted.xunits += ' Duration: ' + trim(stx_time_diff(img.time_range[1],img.time_range[0])) + 'sec'
      map_shifted.yunits += ' Energy Range: ' + trim(img.energy_range[0]) + '-' + trim(img.energy_range[1]) + 'keV'
      
      
      same_interval  = ( (stx_time_diff(img.time_range[0], img_shifted.time_range[0]) eq 0) and ((stx_time_diff(img.time_range[1], img_shifted.time_range[1]) eq 0)) $
        and (img.energy_range[0] eq img_shifted.energy_range[0]) and (img.energy_range[1] eq img_shifted.energy_range[1])) ? 1 : 0
        
        
      if ~same_interval then begin
      
        print, 'Intervals differ'
        print, 'Original interval'
        print, ' Energy Range: ', stx_time2any(img.time_range[0],/ecs) , ' - ',stx_time2any(img.time_range[1],/ecs)
        print, ' Energy Range: ' + trim(img.energy_range[0]) + '-' + trim(img.energy_range[1])+' keV'
        print, 'Shifted interval'
        print, ' Energy Range: ', stx_time2any(img_shifted.time_range[0],/ecs) , ' - ',stx_time2any(img_shifted.time_range[1],/ecs)
        print, ' Energy Range: ' + trim(img_shifted.energy_range[0]) + '-' + trim(img_shifted.energy_range[1])+' keV'
        
      endif
      
      imagefilename = 'Image_comaprison_' + scenario_flux + '_time_' + trim(times[i]) + '_energy_' + trim(long(energies[j])) + '.ps'
      visfilename   = 'Vis_difference_' + scenario_flux + '_time_' + trim(times[i]) +'_energy_' + trim(long(energies[j])) + '.ps'
      
      imagefilename =  filepath(imagefilename ,root_dir = comp_dir)
      visfilename   =  filepath(visfilename ,root_dir = comp_dir)
      
      loadct,3,/si
      tvlct,r,g,b, /get
      tvlct, reverse(r),reverse(g),reverse(b)
      
      colorbar = obj_new('colorbar2')
      
      set_plot,'ps'
      !p.multi   = [0,2,1]
      !P.Color   = 255
      !y.omargin = [2,4]
      
      device, filename = imagefilename, xsize=20, ysize=12, encapsulated=1,/color, /decomposed, bits_per_pixel=8
      
      plot_map, map, /limb, /true, bthick = 5, charthick = 3, charsize = 0.8
      !p.charthick = 2.5
      
      colorbar -> setproperty, position = [0.09,0.9,0.47,0.95], range = [min(map.data),max(map.data)], charsize = 0.45,ticklen = 0.1, color = 0
      colorbar->draw
      !p.charthick = 1.
      
      plot_map, map_shifted, /limb, /true, bthick = 5, charthick = 3, charsize = 0.8
      !p.charthick = 2.5
      
      colorbar -> setproperty, position = [0.59,0.9,0.97,0.95], range = [min(map_shifted.data),max(map_shifted.data)], charsize = 0.45,ticklen = 0.1, color = 0
      colorbar->draw
      !p.charthick = 1.
      device,/close
      
      !y.omargin = [0,0]
      !p.multi   = 0
      
      device, filename = visfilename, xsize=30, ysize=12, encapsulated=1, /color, /decomposed, bits_per_pixel = 8
      stx_plot_visibility_diff, visibilities, visibilities_shifted
      
      device,/close
      set_plot,'win'
      
    endfor
  endfor
  
end
