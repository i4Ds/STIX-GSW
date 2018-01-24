;+
; :description:
;    This routine pulls out a simulation scenario and generates sources and a backround
;    source to simulate
;
; :categories:
;    simulation, source
;
; :keywords:
;    scenario_name : in, optional, type='string', default='stx_scenario_1'
;      the name of the scenario file w/o the CSV file ending
;    scenario_file : in, optional, type='string'
;      a file path to a scenario
;    out_bkg_str : out, optional, type='stx_sim_source'
;      a stx_sim_source structure containing the background information
;    out_scenario_file : out, optional, type='string'
;      the file path and name of the selected scenario
;      
; :returns:
;    a flat array of stx_sim_source structures required to simulate the complete scenario
;
; :examples:
;    sources = stx_sim_read_scenario(out_bkg_str=out_bkg_str)
;
; :history:
;    30-Jul-2014 - Laszlo I. Etesi (FHNW), initial release
;    05-Sep-2014 - Laszlo I. Etesi (FHNW), added out parameter out_scenario_file
;    04-Dec-2014 - Laszlo I. Etesi (FHNW), allowing for multiple backgrounds; NB: background source start times are ABSOLUT
;    05-Dec-2014 - Sophie Musset (LESIA), bug fix when extracting virtual sources
;    05-Dec-2014 - Laszlo I. Etesi (FHNW), - added scenario_file keyword
;                                          - reading background effective area multiplier array
;    22-Jan-2014 - Laszlo I. Etesi (FHNW), only setting a default value for the scenario name if neither name or file is present
;    11-Feb-2015 - Laszlo I. Etesi (FHNW), replaced complicated regex expression with file_basename
;    27-Feb-2015 - Laszlo I. Etesi (FHNW), - informing the user if a background source with flux 0 is loaded
;                                          - allowing the user to specify NO background at all
;    06-Mar-2015 - Laszlo I. Etesi (FHNW), bugfix: adjusted counter after change to stx_sim_source (found and fixed by Roman Boutellier (FHNW))                              
;    06-Mar-2015 - Shaun Bloomfield (TCD), fixed bugfix, so that new columns in stx_scenario_*.csv won't need new bugfixes
;    
; :todo:
;    30-Jul-2014 - Laszlo I. Etesi (FHNW), may need to be changed to only contain physical sources
;                                          which will be split up automaticall into virtual sources (hidden away from the user)
;-
function stx_sim_read_scenario, scenario_name=scenario_name, scenario_file=scenario_file, out_bkg_str=out_bkg_str
  if(~ppl_typeof(scenario_file, compareto='string')) then default, scenario_name, 'stx_scenario_1'
  
  ; only allow one of the two: scenario file or name
  if(ppl_typeof(scenario_name, compareto='string') && ppl_typeof(scenario_file, compareto='string')) then message, 'Please only specify a scenario name or a scenario file'
  if(~ppl_typeof(scenario_name, compareto='string') && ~ppl_typeof(scenario_file, compareto='string')) then message, 'Please specify exactly one: scenario name or a scenario file'
  
  ; get the scenario csv
  if(isvalid(scenario_file)) then begin
    scenario_name = file_basename(scenario_file, '.csv')
  endif else begin
    scenario_file = concat_dir(concat_dir(getenv('STX_SIM'), 'scenarios'), scenario_name + '.csv')
  endelse
  
  if(~file_exist(scenario_file)) then message, 'Invalid scenario name: ' + scenario_name
  
  ; read the scenario in and crudly check for validity
  scenario_str = read_csv(scenario_file, header=header, count=no_srcs)
  header = strlowcase(header)
  src_id_index = where(header eq 'source_id')
  src_sub_id_index = where(header eq 'source_sub_id')
  src_start_time_index = where(header eq 'start_time')
  src_duration_index = where(header eq 'duration')
  
  if(src_sub_id_index eq -1) then message, 'Invalid scenario file: ' + scenario_name
  
  ; extract background sources
  bkg_src_idx = where(scenario_str.(src_id_index) eq 0, bkg_src_count)
  
  ; extract the number of physical and virtual sources
  physical_src_idx = where(scenario_str.(src_sub_id_index) eq 0 and scenario_str.(src_id_index) gt 0, physical_src_count)
  
  ; extract the virtual sources
  virtual_src_idx = where(scenario_str.(src_id_index) gt 0 and scenario_str.(src_sub_id_index) ne 0, virtual_src_count)
  
  ; virtual sources are actually made into a source structure
  if(virtual_src_count gt 0) then virtual_srcs = replicate(stx_sim_source_structure(), virtual_src_count)
  
  ; extract the tags to fill; base this on the stx_sim_source structure
  vsrc_tag_names = strlowcase(tag_names(stx_sim_source_structure()))
  
  ; lookup background information and set the structure up if available
  if(bkg_src_count gt 0) then out_bkg_str = replicate(stx_sim_source_structure(), bkg_src_count)
  
  ; identify special tag 'background_multiplier'
  is_background_multiplier = stregex(header, 'background_multiplier(_[0-9]*)?', /boolean)
  background_multiplier_count = fix(total(is_background_multiplier))
  
  ; loop over all structure tags and fill in data
  for tag_idx = 0L, n_elements(header)-1 do begin
    tag_idx_vsrc = where(vsrc_tag_names eq header[tag_idx]) 
    ;if(tag_idx_vsrc eq -1) then continue
    
    if(~is_background_multiplier[tag_idx] && virtual_src_count gt 0) then virtual_srcs.(tag_idx_vsrc) = (scenario_str.(tag_idx))[virtual_src_idx]
    
    if(bkg_src_count gt 0) then  begin
      if(is_background_multiplier[tag_idx]) then begin
        for bgm_idx = tag_idx, tag_idx+background_multiplier_count-1 do begin
          (out_bkg_str.(tag_idx_vsrc)[bgm_idx-tag_idx]) = (scenario_str.(bgm_idx))[bkg_src_idx]
        endfor 
        tag_idx = bgm_idx - 1
      endif else out_bkg_str.(tag_idx_vsrc) = (scenario_str.(tag_idx))[bkg_src_idx]
    endif
  endfor
  
  ; loop over all structures and adjust start_time
  for psrc_idx = 0L, physical_src_count-1 do begin
    curr_phys_src_id = (scenario_str.(src_id_index))[physical_src_idx[psrc_idx]]
    
    if(curr_phys_src_id eq 0) then continue
    
    curr_phys_src_start_time = (scenario_str.(src_start_time_index))[physical_src_idx[psrc_idx]]
    
    srcs_idx = where(virtual_srcs.source_id eq curr_phys_src_id)

    cumul_durations = [0, total(virtual_srcs[srcs_idx].duration, /cumulative)] + curr_phys_src_start_time
    virtual_srcs[srcs_idx].start_time = cumul_durations[0:n_elements(cumul_durations)-2]
  endfor
  
  if(isvalid(out_bkg_str) && total(where(out_bkg_str.flux le 0)) ge 0) then message, 'Please review your background source structures. No fluxes lower or equal to zero are allowed.'
  
  if(virtual_src_count eq 0) then return, !NULL $
  else return, virtual_srcs
end
