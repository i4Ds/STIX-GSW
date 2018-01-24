;+
; :file_comments:
;    This is the basic pipeline processor object; it serves as a basis
;    for processor implementations (applications)
;
; :categories:
;    pipeline processing framework
;
; :examples:
;    n/a
;
; :history:
;    30-Apr-2014 - Laszlo I. Etesi (FHNW), initial release (documentation)
;    20-Aug-2015 - Laszlo I. Etesi (FHNW), bugfix: auto-initialization properly handled
;    07-Oct-2015 - Laszlo I. Etesi (FHNW), introduced the internal state
;-

;+
; :description:
;    this function initialises this module
;
; :params:
;    configuration_manager : in, required, type='instance of ppl_configuration_manager'
;      this is the instance-specific configuration manager
;      
;    internal_state : in, required, type='instance of ppl_processor_internal_state'
;
; :returns:
;   this function returns true or false, depending on the success of initializing this object
;-
function ppl_processor::init, configuration_manager, internal_state

  ; simple check if type is ppl_configuration_manager
  ; IDL command 'isa' would be safe, but it is IDL 8+
  help, internal_state, output=state_name
  if(where(stregex(state_name, '.*_internal_state.*', /boolean, /fold_case) eq 1) eq -1) then return, 0
  
    ; attach internal state
  self.internal_state = ptr_new(ppl_processor_internal_state(specific_state=internal_state))
  
  ; simple check if type is ppl_configuration_manager
  ; IDL command 'isa' would be safe, but it is IDL 8+
  help, configuration_manager, output=module_name
  if(where(stregex(module_name, '.*_configuration_manager.*', /boolean, /fold_case) eq 1) eq -1) then return, 0
  
  ; assign configuration manager
  (*self.internal_state).configuration_manager = ptr_valid(configuration_manager) ? configuration_manager : ptr_new(configuration_manager)
  if(~(*(*self.internal_state).configuration_manager).initialized) then (*(*self.internal_state).configuration_manager)->load_configuration
  return, 1
end

;+
; :description:
;    cleanup
;-
pro ppl_processor::cleanup
  ; TODO: check if the pointers in the state structure need destroying
  destroy, self.internal_state ;configuration_manager
  ; Call our superclass Cleanup method
  self->idl_object::cleanup
end

;+ 
; :description:
;    this routine returns a single parameter or the complete module configuration;
;    the module configuration is merged with the global configuration
; 
; :keywords:
;    module : in, optional, type='string'
;      if set to a module name, the additional parameters are assumed
;      to be withougt a namespace definition and to be specific to the given module;
;      if no parameters are given, the complete module configuration is returned
;    single : in, optional, type='bool', default='true'
;      if set to true, only the one requested parameter is returned, w/o global  
;    extra : in, optional, type=any
;      any set of parameters that exist in the configuration
;  
; :returns:
;    a single parameter or complete module configuration
;      
; :examples:
;    help, sw->get(module='global')
;    help, sw->get(/debug)
;    help, sw->get(/debug, /stop_on_error, single=0)
;      
; :history:
;    30-Apr-2014 - Laszlo I. Etesi, initial release
;    07-Oct-2015 - Laszlo I. Etesi, added internal state update
;-
function ppl_processor::get, module=module, single=single, _extra=extra
  default, single, 1
  return, (*(*self.internal_state).configuration_manager)->get(module=module, single=single, _extra=extra)
end

;+
; :description:
;    this routine allows access to the underlying configuration manager; 
;    a parameter can be set globally or for a specific module;
;    a complete list of parameters can be found in
;    'dbase/config/stx_XXX.config'
;
; :keywords:
;    module : in, optional, type='string'
;      if set all parameters are assumed to be without namespace and are
;      assigned to that module
;    extra : in, required, type=any
;      any set of parameters that modify the configuration
;      
; :examples:
;    sw->set, module='global', debug=1
;    sw->set, debug=1
;    sw->set, namespace_parameter='true'
;      
; :history:
;    30-Apr-2014 - Laszlo I. Etesi, initial release
;    07-Oct-2015 - Laszlo I. Etesi, added internal state update
;-
pro ppl_processor::set, _extra=extra
  (*(*self.internal_state).configuration_manager)->set, _extra=extra
end

;+
; :description:
;    not available yet
;-
function ppl_processor::setdata, _extra=extra
  message, 'This functionality has not been implemented yet.', /continue
  return, 0
end

;+ 
; :description:
;    this is the main processing routine; data can be requested by providing 'input_data'
;    and specifying the desired 'output_target'
;-
function ppl_processor::getdata, input_data=input_data, output_target=output_target, history=history
  message, 'This functionality has not been implemented yet.', /continue
  return, 0
end

;+
; :description:
;    not available yet
;-
function ppl_processor::display
  message, 'This functionality has not been implemented yet.', /continue
  return, 0
end

;+
; :description:
;    not available yet
;-
function ppl_processor::help
  message, 'This functionality has not been implemented yet.', /continue
  return, 0
end

pro ppl_processor__define
  void = { ppl_processor, $
    inherits idl_object , $
    internal_state : ptr_new() $  ; the internal state contains all state information, including the configuration    
  }
end