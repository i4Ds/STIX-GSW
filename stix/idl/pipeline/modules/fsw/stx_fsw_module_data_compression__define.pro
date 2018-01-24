;+
; :file_comments:
;    This module is part of the FLIGHT SOFTWARE (FSW) package and
;    will compact the archive buffer after the ivs
;    also additional meta data is linked to the data such as flare location and trigger counts
;
; :categories:
;    flight software, data compaction
;
; :examples:
;       fs = stx_fsw_module_data_compression()
; :history:
;    17-Sep-2014 - Nicky Hochmuth (FHNW), initial release
;    18-Nov-2014 - Nicky Hochmuth (FHNW), fixed mask reading using read_csv for IDL 8.3
;-

;+
; :description:
;    This internal routine transformes the archive buffer as fare as "max_compression_level" config parameter
;                        0: archive buffer grouped by time
;                        1: archive buffer grouped and summed according to ivs 12 pixels - finaly grouped by same start and endtime
;                        2: archive buffer grouped and summed according to ivs reduced to 4 pixels - finaly grouped by same start and endtime
;                        3: archive buffer grouped and summed according to ivs reduced to 4 pixels and transformed to visibilities and total counts - finaly grouped by same start and endtime
;
; :params:
;    in : in, required, type="defined in 'factory function'"
;        this is a stx_sim_source_structure object
;
;    configuration : in, required, type="stx_configuration_manager"
;        this is the configuration manager object containing the
;        configuration parameters for this module
;
; :returns:
;   this function returns a array of stx_fsw_pixel_data_summed
;   
;-
function stx_fsw_module_data_compression::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  n_time_groups = n_elements(in.archive_buffer_times) - 1
  
  ;groupe the archive buffer by time
  hist = histogram(value_locate(in.archive_buffer_times,in.ARCHIVE_BUFFER.relative_time_range[0]), REVERSE_INDICES = t_groups ) 
  
  Edge_Products,in.archive_buffer_times, EDGES_2=edges2
  edges_abs_time = stx_time_add(in.start_time, seconds=edges2)
  
  rcr_groupe = self._locateRCR(in.rcr, edges_abs_time[0,*], edges_abs_time[1,*])
  trigger_groupe = self._combinetriggers(in.triggers, reform(edges2[0,*]), reform(edges2[1,*]))
  cfl_groupe = self._combineCFL(in.cfl, edges_abs_time[0,*], edges_abs_time[1,*])
  
  ab_grouped = list()
  
  total_counts_eval = total(in.archive_buffer.counts, /integer)
  total_counts = total_counts_eval
  
  for i=0L, n_time_groups-1 do begin
      if t_groups[i] NE t_groups[i+1] then begin
        
        archive_buffer_column  = in.archive_buffer[t_groups[t_groups[i] : t_groups[i+1]-1]]
        start_time      = edges_abs_time[0,i]
        end_time        = edges_abs_time[1,i]
        
        total_counts -= total(archive_buffer_column.counts, /integer)
        
        ab_grouped->add, { type            : 'stx_fsw_archive_buffer_time_group', $
                          archive_buffer  : archive_buffer_column, $
                          start_time      : start_time, $
                          end_time        : end_time, $
                          rcr             : rcr_groupe[i], $
                          pixel_mask      : bytarr(12)+1b, $ 
                          detector_mask   : bytarr(32)+1b, $
                          trigger         : reform(trigger_groupe[i,*]), $
                          cfl             : cfl_groupe[i] $             
                        }, /no_copy
      endif
  endfor
  
  assert_equals, 0, total_counts, 'not all archive buffer entries are grouped well'
  
  ret_data = { type : "stx_fsw_science_data", $
            start_time                : in.start_time, $
            flare_time                : [in.flare_start, in.flare_end], $
            l0_archive_buffer_grouped : ab_grouped $
  }
  ;quit on thelevel of archive buffer
  if conf.MAX_COMPRESSION_LEVEL eq 0 then return, ret_data
  
  
  img_iv = in.ivs_intervals_img 
  n_img_iv = n_elements(img_iv)
  spc_iv = in.ivs_intervals_spc
  n_spc_iv =  n_elements(spc_iv)
  
  ;imaging intervals
  img_combined_archive_buffer = replicate(stx_fsw_pixel_data(),n_img_iv)
  
  ;set the relative time ranges
  img_combined_archive_buffer.RELATIVE_TIME_RANGE[0] = stx_time_diff(img_iv.start_time,in.start_time)
  img_combined_archive_buffer.RELATIVE_TIME_RANGE[1] = stx_time_diff(img_iv.end_time,in.start_time)
  
  ;set the energy science channel ranges
  img_combined_archive_buffer.ENERGY_SCIENCE_CHANNEL_RANGE[0] = img_iv.start_energy_idx
  ;todo n.h. check the + 1
  img_combined_archive_buffer.ENERGY_SCIENCE_CHANNEL_RANGE[1] = img_iv.end_energy_idx + 1
  
  ;spectroscopy intervals
  spc_combined_archive_buffer = replicate(stx_fsw_spc_data(),n_spc_iv)
  ;set the relative time ranges
  spc_combined_archive_buffer.RELATIVE_TIME_RANGE[0] = stx_time_diff(spc_iv.start_time,in.start_time)
  spc_combined_archive_buffer.RELATIVE_TIME_RANGE[1] = stx_time_diff(spc_iv.end_time,in.start_time)
  
  ;set the energy science channel ranges
  spc_combined_archive_buffer.ENERGY_SCIENCE_CHANNEL_RANGE[0] = spc_iv.start_energy_idx
  ;todo n.h. check the + 1
  spc_combined_archive_buffer.ENERGY_SCIENCE_CHANNEL_RANGE[1] = spc_iv.end_energy_idx + 1
  
  ;images
  for i=0L, n_img_iv-1 do begin
      iv = img_iv[i]
      summed_pixel = total(in.PIXEL_COUNT_SPECTROGRAM[iv.start_energy_idx:iv.end_energy_idx, *, *, iv.start_time_idx : iv.end_time_idx], /integer, 1)
      ;if many times
      if (size(summed_pixel))[0] eq 3 then summed_pixel = total(summed_pixel,3, /integer)
      img_combined_archive_buffer[i].counts = summed_pixel
  endfor
  
  ;spectrogram
  for i=0L, n_spc_iv-1 do begin
      iv = spc_iv[i]
      spc_combined_archive_buffer[i].counts = total(in.COUNT_SPECTROGRAM[iv.start_energy_idx:iv.end_energy_idx,iv.start_time_idx : iv.end_time_idx], /integer)
  endfor

  total_img_counts = total(img_combined_archive_buffer.counts, /integer )
  total_spc_counts = total(spc_combined_archive_buffer.counts,  /integer)
  print, "IMG count loos: ", total(in.PIXEL_COUNT_SPECTROGRAM,  /integer) - total_img_counts, total_img_counts
  print, "SPC count loos: ", total(in.COUNT_SPECTROGRAM,  /integer) - total_spc_counts, total_spc_counts
  
  ;groupe the combined image data into equal start<->end times
  sort_key = string(img_combined_archive_buffer.relative_time_range[0,*],format='(d32)')+string(img_combined_archive_buffer.relative_time_range[1,*],format='(d32)')
  sort_order = sort(sort_key)
  group_times = img_combined_archive_buffer[uniq(sort_key,sort_order)].RELATIVE_TIME_RANGE
  groups = sort_key[uniq(sort_key,sort_order)]
  
  ;does more than 1 time groupe exits
  n_time_groups = N_ELEMENTS(groups)
  if n_time_groups gt 1 then hist = histogram(value_locate(groups,sort_key), REVERSE_INDICES = t_groups ) 
    
  
  img_grouped = list()
 
  groupe_stx_times = stx_time_add(in.start_time, seconds=group_times)
  
  groupe_rcr = self->_locateRCR(in.rcr, groupe_stx_times[0,*], groupe_stx_times[1,*])
  trigger_groupe = self._combinetriggers(in.triggers, group_times[0,*], group_times[1,*])
  cfl_groupe = self._combineCFL(in.cfl, groupe_stx_times[0,*], groupe_stx_times[1,*])
    
  for i=0L, n_time_groups-1 do begin
        
        intervals    = n_time_groups gt 1 ? img_combined_archive_buffer[t_groups[t_groups[i] : t_groups[i+1]-1]] : img_combined_archive_buffer
        start_time   = groupe_stx_times[0,i]
        end_time     = groupe_stx_times[1,i]
        
        total_img_counts -= total(intervals.counts, /integer)
        
        ;todo: n.h. witch is the correct rcr for the entire interval?
        rcr = groupe_rcr[i]
        pixel_mask = rcr le 4 ? conf.L1_PIXEL_MASK_RCR_LOW : conf. L1_PIXEL_MASK_RCR_HIGH
        
        img_grouped->add, { type           : 'stx_fsw_pixel_data_time_group', $
                          intervals       : intervals, $
                          start_time      : start_time, $
                          end_time        : end_time, $
                          pixel_mask      : pixel_mask, $ 
                          detector_mask   : conf.L1_DETECTOR_MASK, $
                          rcr             : rcr ,$
                          trigger         : reform(trigger_groupe[i,*]), $
                          cfl             : cfl_groupe[i] $
                        }, /no_copy
  endfor
  
  assert_equals, 0, total_img_counts, 'not all archive buffer entries are grouped well'

  ;groupe the combined spectroscopy data into equal start<->end times
  sort_key = string(spc_combined_archive_buffer.relative_time_range[0,*],format='(d32)')+string(spc_combined_archive_buffer.relative_time_range[1,*],format='(d32)')
  sort_order = sort(sort_key)
  group_times = spc_combined_archive_buffer[uniq(sort_key,sort_order)].RELATIVE_TIME_RANGE
  groups = sort_key[uniq(sort_key,sort_order)]
  
  hist = histogram(value_locate(groups,sort_key), REVERSE_INDICES = t_groups ) 
  
  spc_grouped = list()
  groupe_stx_times = stx_time_add(in.start_time, seconds=group_times)
  
  groupe_rcr = self->_locateRCR(in.rcr, groupe_stx_times[0,*], groupe_stx_times[1,*])
  trigger_groupe = self._combinetriggers(in.triggers, group_times[0,*], group_times[1,*])
  cfl_groupe = self._combineCFL(in.cfl, groupe_stx_times[0,*], groupe_stx_times[1,*])
  
  total_counts = total_counts_eval
  
  for i=0L, n_elements(groups)-1 do begin
        
        intervals    = spc_combined_archive_buffer[t_groups[t_groups[i] : t_groups[i+1]-1]]
        start_time   = stx_time_add(in.start_time, seconds=intervals[0].relative_time_range[0]) 
        end_time     = stx_time_add(in.start_time, seconds=intervals[0].relative_time_range[1])      
        
        ;print, intervals.relative_time_range
        ;print, ""
        
        rcr = groupe_rcr[i]
        pixel_mask = rcr le 4 ? conf.L1_PIXEL_MASK_RCR_LOW : conf. L1_PIXEL_MASK_RCR_HIGH
        
        total_spc_counts -= total(intervals.counts, /integer)
        
       spc_grouped->add, { type            : 'stx_fsw_spc_data_time_group', $
                          intervals       : intervals, $
                          start_time      : start_time, $
                          end_time        : end_time, $
                          pixel_mask      : pixel_mask, $ 
                          detector_mask   : conf.L1_DETECTOR_MASK, $
                          rcr             : rcr ,$
                          trigger         : total(trigger_groupe[i,*]), $
                          cfl             : cfl_groupe[i] $
                        }, /no_copy
  endfor
  
  assert_equals, 0, total_spc_counts, 'not all archive buffer entries are grouped well'
  
  ret_data = add_tag(ret_data, img_grouped, 'l1_img_combined_archive_buffer_grouped', /no_copy)
  ret_data = add_tag(ret_data, spc_grouped, 'l1_spc_combined_archive_buffer_grouped', /no_copy)
  
  ;quit on the level of ivs combined archive buffer
  if conf.MAX_COMPRESSION_LEVEL eq 1 then return, ret_data
  
  
  ;read look up tables for summing and visgen
  self->update_io_data, conf
  
  img_sums_grouped = list()
  
  foreach img, ret_data.l1_img_combined_archive_buffer_grouped, i do begin
    ;copy the data group
    sum_img = img 
    sum_img.detector_mask   = conf.L2_DETECTOR_MASK
    sum_img.type = "stx_fsw_pixel_data_summed_time_group"
    sum_img = ppl_replace_tag(sum_img, "intervals", stx_pixel_sums(sum_img.intervals, (self.lut_data)["L2_sumcase_lut_file", sum_img.rcr],  /fsw))
    img_sums_grouped->add, sum_img, /no_copy
  endforeach
  
  ret_data = add_tag(ret_data, img_sums_grouped, 'l2_img_combined_pixel_sums_grouped', /no_copy)
  
  ;quit on the level of ivs combined archive buffer and summed pixel 
  if conf.MAX_COMPRESSION_LEVEL eq 2 then return, ret_data
  
  img_vis_grouped = list()
  
  foreach img, ret_data.l1_img_combined_archive_buffer_grouped, i do begin
    ;copy the data group
    vis_img = img 
    vis_img.detector_mask  = conf.L3_DETECTOR_MASK
    vis_img.type = "stx_fsw_visibility_time_group"
    
    rcr_lookup = value_locate((self.lut_data)["visgen_rcr_map"], vis_img.rcr)
    
    
    vis_img = ppl_replace_tag(vis_img, "intervals", stx_fsw_visgen(vis_img.intervals, $
                                                                    imag_neg = (self.lut_data)["visgen_imag_neg",*,rcr_lookup], $
                                                                    imag_pos = (self.lut_data)["visgen_imag_pos",*,rcr_lookup], $
                                                                    real_neg = (self.lut_data)["visgen_real_neg",*,rcr_lookup], $
                                                                    real_pos = (self.lut_data)["visgen_real_pos",*,rcr_lookup], $
                                                                    total_flux = (self.lut_data)["visgen_total_flux",*,rcr_lookup] ))
    
    img_vis_grouped->add, vis_img, /no_copy
  endforeach

  ret_data = add_tag(ret_data, img_vis_grouped, 'l3_img_combined_visibility_grouped', /no_copy)
  
  ;return all + visibilities
  return, ret_data
   
 
