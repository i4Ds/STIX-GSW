;+
; :description:
;    Utility routines used in conjunction with ppl_create_config_from_xml.
;    Iterates over the 'section' section of the configuration XML and builds
;    a configuration structure for that section.
;
; :categories:
;    xml, configuration, utility
;
; :params:
;    parent_node : in, required, type='idlffxmldomelement'
;      the start node to look for configuration sections
;      
;    type : in, required, type='string'
;      can either be 'system' (default configuration) or 'user' (user configuration);
;      used for internal processin and decision making
;      
;  :keyword:
;    default_configuration : in, optional, type='ppl_configuration'
;      the default configuration structure, used when parsing the user configuration (for default value assignment)
;      
; :returns:
;    a ppl_configuration structure for this node
;
; :examples:
;    cfg = ppl_xml_read_section(node, 'system')
;
; :history:
;    21-Aug-2014 - Laszlo I. Etesi (FHNW), initial release
;    27-Aug-2014 - Laszlo I. Etesi (FHNW), - adding sections as pointers (not for sub-sections)
;                                          - section description can now be empty
;    04-Dec-2014 - Laszlo I. Etesi (FHNW), fixed a problem when loading user configurations
;
; :todo:
;    04-Dec-2014 - Laszlo I. Etesi (FHNW), test script to see if creating new pointers to configuration sections when merging
;                                          is desirable or not
;-
function ppl_xml_read_section, parent_node, type, default_configuration=default_configuration
  if(~ppl_typeof(parent_node,compareto='idlffxmldomelement')) then message, "The input node must be an IDLffXMLDOMElement."

  ; start creating the main configuration manager structure
  cfg_main = { $
    type : 'ppl_configuration', $
    module : 'mainconfig' $
    }
    
  ; extract all sections
  sections = parent_node->getelementsbytagname('section')
  
  ; loop over all sections
  for sec_idx = 0L, sections->getlength()-1 do begin
    section = sections->item(sec_idx)
    
    ; skip sections held inside parameter nodes if parent is a configuration
    if(parent_node->gettagname() eq 'configuration') then begin
      ;destroy, parent
      parent = section->getparentnode()
      if(parent->gettagname() eq 'parameter') then continue
    endif
    
    ; read all section attributes
    sname = section->getattribute('name')
    salias = section->getattribute('alias')
    
    if(sname eq '') then message, 'Name attribute for sections cannot be empty!'
    
    ; extract description
    section_description = ppl_xml_get_single_text_value(section, 'description')
    
    if(section_description eq !NULL) then section_description = ''
    
    ; extract links
    section_links = list()
    section_link_nodes = section->getelementsbytagname('link')
    for sl_idx = 0L, section_link_nodes->getlength()-1 do begin
      ;destroy, section_link
      ;destroy, link_parent_node
      section_link = section_link_nodes->item(sl_idx)
      link_parent_node = section_link->getparentnode()
      if(link_parent_node->gettagname() ne 'section') then continue;
      link_text = ppl_xml_get_text_value(section_link)
      if(link_text ne !NULL) then section_links.add, link_text
    endfor
    
    ;destroy, section_link
    ;destroy, link_parent_node
    ;destroy, link_nodes

    if(section_links.count() gt 0) then section_link_texts = arr2str(section_links.toarray(), ',') $
    else section_link_texts = '' 
    
    ;destroy, section_links
    
    ; start configuration section
    cfg_section = { $
      type : 'ppl_configuration', $
      module : sname, $
      alias : salias, $
      description : section_description, $
      links : section_link_texts $
      }
      
    ; prepare infor list
    parameter_info_list = list()
    
    ; loop over all parameters for this section
    parameters = section->getelementsbytagname('parameter')
    
    for param_idx = 0L, parameters->getlength()-1 do begin
      parameter = parameters->item(param_idx)
      
      ; keep a variable to track if we're in a section -> parameter -> section -> parameter
      in_sub_section = 0b
      
      ; skip parameters inside sub sections if parent_node is configuration
      if(parent_node->gettagname() eq 'configuration') then begin
        parent1 = parameter->getparentnode()
        parent2 = parent1->getparentnode()
        if(parent2->gettagname() eq 'parameter') then continue
      endif else in_sub_section = 1b
      
      ;destroy, parent1
      ;destroy, parent2
      
      ; read all parameter attributes, either from file or from default config
      pname = parameter->getattribute('name')
      punit = ppl_xml_get_single_text_value(parameter, 'unit')
      
      if(pname eq '') then message, 'Parameter name must not be empty.'
      if(type eq 'system') then begin
        pdefault = parameter->getattribute('default')
        pvalid = parameter->getattribute('valid')
        ptype = parameter->getattribute('type')
        punit = (punit eq !NULL) ? '' : punit
      endif else begin
        ; treat sub-sections differently
        if(~in_sub_section) then begin
          default_section_config = default_configuration.(where(strlowcase(tag_names(default_configuration)) eq sname))
          
          ; in case we input default config from the outside
          if(ptr_valid(default_section_config)) then default_section_config = *default_section_config
        endif else begin
          parent1 = parameter->getparentnode()
          parent2 = parent1->getparentnode()
          parent3 = parent2->getparentnode()
          default_section_config = default_configuration.(where(strlowcase(tag_names(default_configuration)) eq parent3->getattribute('name')))
          
          ; in case we input default config from the outside
          if(ptr_valid(default_section_config)) then default_section_config = *default_section_config
        endelse
        ;else default_section_config = default_configuration.(where(strlowcase(tag_names(default_configuration.(where(strlowcase(tag_names(default_configuration)) eq ))) eq sname))
        default_section_info = default_section_config.info[where(strlowcase(default_section_config.info.parameter) eq pname)]
        pdefault = default_section_info.default
        pvalid = default_section_info.valid
        ptype = default_section_info.expected_type
        punit = (punit eq !NULL) ? default_section_info.unit : punit
      endelse
      
;      destroy, parent1
;      destroy, parent2
;      destroy, parent3
      
      ; delete emtpy variables for the below code to work safely
      if(pdefault eq '') then delvar, pdefault
      if(pvalid eq '') then delvar, pvalid
      if(ptype eq '') then delvar, ptype
      if(punit eq '') then delvar, punit
      
      ; currently not allowing empty attributes, coming later with system and user configs
      if(~isvalid(pdefault) or ~isvalid(pvalid) or ~isvalid(ptype)) then message, 'Empty attributes not allowed.'
      
      ; validate default value and type
      value = ppl_xml_transform_string_to_value(pdefault)
      isvalid = ppl_xml_validate_value(value, pvalid, ptype)
      if(~isvalid) then begin
        if(is_struct(value)) then value_txt = 'N/A (struct)' $
        else if(isarray(value)) then value_txt = arr2str(trim(string(value)), ',') $
        else value_txt = trim(string(value))
        message, "Default value for parameter '" + pname + "' in section '" + sname + "' is invalid. Must be of type '" + ptype + "' and satisfy condition '" + pvalid + "'. Actual type and value are '" + ppl_typeof(value) + "' and '" + value_txt + "'."
      endif
      
      if(type eq 'system') then begin
        ; get description
        description_text = ppl_xml_get_single_text_value(parameter, 'description')
        ; get links
        links = parameter->getelementsbytagname('link')
        link_list = list()
        for link_idx = 0L, links->getlength()-1 do begin
          ;destroy, link_node
          link_node = links->item(link_idx)
          link_text = ppl_xml_get_text_value(link_node)
          if(link_text ne !NULL) then link_list.add, link_text
        endfor
        
        if(description_text eq !NULL) then description_text = 'n/a'
        
        ;destroy, link_node
        ;destroy, links
        
        ; prepare link list
        if(link_list.count() gt 0) then links_str = arr2str(link_list.toarray(), ',') $
        else links_str = ''
        
        ;destroy, link_list
        
        ; add info for this parameter
        param_info = { $
          type : 'ppl_configuration_info', $
          module : sname, $
          parameter : pname, $
          default : pdefault, $
          valid : pvalid, $
          expected_type : ptype, $
          description : description_text, $
          unit : punit, $
          links : links_str $
          }
          
        parameter_info_list.add, param_info
      endif
      
      ; check for sub configuration sections
      cfg_sub_section = ppl_xml_read_section(parameter, type, default_configuration=default_configuration)
      
      ; add sub sections
      sub_section_tags = tag_names(cfg_sub_section)
      for tag_idx = 0L, n_elements(sub_section_tags)-1 do begin
        if(ppl_typeof(cfg_sub_section.(tag_idx), compareto='ppl_configuration')) then cfg_section = add_tag(cfg_section, cfg_sub_section.(tag_idx), pname + '_' + strlowcase(sub_section_tags[tag_idx]))
      endfor
      
      ; get user-defined value
      value_text = ppl_xml_get_single_text_value(parameter, 'value')
      
      if(value_text ne !NULL) then begin
        value = ppl_xml_transform_string_to_value(value_text)
        isvalid = ppl_xml_validate_value(value, pvalid, ptype)
        if(~isvalid) then message, "User value for parameter '" + pname + "' in section '" + sname + "' is invalid. Must be of type '" + ptype + "' and satisfy condition '" + pvalid + "'. Actual type and value are '" + ppl_typeof(value) + "' and '" + trim(string(value)) + "'."
      endif
      
      ; add values to configuration structure
      cfg_section = add_tag(cfg_section, value, pname)
    endfor
    
    ; add info to section
    if(parameter_info_list.count() gt 0) then cfg_section = add_tag(cfg_section, parameter_info_list.toarray(), 'info')
    
    ; add section to main
    if(in_sub_section) then cfg_main = add_tag(cfg_main, cfg_section, sname) $
    else cfg_main = add_tag(cfg_main, ptr_new(cfg_section), sname)
  
    ;destroy, section
    ;destroy, parameter_info_list
  endfor
  
  destroy, parent
  destroy, section_link
  destroy, link_parent_node
  destroy, link_nodes
  destroy, section_links
  destroy, parent1
  destroy, parent2
  destroy, parent3
  destroy, link_node
  destroy, links
  destroy, link_list
  destroy, section
  destroy, parameter_info_list
  destroy, sections
  destroy, parameters
  
  
  return, cfg_main
end