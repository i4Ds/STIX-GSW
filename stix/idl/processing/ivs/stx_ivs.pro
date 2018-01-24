;---------------------------------------------------------------------------
; Document name: stx_is.pro
; Created by:    Nicky Hochmuth, 2012/03/05
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; PURPOSE:
;       Performes a interval selection to get a "good" number of "images" 
;       and depending on the time binning for immaging a time pinning for spectroscopy is created. 
;       An "image" is a time/erergy interval from the given spectrogram for which visibility data will be transmitted
;
; CATEGORY:
;       Stix on Bord Algorithm
;
; CALLING SEQUENCE:
;       intervals = stx_ivs(spectrogram)
;
; HISTORY:
;       2012/03/05, Nicky.Hochmuth@fhnw.ch, initial release
;       2013/06/15, Nicky.Hochmuth@fhnw.ch, add input from the 3. stix soft. colocation
;       2013/06/15, Nicky.Hochmuth@fhnw.ch, add input from the reviewed FSWimagingIntervalSelection20130716.doc (Revised 15.07.2013 gh)
;-
;+
; :description:
;     Performes a interval selection to get a "good" number of "images". 
;     and depending on the time binning for immaging a time pinning for spectroscopy is created. 
;     An "image" is a time/erergy interval from the given spectrogram for which visibility data will be transmitted
;
; :params:
;    spectrogram: a stx_spectrogram structure
;    
; :keywords:
;   thermalboundary_idx:  optional, in, type="int index"
;   overrides the thermalboundary
;    
;   min_time_img:   optional, in, type="double(thermal, nonthermal)" 
;   overrides the minimum time duration for an image split in the thermal or nonthermal energy band
;   
;   min_count_img:  optional, in, type="int[[thermal n1, nonthermal n1],[thermal n2, nonthermal n2]]" 
;   overrides the minimum count values n1 and n2 for an image split in the thermal and nonthermal energy band
;   
;   min_count_spc:  optional, in, type="int" 
;   overrides the minimum count for a spectroscopy column
;   
;   min_time_spc:   optional, in, type="double" 
;   overrides the minimum timeduration for a spectroscopy column
;   
;   plotting:        optional, in, type="flag[0|1]" 
;   do some plotting
;   
;   ps:             optional, in, type="flag[0|1]" 
;   enable postscript plotting
;   
;   hide_spectroscopy_intervals:  optional, in, type="flag[0|1]" 
;   hide all spectroscopy intervals in the plot
;   
;   hide_imaging_intervals:       optional, in, type="flag[0|1]" 
;   hide all imaging intervals in the plot  
;-
function stx_ivs, spectrogram,  $
      thermalboundary_idx=thermalboundary_idx, $
      min_time_img                          = min_time_img, $
      min_count_img                         = min_count_img, $
      min_count_spc                         = min_count_spc, $
      min_time_spc                          = min_time_spc, $
      thermal_boundary_lut                  = thermal_boundary_lut, $
      trimming_max_loss                     = trimming_max_loss, $
      plotting                              = plotting, $
      hide_spectroscopy_intervals           = hide_spectroscopy_intervals, $
      hide_imaging_intervals                = hide_imaging_intervals, $
      thermal_min_count_lut                 = thermal_min_count_lut, $
      nonthermal_min_count_lut              = nonthermal_min_count_lut, $
      total_flare_magnitude_index_lut       = total_flare_magnitude_index_lut, $
      thermal_flare_magnitude_index_lut     = thermal_flare_magnitude_index_lut, $
      nonthermal_flare_magnitude_index_lut  = nonthermal_flare_magnitude_index_lut, $
      energy_binning_lut                    = energy_binning_lut, $
      thermal_min_time_lut                  = thermal_min_time_lut, $
      nonthermal_min_time_lut               = nonthermal_min_time_lut, $
      ps                                    = ps
  
  default, hide_spectroscopy_intervals, 1b
  default, hide_imaging_intervals, 0b
  default, ps, 0
  default, plotting, 1
  default, trimming_max_loss, 0.05
  
  
  default, min_time_spc,          4.0; sec
  default, min_count_spc,         [800000,400000] ;[thermal,non_thermal] not corected detetcor counts over all pixel and detectors counts
  
  if ps then begin
      time = anytim(spectrogram.t_axis.time_start[0],/utc_ext)
      time_str = trim(time.year)+'_'+trim(time.month)+'_'+trim(time.day)
      psfile = 'stx_ivs_plot_' +time_str+"_"+strtrim(long(systime(/sec)),1)+'.ps';
      ;sps, /landscape 
      ps_on, FILENAME=psfile, /land;, MARGIN=margin, PAGE_SIZE =[xsize,ysize], /INCHES, /landscape
  endif
  
  
  if ~ppl_typeof(spectrogram, compareto='stx_spectrogram') then message, 'Parameter "spectrogram" has to be an "stx_spectrogram"!'
  
  n_t = n_elements(spectrogram.t_axis.time_start)
  
  
  ;Determine the total number of counts, Ntot, (64 bits) within this flare period
  Ntot = total(spectrogram.data,/integer)
  
  ;Determine a ‘total flare magnitude index’, 
  ;FMtot, to be used as an index for determining the division between thermal and non-thermal energies.
  FMtot = stx_ivs_get_flare_magnitude_index(Ntot, range = "total", total_flare_magnitude_index_lut = total_flare_magnitude_index_lut) 
  
  ;Use the flare magnitude index as an index to a 24-element TC-specified lookup table to
  ;determine the minimum science channel number to be considered as ‘nonthermal’.
  ;Channels below this value are considered themal’.
  
  thermalboundary_idx = keyword_set(thermalboundary_idx) ? thermalboundary_idx : stx_ivs_get_thermal_boundary(FMtot, thermal_boundary_lut=thermal_boundary_lut)
  
  all_bands = indgen(32)
  
  thermal_bands = all_bands[0:thermalboundary_idx] 
  nonthermal_bands = all_bands[thermalboundary_idx+1:*]
  
  ;Calculate the energy-summed counts, Nt and Nnt (64 bits) for thermal and nonthermal energy regimes for the entire flare.
  Nt  = total(spectrogram.data[thermal_bands,*],/integer)
  Nnt = total(spectrogram.data[nonthermal_bands,*],/integer)
  
  ;Determine a ‘thermal flare magnitude index’, FMt, and a nonthermal flare magnitude index, FMnt.
  FMt = stx_ivs_get_flare_magnitude_index(Nt, range = 'thermal', thermal_flare_magnitude_index_lut=thermal_flare_magnitude_index_lut)
  FMnt = stx_ivs_get_flare_magnitude_index(Nnt, range = 'nonthermal', nonthermal_flare_magnitude_index_lut=nonthermal_flare_magnitude_index_lut)
  
  ;get or override minimum counts and times
  if ~keyword_set(min_count_img) then begin
     thermal_min = stx_ivs_get_min_count(FMt, 1, thermal_min_count_lut = thermal_min_count_lut)
     non_thermal_min = stx_ivs_get_min_count(FMnt, 0, nonthermal_min_count_lut = nonthermal_min_count_lut)
     min_count_img = [transpose(thermal_min),transpose(non_thermal_min)]
  endif
  
  if ~keyword_set(min_time_img) then begin
     thermal_min = stx_ivs_get_min_time(FMt,1,thermal_min_time_lut=thermal_min_time_lut)
     non_thermal_min = stx_ivs_get_min_time(FMnt,0,nonthermal_min_time_lut=nonthermal_min_time_lut)
     min_time_img = [thermal_min,non_thermal_min]
  endif
  
  print, "","total","thermal","nonthermal",format="(A10,3A20)"
  print, "count",Ntot,Nt,Nnt, format="(A10,3I20)"
  print, "FM",FMtot,FMt,FMnt, format="(A10,3I20)"
  
  
  
  binning_t  = stx_ivs_get_energy_binning(FMt,1,energy_binning_lut = energy_binning_lut)
  binning_nt = stx_ivs_get_energy_binning(FMnt,0,energy_binning_lut = energy_binning_lut)
  
  ;merge both binnings 
  
  cut = where(binning_t[1,*] le thermalboundary_idx, n_cuts)
  if n_cuts eq 0 then cut=0
  
  binning_t_cut = binning_t[*,cut]
  binning_nt_cut = binning_nt[*,where(binning_nt[0,*] ge binning_t_cut[n_elements(binning_t_cut)-1])]
  merged_bins = [[binning_t_cut],[binning_nt_cut]]
  merged_edges = [reform(merged_bins[0,*]),merged_bins[1,n_elements(merged_bins[1,*])-1]]
  
  energy_axis = stx_construct_energy_axis(select=merged_edges)
  orig_axis = stx_construct_energy_axis()
  
  thermalboundary_orig = orig_axis.low[thermalboundary_idx]
  thermalboundary = orig_axis.low[binning_t_cut[n_elements(binning_t_cut)-1]]
    
  if plotting then begin
    thermal_axis = stx_construct_energy_axis(select=[reform(binning_t[0,*]),binning_t[1,-1]])
    nonthermal_axis = stx_construct_energy_axis(select=[reform(binning_nt[0,*]),binning_nt[1,-1]])
    
    
    if ~ps then window, 4
    plot, [1,1], xrange=[0,4], yrange=[4,150], xstyle=1, ystyle=9, /nodata, /ylog, XTICKS=3, XTICKV=[findgen(4)+0.5], $
      XTICKNAME=["Native","Thermal","Nonthermal","Merged"],xcharsize=0.7,title="Creation of the applied energy binning " 
    oplot, [0,3], make_array(2,value=thermalboundary_orig), linestyle=5, thick=3
    oplot, [3,5], make_array(2,value=thermalboundary), linestyle=5, thick=3
    
    xyouts,0,thermalboundary_orig+2," Thermal Boundary (keV): "+trim(thermalboundary_orig), charsize=1.5
    xyouts,3,thermalboundary+2," "+trim(thermalboundary), charsize=1.5
    
    xyouts,0.5,5,"FMtot: "+trim(fmtot),ORIENTATION=90 
    xyouts,1.5,5,"FMt  : "+trim(fmt),ORIENTATION=90
    xyouts,2.5,5,"FMnt : "+trim(fmnt),ORIENTATION=90
     
    ;plot native enery axis
    for i=0, n_elements(orig_axis.mean)-1 do rectangle, 0, orig_axis.low[i], 1,orig_axis.width[i]
    ;plot thermal enery axis
    for i=0, n_elements(thermal_axis.mean)-1 do rectangle, 1, thermal_axis.low[i], 1,thermal_axis.width[i]
    ;plot nonthermal enery axis
    for i=0, n_elements(nonthermal_axis.mean)-1 do rectangle, 2, nonthermal_axis.low[i], 1,nonthermal_axis.width[i]
    ;plot merged axis
    for i=0, n_elements(energy_axis.mean)-1 do rectangle, 3, energy_axis.low[i], 1,energy_axis.width[i]  
    
  end ;plot
  
  
  ;resample the energy_axis according the flare characteristic choosen axis 
  spectrogram_img = stx_resample_e_axis(spectrogram,energy_axis)
  
  
  
  spectrogram_img_p = ptr_new(spectrogram_img)
  spectrogram_p = ptr_new(spectrogram)
  
  ;create RCR blocks
  rcr_blocks = list()
  start_t = 0
  end_e = n_elements(spectrogram.e_axis.mean)-1
  
  attenuator_state = spectrogram.attenuator_state
  idx = where(attenuator_state gt 1, count)
  if count gt 0 then attenuator_state[idx]=1
  
  for t=0, n_t-1 do begin
    if (t eq n_t-1) || (attenuator_state[t] ne attenuator_state[t+1])  then begin
      ;found a new RSR block and create a stx_ivs_column object
      
      rcr_block = stx_ivs_column(start_t,t,indgen(n_elements(spectrogram_img.e_axis.mean)),spectrogram_img_p,$
      level = 0,thermalboundary=thermalboundary,min_time=min_time_img,min_count=min_count_img) 
      
      ;If the two highest energy channels each have the total number of counts less than N1nt,
      ;and if the sum of the two highest energy channels have a combined total number of
      ;counts greater than N1nt, then combine these two energy channels for all subsequent purposes
      ni_values = rcr_block->get_NiValues()
      zero_cells = where(ni_values eq 0, count_zero_cells)
      
      if count_zero_cells ge 2 then begin
        zero_cells = reverse(zero_cells[sort(zero_cells)])
         
        for i=1, count_zero_cells-1 do begin
          lovest_hight_0 = zero_cells[i]
          if lovest_hight_0 + 1 ne zero_cells[i-1] then break
        endfor
        
          if ni_values[lovest_hight_0] eq 0 && ni_values[lovest_hight_0+1] eq 0 then begin
            print, merged_edges
            void = where(indgen(n_elements(merged_edges)) eq lovest_hight_0+1,complement=merged_edges_rcr_idx)
            merged_edges_rcr = merged_edges[merged_edges_rcr_idx]
            print, merged_edges_rcr
            energy_axis_rcr = stx_construct_energy_axis(select=merged_edges_rcr)
            spectrogram_rcr = stx_resample_e_axis(spectrogram,energy_axis_rcr)
            ;replace the former bloch with a new one where the uper two ni0 rows are combined
            rcr_block = stx_ivs_column(start_t,t,indgen(n_elements(spectrogram_rcr.e_axis.mean)),ptr_new(spectrogram_rcr),$
              level = 0,thermalboundary=thermalboundary,min_time=min_time_img,min_count=min_count_img) 
          end 
      end
      
      rcr_blocks->add, rcr_block
      
      start_t=t+1
    end
  end
  
  if plotting then stx_interval_plot, spectrogram_img, thermalboundary=thermalboundary,ps=ps
  
  intervals = []
  
  all_split_times = make_array(n_elements(rcr_blocks), /ptr)
  
  ;do a interval selection on each RCR block
  foreach rcr,  rcr_blocks, rcr_idx do begin
    ;concat all found intervals to the result list
    split_times = []
    
    new_intervals = rcr->get_intervals(split_times = split_times)
    
    if n_elements(new_intervals) eq 0 then begin
      split_times = [0,rcr->get_starttime_idx()]
      times_splits = [rcr->get_starttime_idx(), rcr->get_endtime_idx()]
      new_intervals = rcr->get_dafault_intervals()
    end else begin
      if n_elements(split_times) eq 0 then begin
        split_times = [0,rcr->get_starttime_idx()]
        times_splits = [rcr->get_starttime_idx(), rcr->get_endtime_idx()]
      end else begin
        times_splits = [rcr->get_starttime_idx(), transpose(split_times[1,sort(split_times[1,*])])+1, rcr->get_endtime_idx()]
      end
    end
    
    times_splits = times_splits[uniq(times_splits)]
    
    ;find all trim candidates 
    trims =  where(new_intervals.trim gt 0, count_trims)   
    if (count_trims gt 0) && (trimming_max_loss gt 0) then begin
      for i=0, count_trims-1 do begin
       ;replace the trim candidate interval with the trimmed interval
       new_intervals[trims[i]] = stx_ivs_trim_interval(new_intervals[trims[i]],rcr->get_spectrogram(),times_splits, right=new_intervals[trims[i]].trim eq 2,max_loss=trimming_max_loss) 
      endfor
    endif
    
    intervals = [intervals,new_intervals]
    
    if ~hide_imaging_intervals && plotting then begin 
      stx_interval_plot, rcr->get_spectrogram(), /overplot, intervals=new_intervals, plot_energy_binning = stx_time2any((rcr->get_spectrogram()).t_axis.time_start[rcr->get_starttime_idx()])
    endif
    
    
    ;store all times splits for later plotting
    all_split_times[rcr_idx] = ptr_new(split_times)
        
    times_splits[-1]++    
    for t=0, n_elements(times_splits)-2 do begin
    
      spectroscopy_column = stx_ivs_column_spc(times_splits[t],times_splits[t+1]-1,spectrogram_p,min_count=min_count_spc,min_time=min_time_spc)
      
      new_intervals = spectroscopy_column->get_intervals()
      