end

function stx_fsw_module_data_compression::_combineTriggers, ab_triggers, start_time, end_time
  if ~isa(end_time) then end_time=start_time
  
  n_entries = n_elements(start_time)
  combinedtriggers = ulon64arr(n_entries,16)
  for i=0L, n_entries-1 do begin
    
    found = where(ab_triggers.RELATIVE_TIME_RANGE[0] ge start_time[i] AND ab_triggers.RELATIVE_TIME_RANGE[1] le end_time[i], n_found)
    
    if n_found eq 0 then begin
      print, "error"
    endif
    
    combinedtriggers[i,*] = total(transpose(ab_triggers[found].triggers),1)
  endfor
  
  return, combinedtriggers
end

function stx_fsw_module_data_compression::_combineCFL, cfl, start_time, end_time
  if ~isa(end_time) then end_time=start_time
  
  group_start_idx = stx_time_value_locate(cfl.time_axis.time_start, start_time)
  group_end_idx = stx_time_value_locate(cfl.time_axis.time_start, end_time)
  
  n_entries = n_elements(group_end_idx)
  x_pos = fltarr(n_entries)
  y_pos = fltarr(n_entries)
  for i=0L, n_entries-1 do begin
    x_pos[i] = mean(cfl.x_pos[group_start_idx[i]:group_end_idx[i]],/nan)
    y_pos[i] = mean(cfl.y_pos[group_start_idx[i]:group_end_idx[i]],/nan)
  endfor
  
  ret_val = replicate({ x_pos : 0.0 , y_pos : 0.0}, n_entries) 
  
  ret_val.x_pos = x_pos
  ret_val.y_pos = y_pos
  
  return, ret_val
