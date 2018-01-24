;+
; :file_comments:
;    This file contains the definition for the pipeline configuration manager.
;    The purpose of this object is to centralize the access to module configurations
;    and to provide the user an interface to interacting with the configurations.
;
; :categories:
;    pipeline, configuration
;
; :properties:
;    configuration_file
;      this parameter points to the configuration file to be loaded
;
; :examples:
;    cofm = new_obj('ppl_configuration_manager', 'configuration.txt')
;    cofm->load_configuration()
;    cofm->get(module='module_name')
;
; :history:
;    30-Apr-2013 - Laszlo I. Etesi (FHNW), initial release
;    25-Feb-2014 - Laszlo I. Etesi (FHNW), allow for the external specification of the configuration file
;    29-Apr-2014 - Laszlo I. Etesi (FHNW), keyword 'single' in 'get' is set to 0 if 'module' is present
;    27-Aug-2014 - Laszlo I. Etesi (FHNW), updated configuration manager to work with new XML configuration
;    20-Aug-2015 - Laszlo I. Etesi (FHNW), bugfix: auto-initialization properly handled
;
; :todo:
;    28-Aug-2014 - Laszlo I. Etesi (FHNW), ensure all parameter names and tag names are handled lowercase
;-

;+
; :description:
;    Init routine
;-
function ppl_configuration_manager::init, configuration_file, application, initialized
  default, initialized, 0b
  if(isvalid(configuration_file) and isvalid(application) or ~isvalid(configuration_file) and ~isvalid(application)) then message, 'Please specify a configuration file or an application name (one or the other).'
  if(isvalid(configuration_file) and ~file_exist(configuration_file)) then message, 'Please specify a correct configuration file; given file path is invalid.'

  if(isvalid(configuration_file)) then self.configuration_file = configuration_file $
  else self.application = application
  
  self.initialized = initialized
  return, 1
end

;+
; :description:
;    Cleanup routine
;-
pro ppl_configuration_manager::cleanup
  if(ptr_valid(self.configuration)) then begin
    tagnames = tag_names(*self.configuration)
    for tidx = 0L, n_elements(tagnames)-1 do begin
      if(valid_pointer((*self.configuration).(tidx))) then destroy, (*self.configuration).(tidx)
    endfor

    destroy, self.configuration
  endif
  destroy, self.lookup
end

;+
; :description:
;    Reads a configuration file from the disk and creates
;    a ppl_configuration structure
;
; :keywords:
;    file : in, optional, type="string"
;               the path to the configuration file
;
; :history:
;    30-Apr-2013 - Laszlo I. Etesi (FHNW), initial release
;-
pro ppl_configuration_manager::load_configuration
  if(~file_exist(self.configuration_file) and ~isvalid(self.application)) then message, 'Please initialize the configuration manager properly. Could not find a configuration file or application name!'

  self.configuration = ptr_new(ppl_create_config_from_xml(application_name=(self.application eq '') ? void : self.application, xml_configuration_file=(self.configuration_file eq '') ? void : self.configuration_file))

  ; extract the aliases
  tagnames = tag_names(*self.configuration)
  tmp_lookup = strarr(n_elements(tagnames), 2)
  lookupidx = 0
  for tidx = 0L, n_elements(tagnames)-1 do begin
    current = (*self.configuration).(tidx)
    if(valid_pointer(current) && is_struct(*current) && tag_exist(*current, 'type') && get_tag_value(*current, /type) eq 'ppl_configuration') then begin
      tmp_lookup[lookupidx++] = get_tag_value(*current, /alias)
      tmp_lookup[lookupidx++] = get_tag_value(*current, /module)
    endif
  endfor

  self.lookup = ptr_new(tmp_lookup[0:lookupidx-1])
end

;+
; :description:
;    Writes the currently loaded configuration to a file
;
; :keywords:
;    file : in, required, type="string"
;               the path to the configuration file
;
; :history:
;    30-Apr-2013 - Laszlo I. Etesi (FHNW), initial release
;
; :todo:
;    30-Apr-2013 - Laszlo I. Etesi (FHNW), implement routine
;-
function ppl_configuration_manager::save_configuration, file=file
  message, 'Not implemented yet'
  return, 0
end

