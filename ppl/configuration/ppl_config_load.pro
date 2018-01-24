;+
; :description:
;    This helper method creates
;    a) a configuration structure to configure
;       a module in the processing pipeline
;    b) a string array of must-have tags
;
; :params:
;    entries : in, required, type="strarr()"
;              A string array containing the configuration
;              parameter information, e.g. "param1=[1, 2, 3, 4]"
;    module : in, required, type="string"
;             The the module name, e.g. hsp_module_example
;
; :keywords:
;    alias : in, optional, type="string"
;            An optional alias for this module
;
; :history:
;    18-Jul-2012 - Nicky Hochmuth (FHNW), initial release
;    18-Apr-2012 - Laszlo I. Etesi (FHNW), added alias handling to routine
;
;-
function __extract_config_data, entries, module, alias=alias
  defcon = { $
    type : 'ppl_configuration', $
    module : module $
  }
  
  if(isvalid(alias)) then defcon = add_tag(defcon, alias, 'alias')
  
  entries = [entries, [';end']]
  cases = where(stregex(entries,'^\[[_a-z]+[_a-z0-9]*\]$' ,/boolean, /fold_case), case_count)
    cases = case_count ge 1 ? [cases, n_elements(entries)] : [n_elements(entries)]
    
  ; read and analyze each line to detect sub-configuration sections
  for line=0, cases[0]-1 do begin
    term = strtrim(entries[line],2)
    token = stregex(term,'^\[\[\[([_a-z]+[_a-z0-9]*) *= *(.+)\]\]\]$',/subexpr, /extract, /fold_case)
      if (strlen(token[0]) gt 0) then begin
        if (isvalid(sub_sections)) then sub_sections = [sub_sections, token[1], token[2]] $
        else sub_sections = [token[1], token[2]]
    endif
  end
  
  ; flag to specify if parsing a section of the configuration should be stopped
  sub_section = ''
  sub_case = 0
  
  for line=0, cases[0]-1 do begin
    term = strtrim(entries[line],2)
    
    check_for_sub_section = stregex(term,'^\[\[\[([_a-z]+[_a-z0-9]*) *= *(.+)\]\]\]$',/subexpr, /extract, /fold_case)
    
    if(strlen(check_for_sub_section[0]) gt 0) then begin
      sub_section = check_for_sub_section[1]
      sub_case = check_for_sub_section[2]
      defcon = ppl_replace_tag(defcon,sub_section+"."+sub_case, {type : 'ppl_sub_config'})
      continue
    end
    token = stregex(term,'^([_a-z]+[_a-z0-9]*) *= *(.+)$',/subexpr, /extract, /fold_case)
   
    if strlen(token[0]) gt 0 then begin
      if (execute('interpreted_value = ' + token[2])) then begin
        if strlen(sub_section) eq 0 then begin
          ;no subsection
          defcon = add_tag(defcon, interpreted_value, token[1])
        end else begin
          defcon = ppl_replace_tag(defcon,sub_section+"."+sub_case+"."+token[1], interpreted_value)
        endelse
      endif
    endif
  end
  
  for i=0l, case_count-1 do begin
    case_ = (stregex(entries[cases[i]],'^\[([_a-z]+[_a-z0-9]*)\]$',/subexpr,/extract))[1]
        case_config = __extract_config_data(entries[cases[i]+1:cases[i+1]-1],module)
        defcon = add_tag(defcon,case_config,'case_'+case_)
      end
      
      return, defcon
    end
    
    ;+
    ; :description:
    ;    This function processes a stix analysis pipeline configuration file with
    ;    structure:
    ;    [[module_name,alias=AS]]
    ;    property1=XYZ
    ;    property2=ABC
    ;
    ;    Using the function on the main configuration file w/o specifying a module
    ;    it will return the complete configuration as a ppl_configuration structure.
    ;    If a specific module name is given, only the ppl_configuration for that
    ;    module is returned.
    ;
    ; :categories:
    ;    utility, pipeline, configuration
    ;
    ; :params:
    ;    filename : in, required, type="string"
    ;             The file name and path to the configuration file
    ;
    ; :keywords:
    ;    modulename : in, optional, type="string"
    ;                 An optional module name. If given, the returned
    ;                 structure will only contains the configuration
    ;                 for that module.
    ;
    ; :examples:
    ;    ppl_config_load, stix/config/stx_config.txt
    ;
    ; :history:
    ;    18-Jul-2012 - Nicky Hochmuth (FHNW), initial release
    ;    18-Apr-2012 - Laszlo I. Etesi (FHNW), added alias handling to routine
    ;    30-apr-2012 - Laszlo I. Etesi (FHNW), changed internal module configuration to pointers
    ;-
function ppl_config_load, filename, modulename=modulename
  config = { $
    type : 'ppl_configuration', $
    module : keyword_set(modulename) ? modulename : 'mainconfig' $
  }
  data = rd_tfile(filename,nocomment=';',/compress)
  
  data = [data, [';end']]
  
  modules = where(stregex(data, '^\[\[[_a-z]+[_a-z0-9]*(, *alias *= *[a-z]*)?\]\]$' ,/boolean, /fold_case),module_count)
  modules = [modules, n_elements(data)]
  data = [data, [';end']]
  
  global_config = -1
  
  for i=0l, module_count-1 do begin
    ; extract the module information with module name and alias (if present)
    mod_info = stregex(data[modules[i]],'^\[\[([_a-z]+[_a-z0-9])*,? *((alias) *= *(.*))?\]\]$',/subexpr,/extract)
    
    ; get the module name
    module = mod_info[1]
      
    ; get the alias if present, otherwise set it to ''
    alias_idx = where(mod_info eq 'alias')
    alias = (alias_idx ne -1) ? (mod_info[alias_idx+1])[0] : ''
    
    module_config = __extract_config_data(data[modules[i]+1:modules[i+1]], module, alias=alias)
    
    if keyword_set(modulename) && ~strcmp(string(modulename), module, /fold_case) then continue
    
    if keyword_set(modulename) && strcmp(string(modulename), module, /fold_case) then begin
      if isvalid(global_config) then  module_config = add_tag(module_config,global_config,'global')
      return, module_config
    endif
    
    config = add_tag(config, ptr_new(module_config), module)
  end
  
  return, config
end