;      if ~hide_spectroscopy_intervals && plotting then begin 
;        stx_interval_plot, spectrogram_img, /overplot, intervals=new_intervals
;      endif
      
      intervals = [intervals,new_intervals]
      
    endfor
  endforeach
  
  
  ;Time Split Tree RCR-Block Plott
;  if plotting then begin 
;    
;    for rcr_idx=0, rcr_blocks_count-1 do begin
;      if ~ps then window, 6+rcr_idx
;      split_times = *(all_split_times[rcr_idx])
;      n_rec_steps = max(split_times[0,*])+1
;      plot, [0],/nodata, xrange=[rcr_blocks[rcr_idx]->get_starttime_idx(),rcr_blocks[rcr_idx]->get_endtime_idx()] ,yrange=[0,n_rec_steps], YTicklen=1.0, YGridStyle=0, title="Time Split Tree RCR-Block: "+trim(rcr_idx), /xstyle, /ystyle, yticks=n_rec_steps
;      for i=0, n_elements(split_times[1,*])-1 do oplot, replicate(split_times[1,i],2) , [split_times[0,i],split_times[0,i]+1]
;    endfor 
;  endif
  
;  if interval_duplicates(intervals) gt 0 then begin
;    print, "finale duplicates found"
;  end
  
  img_cells = where(intervals.spectroscopy eq 0, n_img_cells, complement=spc_cells, ncomplement=n_spc_cells)
  
  print, n_img_cells, " img intervals created"
  print, n_spc_cells, " spc intervals created"
  
  if ps then ps_off
   
  return,  intervals
end