;+
; :description:
;    Retrieves a module configuration from the loaded configuration.
;    The module configuration will always contain the global parameters (however, the
;    module-specific parameter have precedence!)
;    The behaviour is such:
;    0. no module, no namespace: return global
;    1. no module, namespace: the first parameter defines the namespace, the others are treated as in namespace + global
;    2. module, no namespace: treat all parameters as "for module" + global
;    3. module, namespace: treat all parameters as "for module" + global
;    4. module, no parameters: return all module parameters + global
;
; :keywords:
;    module : in, optional, type="string"
;             the module name (e.g. stx_module_calculate_visibilities) (see behaviour above)
;
;    single : in, optional, type="boolean", default="false"
;             if single is set, only the value of the requested parameter is returned and not
;             the complete struct; only allowd when one (and exactly) one parameter is requested
;
;    to_string: in, optional, type="boolean", default="false"
;               only valid with single; if set, the output is converted to a string rather than number, etc.
;
;    _extra : in, optional, type="extra"
;             the parameters that will be returned (see behaviour above)
;
; :returns:
;    Returns a ppl_configuration structure with the requested configuration for a given module
;    (copy of original module configuration!)
;
; :history:
;    30-Apr-2013 - Laszlo I. Etesi (FHNW), initial release
;    21-May-2013 - Laszlo I. Etesi (FHNW), added single parameter
;    29-Jul-2015 - Laszlo I. Etesi (FHNW), added to_string parameter
;    30-Jul-2015 - Laszlo I. Etesi (FHNW), improved to_string to handle arrays
;    08-Oct-2015 - Laszlo I. Etesi (FHNW), removed condition that single cannot be used with module
;
; :todo:
;    30-Apr-2013 - Laszlo I. Etesi (FHNW), mix and match not possible, i.e. no combination of cv_param and sp_keyword.
;    21-May-2013 - Laszlo I. Etesi (FHNW), introduced shared sections, variable resolution (e.g. $SSW), and maybe execute instruction (e.g. #!getenv('test'))
;    28-Aug-2014 - Laszlo I. Etsei (FHNW), upated to work with XML configuration
;-
function ppl_configuration_manager::get, module=module, single=single, to_string=to_string, _extra=extra
  ; check if single was selected
  ;if(isvalid(module)) then single=0

  default, single, 0
  default, to_string, 0

  n_extra = n_tags(extra)
  if(n_extra ne 1 && keyword_set(single)) then begin
    ;message, "The keyword 'single' is only allowed in combination with one parameter.", /continue
    ;return, -1
    single = 0
  endif

  ; check if extra is empty and return all paramters
  if(~keyword_set(extra)) then begin
    retconf = self->_parse_input_get_module_config_reference(module=module, globalconf=globalconf)
    if(ptr_valid(retconf)) then retconf = *retconf $
    else retconf = ptr_new()
  endif else begin
    ; loop over all extra parameters
    ; if only one parameter is supplied, return that value, else return ppl_configuration structure
    tagnames = tag_names(extra)
    for eidx = 0L, n_elements(tagnames)-1 do begin
      parameter = tagnames[eidx]

      ; get module configuration pointer
      modconf = self->_parse_input_get_module_config_reference(module=module, parameter=parameter, ns=ns, globalconf=globalconf)

      ; remove namespace from parameter if necessary
      param = self->_remove_ns_from_parameter(parameter, config=modconf)

      ; check if tag exists
      if(tag_exist(*modconf, param)) then value = (*modconf).(tag_index(*modconf, param)) $
      else begin
        ; check for sub sections
        tag_sc_split = strsplit(param, '_', /extract)
        if(n_elements(tag_sc_split) lt 2) then message, 'Could not locate parameter ' + param + ' for module ' + (isvalid(module) ? module : (isvalid(*modconf) ? (*modconf).module : 'N/A'))
        tag_sc = arr2str(tag_sc_split[0:1], '_')
        if(tag_exist(*modconf, tag_sc)) then begin
          sc = (*modconf).(tag_index(*modconf, tag_sc))
          tag_for_sc = arr2str(tag_sc_split[2:*], '_')
          if(~tag_exist(sc, tag_for_sc)) then message, 'Could not locate parameter ' + tag_for_sc + ' for sub section ' + tag_sc + ' in module ' + (isvalid(module) ? module : (isvalid(*modconf) ? (*modconf).module : 'N/A'))
          value = sc.(tag_index(sc, tag_for_sc))
        endif else message, 'Could not locate parameter ' + param + ' for module ' + (isvalid(module) ? module : (isvalid(*modconf) ? (*modconf).module : 'N/A'))
      endelse

      ; compile return value
      if(~isvalid(retconf)) then retconf = { type:(*modconf).type, module:(*modconf).module, alias:(*modconf).alias }
      retconf = add_tag(retconf, value, param, /quiet)

      if(keyword_set(single)) then begin
        retval = retconf.(tag_index(retconf, param))
        if(to_string && ~ppl_typeof(retval, compareto='byte', /raw)) then return, trim(arr2str(retval, delimiter=',')) $
        else if(to_string && ppl_typeof(retval, compareto='byte', /raw)) then return, trim(arr2str(fix(retval), delimiter=',')) $
        else return, retval
      endif
    endfor
  endelse

  ; merge global configuration with module configuration
  retconf = self->_merge_configs_by_reference(config1=retconf, config2=globalconf)

  return, retconf
end

;+
; :description:
;    Add new parameters or reset existing parameters to a given value in the module configuration.
;    The behaviour is such:
;    0. no module: for parameters with namespace -> assign to module, otherwise make global
;    1. module: All parameters are assigend to that module (even if they have a foreign namespace encoded. The module namespace is removed)
;
; :keywords:
;    module : in, optional, type="string"
;             the module name (e.g. stx_module_calculate_visibilities) (see behaviour above)
;    _extra : in, optional, type="extra"
;             the parameters that will be set (see behaviour above)
;
; :history:
;    30-Apr-2013 - Laszlo I. Etesi (FHNW), initial release
;    28-Aug-2014 - Laszlo I. Etesu (FHNW), updated to work with XML configuration (allowing for sub-section
;
;-
pro ppl_configuration_manager::set, module=module, subcase=subcase, _extra=extra
  ; return if nothing is set
  if(~keyword_set(module) && ~keyword_set(extra)) then return

  ; get tag names
  tagnames = tag_names(extra)

  ; handle the two cases (module set or not)
  if(keyword_set(module)) then begin
    ; get module configuration
    modconf = self->_get_module_config_reference(module=module)

    ; if no module configuration found, return and give error
    if(~ptr_valid(modconf)) then begin
      message, 'Module ' + module + ' is not a valid module name', /continue
      return
    endif

    ; for each parameter, add it to the module configuration or change its value
    for eidx = 0L, n_elements(tagnames)-1 do begin

      ; extract the ns-removed paramter, check if it exists
      param = self->_remove_ns_from_parameter(tagnames[eidx], config=modconf, exists=exists)

      ; check if the parameter is a sub section
      if(exists and ~tag_exist(*modconf, param)) then begin
        tag_sc_split = strsplit(param, '_', /extract)
        tag_sc = arr2str(tag_sc_split[0:1], '_')
        if(tag_exist(*modconf, tag_sc)) then begin
          idx_tag_sc = tag_index(*modconf, tag_sc)
          (*modconf) = ppl_replace_tag(*modconf, tag_sc, ppl_replace_tag((*modconf).(idx_tag_sc), tag_sc_split[2:*], extra.(eidx)))
        endif else (*modconf) = ppl_replace_tag(*modconf, param, extra.(eidx)) ; unknown tag, don't check for validity
      endif else begin
        self->_input_parameter_valid, *modconf, param, extra.(eidx)
        (*modconf) = ppl_replace_tag(*modconf, param, extra.(eidx))
      endelse
    endfor
  endif else begin
    ; for each parameter, add it to the module configuration or change its value
    for eidx = 0L, n_elements(tagnames)-1 do begin
      ; extract validated namespace
      ns = self->_extract_ns_from_parameter(tagnames[eidx], /validated)

      ; if namespace is empty, make it global, otherwise use module
      if(ns eq '') then module = 'global' $
      else module = self->_get_module_for_ns(ns)

      ; get the module configuration (may be global)
      modconf = self->_get_module_config_reference(module=module)

      ; get the parameter
      param = self->_remove_ns_from_parameter(tagnames[eidx], config=modconf, exists=exists)

      ; check if the parameter is a sub section
      if(exists and ~tag_exist(*modconf, param)) then begin
        tag_sc_split = strsplit(param, '_', /extract)
        tag_sc = arr2str(tag_sc_split[0:1], '_')
        if(tag_exist(*modconf, tag_sc)) then begin
          idx_tag_sc = tag_index(*modconf, tag_sc)
          (*modconf) = ppl_replace_tag(*modconf, tag_sc, ppl_replace_tag((*modconf).(idx_tag_sc), arr2str(tag_sc_split[2:*], '_'), extra.(eidx)))
        endif else (*modconf) = ppl_replace_tag(*modconf, param, extra.(eidx))
      endif else (*modconf) = ppl_replace_tag(*modconf, param, extra.(eidx))
    endfor
  endelse
end

function ppl_configuration_manager::help, parameter=parameter, module=module, namespace=namespace
  message, 'To be implemented'
end

;+
; :description:
;    Internal routine.
;    Retrieves the global configuration (by keyword) and the configuration for a module.
;    Both structures are returned as pointers and reference the original internal configuration.
;    The target module is selected using the following process:
;    0. no module, no parameter/namespace: return global configuration
;    1. no module, namespace: return global configuration + module referenced by namespace
;    2. module, no namespace: return global configuration + module configuration
;
; :keywords:
;    module : in, optional, type="string"
;             the module name (e.g. stx_module_calculate_visibilities) (see behaviour above)
;    parameter : in, optional, type="string"
;                the parameter with namespace information (see behaviour above)
;    ns : out, optional, type="string"
;         the namespace that was found in 'parameter'; can be empty string
;    globalconf : out, optional, type="ptr(ppl_configuration)"
;                 a pointer reference to the original global configuration
;
; :returns:
;    the return value is a pointer to the internal structure of the selected module configuration
;
; :history:
;    30-Apr-2013 - Laszlo I. Etesi (FHNW), initial release
;-
function ppl_configuration_manager::_parse_input_get_module_config_reference, module=module, parameter=parameter, ns=ns, globalconf=globalconf
  ; set default values
  default, parameter, ''
  default, ns, ''

  ; extract namespace, may be empty!
  if(parameter ne '') then ns = self->_extract_ns_from_parameter(parameter, /validated)

  ; get global config
  globalconf = self->_get_module_config_reference(module='global')

  ; select appropriate case
  switch ((keyword_set(module) * 2) + fix(ns ne '')) of
    0: begin ; module NOT set, NO namespace detected
      modconf = globalconf
      break
    end
    1: begin ; module NOT set, namespace detected
      modconf = self->_get_module_config_reference(namespace=ns)
      break
    end
    2: begin ; module set, NO namespace detected
      modconf = self->_get_module_config_reference(module=module)
      break
    end
    3: begin ; module set, namespace detected
      modconf = self->_get_module_config_reference(module=module)
      break
    end
    else: begin
      message, 'Could neither locate module nor parameter'
    end
  endswitch

  ; return module config pointer
  return, modconf
end

;+
; :description:
;    Internal routine.
;    Takes a parameter and tries to extract namespace information from it.
;
; :params:
;    parameter : in, required, type="string"
;                the parameter name for which to try to extract namespace information
;
; :keywords:
;    exits : out, optional, type="boolean"
;            returns true or false, indicating if the extracted namespace
;            exists in the internal module->ns lookup table
;    validated : in, optional, type="boolean"
;                if validated is set, the returned namespace will be set to empty string
;                if the namespace does not exist in the internal lookup table
; :returns:
;    the namespace information for given parameter
;
; :history:
;    30-Apr-2013 - Laszlo I. Etesi (FHNW), initial release
;-
function ppl_configuration_manager::_extract_ns_from_parameter, parameter, exists=exists, validated=validated
  ; extract the namespace from the parameter
  ns = strlowcase((stregex(parameter, '^([a-zA-Z0-9]+)_.*$', /subexpr, /extract))[1])

  ; check if ns appears in the internal lookup table
  exists = where((*self.lookup) eq ns) gt -1

  ; check if this is an actual namespace and set it to emtpy string (if not and requested by user)
  if(keyword_set(validated) && ~exists) then return, '' $
  else return, ns
end

;+
; :description:
;    Internal routine.
;    Takes a parameter and tries to remove the namespace information
;
; :params:
;    parameter : in, required, type="string"
;                the parameter from which to remove the namespace information
;
; :keywords:
;    config : in, optional, type="ptr(ppl_configuration)"
;            if config is a valid pointer to a ppl_configuration, the routine
;            will evaluate if the parameter is an actual parameter for given module
;    exists : out, optional, type="boolean"
;             returns true if the parameter is an actual parameter for given module
;
; :returns:
;    the parameter string with namespace removed
;
; :history:
;    30-Apr-2013 - Laszlo I. Etesi (FHNW), initial release
;-
function ppl_configuration_manager::_remove_ns_from_parameter, parameter, config=config, exists=exists
  ; if config is valid, validate the parameter for module "config"
  if(ptr_valid(config)) then begin
    exists = self->_parameter_valid_for_module_config(parameter, config, hasns=hasns)
  endif

  ; if the above statement is not invoked, assume the parameter has namespace information attached
  default, hasns, 1

  ; if the above statement is not invoked, set the exists keyword to false (since we cannot verify it)
  default, exists, 0

  ; get the namespace information
  if(exists && hasns) then ns = self->_extract_ns_from_parameter(parameter) $
  else ns = ''

  ; if the namespace is an empty string, return the original parameter, otherwise cut the namespace off
  return, ns ne '' ? strmid(parameter, strlen(ns)+1) : parameter
end

;+
; :description:
;    Internal routine.
;    Validates a parameter by checking if it exists for a given module
;
; :params:
;    parameter : in, required, type="string"
;                the parameter from which to remove the namespace information
;    config : in, required, type="ptr(ppl_configuration)"
;             this parameter is used to verify if 'parameter' exists
;
; :keywords:
;    hasns : out, optional, type="boolean"
;            is true if this parameter has namespace information attached
;
; :returns:
;    the parameter string with namespace removed
;
; :history:
;    30-Apr-2013 - Laszlo I. Etesi (FHNW), initial release
;-
function ppl_configuration_manager::_parameter_valid_for_module_config, parameter, config, hasns=hasns
  ; default hasns to false
  default, hasns, 0

  ; if the parameter exists "as is", no namespace information is attached and parameter exits
  if(tag_exist(*config, parameter,/recurse)) then return, 1 $
  else begin ; else the parameter
    ns = self->_extract_ns_from_parameter(parameter)
    hasns = ns ne '' and ns eq self->_get_ns_for_module((*config).module)

    ; we already checked if tag exists; if no ns is found tag is invalid
    if(~hasns) then return, 0

    tag_wo_ns = strmid(parameter, strlen(ns) + 1)

    ; check if the tag exists
    tag_exists = tag_exist(*config, tag_wo_ns, /recurse)

    if(tag_exists) then return, 1

    ; if tag doesn't exist try and see if there is sub structure
    tag_sc_split = strsplit(tag_wo_ns, '_', /extract)
    if(n_elements(tag_sc_split) lt 2) then return, 0

    tag_sc = arr2str(tag_sc_split[0:1], '_')
    tag_sc_exists = tag_exist(*config, tag_sc, /recurse)

    return, tag_sc_exists
  endelse
end

;+
; :description:
;    Internal routine.
;    Tries to find the namespace for a module
;
; :params:
;    module : in, required, type="string"
;             the module name for which to look for the namespace

; :returns:
;    the module's namespace
;
; :history:
;    30-Apr-2013 - Laszlo I. Etesi (FHNW), initial release
;-
function ppl_configuration_manager::_get_ns_for_module, module
  lookupidx = where((*self.lookup) eq module)
  if(lookupidx eq -1) then return, '' $
  else return, (*self.lookup)[lookupidx-1]
end

;+
; :description:
;    Internal routine.
;    Tries to find the module for a namespace
;
; :params:
;    namespace : in, required, type="string"
;             the namespace for which to look for a module

; :returns:
;    the namespace for given module name
;
; :history:
;    30-Apr-2013 - Laszlo I. Etesi (FHNW), initial release
;-
function ppl_configuration_manager::_get_module_for_ns, namespace
  lookupidx = where((*self.lookup) eq namespace)
  if(lookupidx eq -1) then return, '' $
  else return, (*self.lookup)[lookupidx+1]
end

;+
; :description:
;    Internal routine.
;    Searches for the configuration (pointer) for a module or its namespace
;
; :keywords:
;    module : in, optional, type="string"
;             the module name for which to get the configuration
;    namespace : in, optional, type="string"
;                the namespace name for which to get the module configuration
; :returns:
;    a module configuration pointer (careful: returning the original internal pointer";
;    returning ptr_new() if module or namespace was not found
;
; :history:
;    30-Apr-2013 - Laszlo I. Etesi (FHNW), initial release
;-
function ppl_configuration_manager::_get_module_config_reference, module=module, namespace=namespace
  ; make sure only one keyword is supplied
  if(keyword_set(module) and keyword_set(namespace)) then message, 'Conflicting keywords.'

  ; extracting module from namespace if namespace is supplied
  if(keyword_set(namespace)) then begin
    module = self->_get_module_for_ns(namespace)
  endif

  modidx = tag_index(*self.configuration, module)
  if(modidx gt -1) then return, (*self.configuration).(modidx) $
  else return, ptr_new()
end

function ppl_configuration_manager::_flatten_cases, config
  tags =  tag_names(config)

  for i=0L, n_elements(tags)-1 do begin
    tag_idx = tag_index(config, tags[i])
    if ppl_typeof(config.(tag_idx),compareto="ppl_case") then begin
      ppl_case = config.(tag_idx)
      config = ppl_replace_tag(config,tags[i], ppl_case.value)
      case_idx = tag_index(ppl_case,ppl_case.value)
      if case_idx ge 0 then  config = self->_merge_configs_by_reference(config1=config,config2=ppl_case.(case_idx))
    end
  endfor

  return, config
end


;+
; :description:
;    Internal routine.
;    Takes two configuration pointers (usually one module pointer and one
;    global configuration), merges the configurations and returns a new
;    configuration struct.
;
; :keywords:
;    config1 : in, optional, type="ptr_new(ppl_configuration)"
;              a pointer to a (module) configuration; this configuration
;              pointer has precedence over config2 (if they both contain the same
;              tags)
;    config2 : in, optional, type="ptr_new(ppl_configuration)"
;              a pointer to a (global) configuration; tags in this configuration structure
;              that also appear in config1 are overwritten.
; :returns:
;    returns a merged copy of config1 and config2; if one of the two configuration
;    pointers is null, a copy of the other configuration is returned.
;
; :history:
;    30-Apr-2013 - Laszlo I. Etesi (FHNW), initial release
;-
function ppl_configuration_manager::_merge_configs_by_reference, config1=config1, config2=config2
  ; make a copy of the input parameters
  if(ptr_valid(config1)) then config1 = *config1
  if(ptr_valid(config2)) then config2 = *config2

  ; prepare for the case where only one input parameter is present
  if(is_struct(config1)) then begin copystr = config1
endif else if (is_struct(config2)) then begin copystr = config2
endif else begin
  message, 'No valid configuration structure given.'
endelse

; merge the two configuration copies into one
if(is_struct(config1) and is_struct(config2)) then begin
  tags = tag_names(config2)
  for tidx = 0L, n_elements(tags)-1 do begin
    copystr = add_tag(copystr, config2.(tidx), tags[tidx], /quiet)
  endfor
endif
return, copystr
end

pro ppl_configuration_manager::_input_parameter_valid, config, parameter, value
  param_info_idx = where(strlowcase(config.info.parameter) eq strlowcase(parameter), count)
  if(count ne 1) then message, 'Could not select parameter info for ' + parameter + ' in module ' + config.module

  condition = config.info[param_info_idx].valid
  type = config.info[param_info_idx].expected_type
  if(~ppl_xml_validate_value(value, config.info[param_info_idx].valid, type)) then message, "Value for parameter '" + parameter + "' in module '" + config.module + "' is invalid. Must be of type '" + type + "' and satisfy condition '" + condition + "'. Actual type and value are '" + ppl_typeof(value) + "' and '" + trim(string(value)) + "'."
end

;+
; :description:
;    Constructor
;
; :hidden:
;-
pro ppl_configuration_manager__define
  compile_opt idl2, hidden
  void = { ppl_configuration_manager, $
    configuration_file : '', $
    application : '', $
    configuration : ptr_new(), $
    lookup : ptr_new(), $
    initialized : 0b $
  }
end