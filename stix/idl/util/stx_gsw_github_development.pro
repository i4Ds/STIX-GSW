;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_gsw_github_development
;
; :description:
;    This procedure allows you to switch to a development version of the STIX Ground Software that you have downloaded
;    from GitHub.
;
; :categories:
;    utility, development
;
; :params:
;    workspace_path : in, required, type="string"
;                     the path to the development folder downloaded from GitHub
;
;
; :examples:
;    stx_gsw_github_development, '~/STIX-GSW'
;
; :history:
;    30-Mar-2022 - ECMD (Graz), initial release
;
;-
pro stx_gsw_github_development, workspace_path

  ;remove the current stix folders from the path
  remove_path,'stix'

  cd, current=current
  ;check for the /stix folder in the downloaded repository
  stix_folder =  workspace_path + get_delim() +'stix'
  if ~file_test(stix_folder, /directory) then begin
    message, 'STIX folder not found.'
  end

  ;add the development files
  add_path, stix_folder, /expand, /quiet

  ;switch directory to the development folder
  cd,  workspace_path

  ;replace the environment variables from the SSW version with the development equivalents
  devel_env_setup_propagate_setup_dot_env, root = workspace_path, project = 'stix'

end