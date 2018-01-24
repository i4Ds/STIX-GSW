;+
; :description:
;    This routine reads a default or user configuration XML and generates a pipeline configuration structure.
;    It automatically locates the configuration directory (STX_CONF) and tries finding appropriate default configurations (APPLICATION_default.xml). The
;    default configuration is either requested using the application_name keyword or loaded implicitely when passing in a user configuration (using the "application"
;    tag in the XML document). User configurations are ALWAYS checked against and merged with default configurations.
;
; :categories:
;    pipeline, configuration, xml
;
; :keywords:
;    application_name : in, optional, type='string'
;      an application name, such as 'stx_data_simulation', 'stx_analysis_software', or 'stx_flight_software_simulator'
;
;    xml_configuration_file : in, optional, type='string'
;      a path to a user configuration xml
;
; :returns:
;   a ppl_configuration structure with all the configuration data for this application
;
; :examples:
;    configuration = ppl_create_config_from_xml(xml_configuration_file=concat_dir(getenv('stx_conf'), 'stx_data_simulation_user.xml'))
;
; :history:
;    21-Aug-2014 - Laszlo I. Etesi (FHNW), initial release
;    04-Dec-2014 - Laszlo I. Etesi (FHNW), - fixed a problem when loading user configurations
;                                          - fixed a possible issue when working with user and system configuration that have
;                                            a different number of elements (or a different arrangement of the modules)
;    19-May-2015 - Laszlo I. Etesi (FHNW), - added some comments
;    
; :todo:
;    04-Dec-2014 - Laszlo I. Etesi (FHNW), test script to see if creating new pointers to configuration sections when merging
;                                          is desirable or not
;-
function ppl_create_config_from_xml, application_name=application_name, xml_configuration_file=xml_configuration_file
  ; some validity checks
  if(~isvalid(application_name) and ~isvalid(xml_configuration_file) or isvalid(application_name) and isvalid(xml_configuration_file)) then message, 'Please specify an application name or an XML configuration file.'
  
  ; if configuration file is empty, read default using application name; also copy it to internal name
  if(~isvalid(xml_configuration_file)) then begin
    configuration_file = concat_dir(getenv('stx_conf'), application_name + '_default.xml')
  endif else configuration_file = xml_configuration_file
  
  ; test if the configuration file exists
  if(isvalid(configuration_file) and ~file_exist(configuration_file)) then message, 'XML configuration file ' + configuration_file + ' does not exist. Check either the application_name or xml_configuration_file keyword.'
  
  ; create document for configuraiton
  doc = obj_new('idlffxmldomdocument', filename=configuration_file)
  
  ; extract the one configuration section
  configurations = doc->getelementsbytagname('configuration')
  configuration = configurations->item(0)
  
  ; read the application name
  application = configuration->getattribute('application')
  
  ; read the configuration type ('system' for default read-only configuration, 'user' for user configuration')
  type = configuration->getattribute('type')
  
  ; if the configuration file is not a system, i.e. default configuration then try finding it automatically
  switch (type) of
    'system': begin
      ; noop
      break
    end
    'user': begin
      ; find and read default configuration file using the application name
      default_configuration = ppl_create_config_from_xml(application_name=application)
      break
    end
    else: begin
      message, "Illegal XML configuration application name '" + application + "'."
    end
  endswitch
  
  cfg_main = ppl_xml_read_section(configuration, type, default_configuration=default_configuration)
  
  ; do merging of configs
  if(isvalid(default_configuration)) then begin
    ; install error handler to be able to give proper error message
    error = 0
    catch, error
    if (error ne 0)then begin
      catch, /cancel
      err = err_state()
      
      if(stregex(err, 'Conflicting data structures', /boolean)) then message, "Could not integrate user configuration with default configuration. Make sure the user configuration does not contain additional parameter. Current section is '" + mod_conf_name + "'." $
      else message, err
    endif
    
    ; recreate config
    cfg_main_new = { $
      type : 'ppl_configuration', $
      module : 'mainconfig' $
      }
    mod_conf_names = strlowcase(tag_names(default_configuration))
    
    ; iterate over all modules
    for mod_conf_idx = 0L, n_elements(mod_conf_names)-1 do begin
      mod_conf_name = mod_conf_names[mod_conf_idx]
      mod_conf_default = default_configuration.(where(strlowcase(tag_names(default_configuration)) eq mod_conf_name))
      
      ; the default config can be a pointer or not
      if(ptr_valid(mod_conf_default)) then begin
        mod_conf_default = *mod_conf_default
        mod_conf_is_ptr = 1
      endif else mod_conf_ptr = 0
      
      ; if user config (cfg_main) does not contain a module, copy default configuration. Otherwise use user config
      if(~tag_exist(cfg_main, mod_conf_name)) then begin
        if(mod_conf_is_ptr) then mod_conf_default = ptr_new(mod_conf_default)
        cfg_main_new = add_tag(cfg_main_new, mod_conf_default, mod_conf_name)
      endif else mod_conf_user = cfg_main.(tag_index(cfg_main, mod_conf_name))
      
      if(ptr_valid(mod_conf_user)) then begin
        mod_conf_user = *mod_conf_user
        mod_conf_user_is_ptr = 1
      endif else mod_conf_user_is_ptr = 0
        
      if(ppl_typeof(mod_conf_default, compareto='ppl_configuration')) then begin
        cfg_merged = ppl_config_merge(mod_conf_default, mod_conf_user, /add_to_base, /recursive)
        
        if(mod_conf_user_is_ptr) then cfg_merged = ptr_new(cfg_merged)
        
        cfg_main_new = add_tag(cfg_main_new, cfg_merged, mod_conf_name)
      endif
  endfor
  
  destroy, configurations
  destroy, configuration
  destroy, doc
  
  return, cfg_main_new
endif

destroy, configurations
destroy, configuration
destroy, doc

return, cfg_main
end