end

function stx_fsw_module_data_compression::_locateRCR, rcr, start_time, end_time
  if ~isa(end_time) then end_time=start_time
  
  rcr_group_start_idx = stx_time_value_locate(rcr.time_axis.time_start, start_time)
  rcr_group_end_idx = stx_time_value_locate(rcr.time_axis.time_end, end_time)
  
  rcr_group_start = rcr.rcr[rcr_group_start_idx]
  rcr_group_end = rcr.rcr[rcr_group_end_idx]
  
  rcr = rcr_group_start
  
  return, reform(rcr)
end


pro stx_fsw_module_data_compression::update_io_data, conf
    ;read the thermal boundary LUT
    
  if self->is_invalid_config("L2_sumcase_lut_file", conf.L2_sumcase_lut_file) then begin  
    L2_sumcase_lut_file = read_csv(exist(conf.L2_sumcase_lut_file) ? conf.L2_sumcase_lut_file : loc_file( 'stx_fsw_datacompression_sumcase.csv', path = getenv('STX_CONF') ), n_table_header=15)
    (self.lut_data)["L2_sumcase_lut_file"] = L2_sumcase_lut_file.FIELD2
  end
  
  if self->is_invalid_config("L3_visgen_lut_file", conf.L3_visgen_lut_file) then begin  
    L3_visgen_lut_file = read_csv(exist(conf.L3_visgen_lut_file) ? conf.L3_visgen_lut_file : loc_file( 'stx_fsw_datacompression_visgen.csv', path = getenv('STX_CONF') ), n_table_header=14)
    (self.lut_data)["visgen_rcr_map"] = L3_visgen_lut_file.FIELD1
    (self.lut_data)["visgen_total_flux"] = byte(byte(str_replace(L3_visgen_lut_file.FIELD2,"'",""))-48)
    (self.lut_data)["visgen_real_pos"] = byte(byte(str_replace(L3_visgen_lut_file.FIELD3,"'",""))-48)
    (self.lut_data)["visgen_real_neg"] = byte(byte(str_replace(L3_visgen_lut_file.FIELD4,"'",""))-48)
    (self.lut_data)["visgen_imag_pos"] = byte(byte(str_replace(L3_visgen_lut_file.FIELD5,"'",""))-48)
    (self.lut_data)["visgen_imag_neg"] = byte(byte(str_replace(L3_visgen_lut_file.FIELD6,"'",""))-48)
  end
end

;+
; :description:
;    Constructor
;
; :inherits:
;    hsp_module
;
; :hidden:
;-
pro stx_fsw_module_data_compression__define
  compile_opt idl2, hidden
  
  void = { stx_fsw_module_data_compression, $
    inherits ppl_module_lut }
end
