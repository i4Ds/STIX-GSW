;---------------------------------------------------------------------------
; Document name: devel_env_setup.pro
; Created by:    Laszlo I. Etesi, 2011/02/24
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX/HESPE
;
; NAME:
;       STIX/HESPE Development Environment Setup script
;
; PURPOSE:
;       Helps setting up the development environment. Overriding any occurrence of Hespe files in SSW
;
; CATEGORY:
;       STIX/HESPE developer support
;
; CALLING SEQUENCE:
;       devel_env_setup, set_status, project=project, workspace=workspace, quiet=quiet
;
; KEYWORDS:
;   SET_STATUS:	Switch it 'on', or 'off'
;		PROJECT:	The project name inside your IDL Workspace. Should you be working without the graphical
;					development environment, PROJECT corresponds to the 'root' folder of the package, e.g.
;					'myproject' for /home/development/myproject.
;					If not defined, devel_env_setup tries retrieving the project from the environment
;					variable $IDL_PROJECT_NAME.
;		WORKSPACE:	The workspace path you are working with, e.g. /home/development. This workspace
;					contains the project that was defined by PROJECT.
;					If not defined, devel_env_setup tries retrieving the workspace from the environment
;					variable $IDL_WORKSPACE_PATH.
;		QUIET: If set to true, no error or status messages are printed
;
; HISTORY:
;       2011/02/24, laszlo.etesi@fhnw.ch, initial release
;       2012/04/18, laszlo.etesi@fhnw.ch, added quiet switch
;       2012/07/24, laszlo.etesi@fhnw.ch, added handler for multiple projects
;
;-
pro devel_env_setup, set_status, project=project, workspace=workspace, quiet=quiet
  checkvar, quiet, 0
  checkvar, project, getenv('IDL_PROJECT_NAME')
  checkvar, workspace, getenv('IDL_WORKSPACE_PATH')
  
  ; Get the environment variable if 'set_status' is not set. If environment var is null, then assume 'on'
  checkvar, set_status, getenv('IDL_DEVEL_STATUS')
  if (is_string(set_status) and set_status eq '') then begin
    setenv, 'IDL_DEVEL_STATUS=on'
    set_status = getenv('IDL_DEVEL_STATUS')
  endif
  
  projects = strsplit(project, ' ', /extract)
  
  for index = 0L, N_ELEMENTS(projects)-1 do begin
    if(~quiet) then begin
      if (projects[index] eq '') then message, "Project name could not be evaluated. Please set variable 'project'."
      if (workspace eq '') then message, "Workspace name could not be evaluated. Please set variable 'workspace'."
    endif else begin
      if (projects[index] eq '') then return
      if (workspace eq '') then return
    endelse
    
    project_path = workspace + get_delim() + projects[index]
    remove_path, project_path, old_path=old_path
    
    ; Check if project is still in !PATH and if so, give a warning to the user to disable the workspace auto-loading feature
    if(~quiet) then begin
      if(max(strpos(!PATH, project_path)) ne -1) then message, 'WARNING: Please disable the workspace auto-path feature. Right-click on project -> Properties -> IDL Project Properties -> Uncheck first checkbox (Refresh IDL search path when opening/closing a project)', /continue
    endif else begin
      if(max(strpos(!PATH, project_path)) ne -1) then return
    endelse
    
    if (is_string(set_status) and set_status eq 'on' or set_status eq '') then begin
      add_path, workspace + get_delim() + projects[index], /expand, /quiet
      setenv, 'IDL_DEVEL_STATUS=on'
      
      ; read project setup file
      devel_env_setup_propagate_setup_dot_env, root=getenv('IDL_WORKSPACE_PATH'), project=projects[index]
    endif else begin
      setenv, 'IDL_DEVEL_STATUS=off'
    endelse
  endfor
  
  cd, workspace
  
  if(quiet) then return
  
  if (set_status eq 'on') then begin
    print, '****************************'
    print, '* Development mode enabled *'
    print, '****************************'
  endif else begin $
    print, '**************************************************************************************'
  print, "* Development mode is or has been disabled.                                          *"
  print, "  Please execute '.FULL_RESET_SESSION' to clean up (if you haven't done so already)  *"
  print, "* Call                                                                               *"
  print, "*      devel_env_setup, 'on'                                                         *"
  print, "*                            to re-enable development mode                           *"
  print, '**************************************************************************************'
endelse
end

























