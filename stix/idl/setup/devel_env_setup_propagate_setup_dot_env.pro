pro devel_env_setup_propagate_setup_dot_env, root=root, project=project

  ; try to find 'setup.PROJECT_env' file
  setup_file_name = 'setup.' + project + '_env'
  setup_file_relative_location = concat_dir(project, 'setup')
  setup_file_abolut_location = concat_dir(root, setup_file_relative_location)
  file = loc_file(setup_file_name, path=setup_file_abolut_location)
  project_root = concat_dir(root, project)
  
  if(file_exist(file)) then begin
    ; if setup file was found continue
    
    ; work on $SSW_PROJECT (e.g. SSW_STIX or SSW_HESSI)
    ssw_project_varname = 'SSW_' + strupcase(project)
    ssw_project = getenv(ssw_project_varname)
    
    ; if $SSW_PROJECT already exists and it is not root/project, give error
    if(ssw_project ne '' && ssw_project ne project_root) then message, 'Project roots do not agree, resetting project root from ' + ssw_project + ' to ' + project_root, /continue
    ; read and propagate variables
    ; set ssw_project first
    setenv, ssw_project_varname + '=' + project_root
    openr, lun, file, /get_lun
    
    ; find setenv instructions
    while ~eof(lun) do begin
      line=''
      readf, lun, line
      if(~stregex(trim(line), '^setenv.*$', /boolean, /fold_case)) then continue
        split = strsplit(line, /extract)
        
        if(stregex(split[2], '^\$' + ssw_project_varname, /boolean)) then split[2] = project_root + strsplit(split[2], '^\$' + ssw_project_varname, /extract, /regex)
        
        setenv, arr2str(split[1:2], '=') 
      endwhile
      
    close, lun
  
endif
end