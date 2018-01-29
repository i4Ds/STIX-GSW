pro stx_lldp_init_environment
  ; ensure it's linux ($ENV vs. %env%)
  if(strlowcase(!VERSION.os_family) ne 'unix') then print, '[ERR] - This initialization script does only support Unix/Linux systems'
  
  ; define root
  ssw_stix = '/home/user/svn/idl/stix/STIX-ASW/stix'
  
  ; it seems that SSW_STIX is set incorrectly to /home/user/svn/ssw/so, so we need to reset it to its correct location
  setenv, 'SSW_STIX=' + ssw_stix
  
  ; construct path to setup file
  file = concat_dir(ssw_stix, '/setup/setup.stix_env')
  ;setup_file = 'setup.stix_env'
  ;relative_path = concat_dir('stix', 'setup')
  ;file = concat_dir(concat_dir('..', relative_path), setup_file)
  
  ; loop over all entries and extract setenv instructions
  openr, lun, file, /get_lun
  line = ''
  while ~eof(lun) do begin
    readf, lun, line
    
    ; if line is empty -> skip it
    if(strlen(line) eq 0) then continue
    
    ; if line starts with a hash, it's a comment -> skip it
    if(stregex(line, '^#.*$', /boolean)) then continue
      
    if(stregex(line, '^setenv.*', /boolean, /fold_case)) then begin
      ; find potential environment variables
      env_var = stregex(line, '\$([a-z_]*)/', /extract, /fold_case, /subexpr)
      
      ; replace environment variables with actual values
      if(n_elements(env_var) eq 2) then begin
        env_var = env_var[1]
        resolved_env_var = getenv(env_var)
        
        print, "[INFO] - Input line '" + line + "' will be updated with environment variable '$" + env_var + "'."
        if(trim(resolved_env_var) eq '') then print, "[WARN] - Environment variable '$" + env_var + "' could not be resolved!" 
        
        line = str_replace(line, '$' + env_var, getenv(env_var))
        print, "[INFO] - Input line is now '" + line + "'."
      endif
      
      instruction = str_replace(line, string(9b), string(32b))
      instruction = strsplit(instruction, ' ', /extract)
      ;instruction = strsplit(instruction[1], string(9b), /extract)
      print, "[INFO] - Updating environment with 'setenv, " + instruction[1] + "=" + instruction[2] + "'."
      setenv, instruction[1] + '=' + instruction[2]
    endif else begin
      print, 'Unknown line or command: ' + line
    endelse
  endwhile
  free_lun, lun
end

; setenv STX_CONF   $SSW_STIX/dbase/conf