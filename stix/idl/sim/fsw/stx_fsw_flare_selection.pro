;+
; :description:
;    This procedure simulates the on board flare selection algo.
;    See https://www.dropbox.com/home/STIX/Instrument/Flight_Software/Algorithms/FSWflareSelector20130709.docx for more infos and nomenclature
;
; :categories:
;    STIX, on board algo
;   
; :parameters:
; 
;    flare_flag
;                     : in, type="byte(t)"
;                     the flare flag as output of the flare detection
;                     
;    cfl             : in, type="stx_"
;                     the coarse flare location data
;        
; 
function stx_fsw_flare_selection, fsw_flare_flag, fsw_cfl 
  
  flare_flag = fsw_flare_flag.flare_flag
  time = fsw_flare_flag.time_axis
  
  flare_flag_ex = [fix(0),flare_flag gt 0]
  edges = (flare_flag_ex-shift(flare_flag_ex,-1))[0:-2]
  
  start_idx = where(edges lt 0, start_count)
  end_idx = where(edges gt 0, end_count)
  
  flare_list = list()
  
  foreach start_pos, start_idx, idx do begin
    ;this flare has start and end
    if idx lt n_elements(end_idx) then begin
      
      f_start_time = time.time_start[start_pos]
      f_end_time = time.time_end[end_idx[idx]]
      
      cfl_start_idx = stx_time_value_locate(fsw_cfl.time_axis.time_start, f_start_time) 
      cfl_end_idx = stx_time_value_locate(fsw_cfl.time_axis.time_start, f_end_time)
      
      zloc = mean(fsw_cfl.x_pos[cfl_start_idx : cfl_end_idx], /nan) 
      yloc = mean(fsw_cfl.y_pos[cfl_start_idx : cfl_end_idx], /nan) 
      
      fe = stx_fsw_flare_list_entry(fstart=f_start_time, fend=f_end_time, fsbyte=1, ended=1b, yloc=yloc, zloc=zloc)
    endif else begin
    ;this flare started but not ended so fare  
      fe = stx_fsw_flare_list_entry(fstart=time.time_start[start_pos], fsbyte=1, ended=0b)
    endelse
      
    flare_list->add, fe
  endforeach
  
  
  return, flare_list
  
end